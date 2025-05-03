import type { Express } from "express";
import { createServer, type Server } from "http";
import { WebSocketServer, WebSocket } from "ws";
import { storage } from "./storage";
import { db } from "./db";
import { setupAuth } from "./auth";
import { InsertVendor, InsertBooking, InsertMessage, BOOKING_STATUS, messages } from "@shared/schema";
import { z } from "zod";
import { eq, or, and } from "drizzle-orm";

interface WSMessage {
  type: string;
  sender: number;
  receiver: number;
  content: string;
  timestamp: Date;
}

interface SocketConnection {
  userId: number;
  socket: WebSocket;
}

export async function registerRoutes(app: Express): Promise<Server> {
  // Set up authentication
  setupAuth(app);
  
  const httpServer = createServer(app);
  
  // Set up WebSocket server
  const wss = new WebSocketServer({ server: httpServer, path: '/ws' });
  const connections: SocketConnection[] = [];
  
  wss.on('connection', (ws: WebSocket) => {
    let userId: number | null = null;
    
    ws.on('message', async (message: string) => {
      try {
        const data = JSON.parse(message) as WSMessage;
        
        if (data.type === 'auth') {
          userId = parseInt(data.content);
          connections.push({ userId, socket: ws });
          console.log(`User ${userId} connected to WebSocket`);
          return;
        }
        
        if (data.type === 'message' && userId !== null) {
          // Store message in database
          const savedMessage = await storage.createMessage({
            senderId: data.sender,
            receiverId: data.receiver,
            content: data.content,
            read: false,
            createdAt: new Date()
          });
          
          // Forward message to recipient if online
          const recipientConnection = connections.find(conn => conn.userId === data.receiver);
          if (recipientConnection && recipientConnection.socket.readyState === WebSocket.OPEN) {
            recipientConnection.socket.send(JSON.stringify({
              ...data,
              id: savedMessage.id,
              timestamp: savedMessage.createdAt
            }));
          }
        }
      } catch (error) {
        console.error('WebSocket message error:', error);
      }
    });
    
    ws.on('close', () => {
      if (userId !== null) {
        const index = connections.findIndex(conn => conn.userId === userId);
        if (index !== -1) {
          connections.splice(index, 1);
          console.log(`User ${userId} disconnected from WebSocket`);
        }
      }
    });
  });
  
  // Vendor routes
  app.get('/api/vendors', async (req, res) => {
    try {
      const { category, search } = req.query;
      
      let vendors;
      if (category) {
        vendors = await storage.getVendorsByCategory(category as string);
      } else if (search) {
        vendors = await storage.searchVendors(search as string);
      } else {
        vendors = await storage.getAllVendors();
      }
      
      // Enhance vendors with user data
      const enhancedVendors = await Promise.all(
        vendors.map(async vendor => {
          const user = await storage.getUser(vendor.userId);
          return {
            ...vendor,
            email: user?.email,
            phone: user?.phone
          };
        })
      );
      
      res.json(enhancedVendors);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching vendors' });
    }
  });
  
  app.get('/api/vendors/:id', async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const vendor = await storage.getVendor(id);
      
      if (!vendor) {
        return res.status(404).json({ message: 'Vendor not found' });
      }
      
      // Get user data, services, and reviews
      const user = await storage.getUser(vendor.userId);
      const services = await storage.getServicesByVendor(id);
      const reviews = await storage.getReviewsByVendor(id);
      
      // Enhance reviews with user data
      const enhancedReviews = await Promise.all(
        reviews.map(async review => {
          const reviewer = await storage.getUser(review.clientId);
          return {
            ...review,
            reviewerName: reviewer?.fullName || reviewer?.username
          };
        })
      );
      
      res.json({
        ...vendor,
        email: user?.email,
        phone: user?.phone,
        services,
        reviews: enhancedReviews
      });
    } catch (error) {
      res.status(500).json({ message: 'Error fetching vendor details' });
    }
  });
  
  // Create or update vendor (for vendor users)
  app.post('/api/vendors', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      // Check if user is a vendor
      if (req.user.userType !== 'vendor') {
        return res.status(403).json({ message: 'Not authorized to create vendor profile' });
      }
      
      // Check if vendor profile already exists
      let vendor = await storage.getVendorByUserId(req.user.id);
      
      if (vendor) {
        // Update existing vendor
        const vendorData: Partial<InsertVendor> = {
          ...req.body,
          userId: req.user.id
        };
        
        vendor = await storage.updateVendor(vendor.id, vendorData);
        return res.json(vendor);
      } else {
        // Create new vendor
        const vendorData: InsertVendor = {
          ...req.body,
          userId: req.user.id
        };
        
        vendor = await storage.createVendor(vendorData);
        return res.status(201).json(vendor);
      }
    } catch (error) {
      res.status(500).json({ message: 'Error creating/updating vendor profile' });
    }
  });
  
  // Booking routes
  app.post('/api/bookings', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      console.log("Booking request body:", JSON.stringify(req.body, null, 2));
      
      // Validate that required fields are present
      if (!req.body.vendorId) {
        return res.status(400).json({ message: 'Missing required field: vendorId' });
      }
      
      if (!req.body.eventType) {
        return res.status(400).json({ message: 'Missing required field: eventType' });
      }
      
      if (!req.body.eventDate) {
        return res.status(400).json({ message: 'Missing required field: eventDate' });
      }
      
      let bookingData;
      try {
        bookingData = {
          clientId: req.user.id,
          vendorId: req.body.vendorId,
          eventType: req.body.eventType,
          eventDate: new Date(req.body.eventDate),
          guestCount: req.body.guestCount || 0,
          specialRequests: req.body.specialRequests || "",
          totalPrice: req.body.totalPrice || 0,
          status: BOOKING_STATUS.PENDING,
          serviceId: req.body.serviceId !== undefined ? req.body.serviceId : null,
        };
      } catch (parseError: any) {
        console.error("Error parsing booking data:", parseError);
        return res.status(400).json({ message: 'Invalid booking data', error: parseError?.message || 'Unknown parsing error' });
      }
      
      console.log("Processed booking data:", JSON.stringify(bookingData, null, 2));
      
      try {
        const booking = await storage.createBooking(bookingData);
        res.status(201).json(booking);
      } catch (dbError: any) {
        console.error("Database error creating booking:", dbError);
        return res.status(500).json({ 
          message: 'Database error creating booking', 
          error: dbError?.message || 'Unknown database error'
        });
      }
    } catch (error: any) {
      console.error("Booking creation error:", error);
      res.status(500).json({ 
        message: 'Error creating booking', 
        error: error?.message || 'Unknown error during booking creation'
      });
    }
  });
  
  app.get('/api/bookings', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      let bookings;
      
      if (req.user.userType === 'client') {
        bookings = await storage.getBookingsByClient(req.user.id);
      } else if (req.user.userType === 'vendor') {
        const vendor = await storage.getVendorByUserId(req.user.id);
        if (!vendor) {
          return res.status(404).json({ message: 'Vendor profile not found' });
        }
        bookings = await storage.getBookingsByVendor(vendor.id);
      } else {
        return res.status(403).json({ message: 'Unauthorized' });
      }
      
      // Enhance bookings with vendor/client data
      const enhancedBookings = await Promise.all(
        bookings.map(async booking => {
          const vendor = await storage.getVendor(booking.vendorId);
          const client = await storage.getUser(booking.clientId);
          
          return {
            ...booking,
            vendorName: vendor?.businessName,
            clientName: client?.fullName || client?.username
          };
        })
      );
      
      res.json(enhancedBookings);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching bookings' });
    }
  });
  
  app.put('/api/bookings/:id', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const id = parseInt(req.params.id);
      const booking = await storage.getBooking(id);
      
      if (!booking) {
        return res.status(404).json({ message: 'Booking not found' });
      }
      
      // Only allow updates by client who made booking or vendor who received it
      const vendor = await storage.getVendorByUserId(req.user.id);
      if (booking.clientId !== req.user.id && (!vendor || booking.vendorId !== vendor.id)) {
        return res.status(403).json({ message: 'Not authorized to update this booking' });
      }
      
      const updatedBooking = await storage.updateBooking(id, req.body);
      res.json(updatedBooking);
    } catch (error) {
      res.status(500).json({ message: 'Error updating booking' });
    }
  });
  
  // Messages routes
  app.get('/api/messages/:userId', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const otherUserId = parseInt(req.params.userId);
      const messages = await storage.getMessagesBetweenUsers(req.user.id, otherUserId);
      
      // Mark messages as read
      await Promise.all(
        messages
          .filter(m => m.receiverId === req.user.id && !m.read)
          .map(m => storage.markMessageAsRead(m.id))
      );
      
      res.json(messages);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching messages' });
    }
  });
  
  app.post('/api/messages', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const messageData: InsertMessage = {
        senderId: req.user.id,
        receiverId: req.body.receiverId,
        content: req.body.content,
        read: false,
        createdAt: new Date()
      };
      
      const message = await storage.createMessage(messageData);
      
      // Notify recipient via WebSocket if connected
      const recipientConnection = connections.find(conn => conn.userId === req.body.receiverId);
      if (recipientConnection && recipientConnection.socket.readyState === WebSocket.OPEN) {
        recipientConnection.socket.send(JSON.stringify({
          type: 'message',
          sender: req.user.id,
          receiver: req.body.receiverId,
          content: req.body.content,
          id: message.id,
          timestamp: message.createdAt
        }));
      }
      
      res.status(201).json(message);
    } catch (error) {
      res.status(500).json({ message: 'Error sending message' });
    }
  });
  
  // Get user by ID (for chat)
  app.get('/api/users/:id', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const userId = parseInt(req.params.id);
      const user = await storage.getUser(userId);
      
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }
      
      // Return user without password
      const { password, ...userWithoutPassword } = user;
      res.json(userWithoutPassword);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching user' });
    }
  });
  
  // Vendor Dashboard Routes
  
  // Get vendor dashboard data
  app.get('/api/vendors/dashboard', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== 'vendor') {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    try {
      // Get vendor profile
      const vendor = await storage.getVendorByUserId(req.user.id);
      
      if (!vendor) {
        return res.status(404).json({ message: 'Vendor profile not found' });
      }
      
      // Get bookings for this vendor
      const bookings = await storage.getBookingsByVendor(vendor.id);
      
      // Get services for this vendor
      const services = await storage.getServicesByVendor(vendor.id);
      
      // Get reviews for this vendor
      const reviews = await storage.getReviewsByVendor(vendor.id);
      
      // Calculate stats
      const totalBookings = bookings.length;
      const pendingBookings = bookings.filter(b => b.status === BOOKING_STATUS.PENDING).length;
      const confirmedBookings = bookings.filter(b => b.status === BOOKING_STATUS.CONFIRMED).length;
      const totalEarnings = bookings
        .filter(b => b.status !== BOOKING_STATUS.CANCELLED)
        .reduce((sum, booking) => sum + (booking.totalPrice || 0), 0);
      
      // Calculate average rating
      const avgRating = reviews.length > 0 
        ? reviews.reduce((sum, review) => sum + review.rating, 0) / reviews.length 
        : 0;
      
      res.json({
        vendor,
        stats: {
          totalBookings,
          pendingBookings,
          confirmedBookings,
          totalEarnings,
          avgRating,
          totalReviews: reviews.length,
          totalServices: services.length
        }
      });
    } catch (error) {
      console.error('Error fetching vendor dashboard:', error);
      res.status(500).json({ message: 'Error fetching vendor dashboard' });
    }
  });
  
  // Get recent bookings for vendor dashboard
  app.get('/api/bookings/recent', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== 'vendor') {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    try {
      const vendor = await storage.getVendorByUserId(req.user.id);
      
      if (!vendor) {
        return res.status(404).json({ message: 'Vendor profile not found' });
      }
      
      // Get all bookings for this vendor
      const allBookings = await storage.getBookingsByVendor(vendor.id);
      
      // Sort by creation date (newest first) and take the first 5
      const recentBookings = allBookings
        .sort((a, b) => {
          const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
          const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
          return dateB - dateA;
        })
        .slice(0, 5);
      
      // Enhance bookings with client names
      const enhancedBookings = await Promise.all(
        recentBookings.map(async booking => {
          const client = await storage.getUser(booking.clientId);
          const service = booking.serviceId ? await storage.getService(booking.serviceId) : null;
          
          return {
            ...booking,
            clientName: client?.fullName || client?.username,
            serviceName: service?.name
          };
        })
      );
      
      res.json(enhancedBookings);
    } catch (error) {
      console.error('Error fetching recent bookings:', error);
      res.status(500).json({ message: 'Error fetching recent bookings' });
    }
  });
  
  // Get vendor-specific bookings with filters
  app.get('/api/vendor/bookings', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== 'vendor') {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    try {
      const vendor = await storage.getVendorByUserId(req.user.id);
      
      if (!vendor) {
        return res.status(404).json({ message: 'Vendor profile not found' });
      }
      
      // Get bookings for this vendor
      const allBookings = await storage.getBookingsByVendor(vendor.id);
      
      // Apply filter based on query param
      const { filter } = req.query;
      let filteredBookings = [...allBookings];
      
      if (filter === 'upcoming') {
        const now = new Date();
        filteredBookings = allBookings.filter(booking => 
          new Date(booking.eventDate) >= now && 
          booking.status !== BOOKING_STATUS.CANCELLED
        );
      } else if (filter === 'pending') {
        filteredBookings = allBookings.filter(booking => 
          booking.status === BOOKING_STATUS.PENDING
        );
      } else if (filter === 'past') {
        const now = new Date();
        filteredBookings = allBookings.filter(booking => 
          new Date(booking.eventDate) < now || 
          booking.status === BOOKING_STATUS.CANCELLED ||
          booking.status === BOOKING_STATUS.COMPLETED
        );
      }
      
      // Enhance bookings with client names and service details
      const enhancedBookings = await Promise.all(
        filteredBookings.map(async booking => {
          const client = await storage.getUser(booking.clientId);
          const service = booking.serviceId ? await storage.getService(booking.serviceId) : null;
          
          return {
            ...booking,
            clientName: client?.fullName || client?.username,
            serviceName: service?.name,
            // For bookings with packages selected
            packageType: req.body.packageType || "Standard"
          };
        })
      );
      
      res.json(enhancedBookings);
    } catch (error) {
      console.error('Error fetching vendor bookings:', error);
      res.status(500).json({ message: 'Error fetching vendor bookings' });
    }
  });
  
  // Get vendor profile
  app.get('/api/vendor/profile', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== 'vendor') {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    try {
      const vendor = await storage.getVendorByUserId(req.user.id);
      
      if (!vendor) {
        return res.status(404).json({ message: 'Vendor profile not found' });
      }
      
      // Return user data along with vendor profile
      const userData = {
        email: req.user.email,
        phone: req.user.phone,
        username: req.user.username,
        fullName: req.user.fullName
      };
      
      res.json({
        ...vendor,
        ...userData
      });
    } catch (error) {
      console.error('Error fetching vendor profile:', error);
      res.status(500).json({ message: 'Error fetching vendor profile' });
    }
  });
  
  // Update vendor profile
  app.put('/api/vendor/profile', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== 'vendor') {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    try {
      const vendor = await storage.getVendorByUserId(req.user.id);
      
      if (!vendor) {
        return res.status(404).json({ message: 'Vendor profile not found' });
      }
      
      // Update user data
      const userUpdates = {
        email: req.body.email,
        phone: req.body.phone,
        fullName: req.body.businessName // Use business name as full name
      };
      
      await storage.updateUser(req.user.id, userUpdates);
      
      // Update vendor data
      const vendorUpdates = {
        businessName: req.body.businessName,
        description: req.body.description,
        address: req.body.address,
        city: req.body.city,
        categories: req.body.categories,
        eventTypes: req.body.eventTypes,
        profileImage: req.body.profileImage
      };
      
      const updatedVendor = await storage.updateVendor(vendor.id, vendorUpdates);
      
      res.json({
        ...updatedVendor,
        ...userUpdates
      });
    } catch (error) {
      console.error('Error updating vendor profile:', error);
      res.status(500).json({ message: 'Error updating vendor profile' });
    }
  });
  
  // Service management routes
  
  // Get all services for the logged-in vendor
  app.get('/api/services', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== 'vendor') {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    try {
      const vendor = await storage.getVendorByUserId(req.user.id);
      
      if (!vendor) {
        return res.status(404).json({ message: 'Vendor profile not found' });
      }
      
      const services = await storage.getServicesByVendor(vendor.id);
      res.json(services);
    } catch (error) {
      console.error('Error fetching services:', error);
      res.status(500).json({ message: 'Error fetching services' });
    }
  });
  
  // Get specific service by ID
  app.get('/api/services/:id', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const id = parseInt(req.params.id);
      const service = await storage.getService(id);
      
      if (!service) {
        return res.status(404).json({ message: 'Service not found' });
      }
      
      // Only allow vendors to access their own services
      if (req.user.userType === 'vendor') {
        const vendor = await storage.getVendorByUserId(req.user.id);
        if (!vendor || service.vendorId !== vendor.id) {
          return res.status(403).json({ message: 'Not authorized to access this service' });
        }
      }
      
      res.json(service);
    } catch (error) {
      console.error('Error fetching service:', error);
      res.status(500).json({ message: 'Error fetching service' });
    }
  });
  
  // Create a new service
  app.post('/api/services', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== 'vendor') {
      return res.status(403).json({ message: 'Not authorized to create services' });
    }
    
    try {
      const vendor = await storage.getVendorByUserId(req.user.id);
      
      if (!vendor) {
        return res.status(404).json({ message: 'Vendor profile not found' });
      }
      
      const serviceData = {
        ...req.body,
        vendorId: vendor.id,
        createdAt: new Date()
      };
      
      const service = await storage.createService(serviceData);
      res.status(201).json(service);
    } catch (error) {
      console.error('Error creating service:', error);
      res.status(500).json({ message: 'Error creating service' });
    }
  });
  
  // Update a service
  app.put('/api/services/:id', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== 'vendor') {
      return res.status(403).json({ message: 'Not authorized to update services' });
    }
    
    try {
      const id = parseInt(req.params.id);
      const service = await storage.getService(id);
      
      if (!service) {
        return res.status(404).json({ message: 'Service not found' });
      }
      
      const vendor = await storage.getVendorByUserId(req.user.id);
      
      if (!vendor || service.vendorId !== vendor.id) {
        return res.status(403).json({ message: 'Not authorized to update this service' });
      }
      
      const updatedService = await storage.updateService(id, {
        ...req.body,
        updatedAt: new Date()
      });
      
      res.json(updatedService);
    } catch (error) {
      console.error('Error updating service:', error);
      res.status(500).json({ message: 'Error updating service' });
    }
  });
  
  // Get conversations (distinct users with whom the current user has exchanged messages)
  app.get('/api/conversations', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      // Get all users the current user has exchanged messages with
      const allMessages = await db.select().from(messages).where(
        or(
          eq(messages.senderId, req.user.id),
          eq(messages.receiverId, req.user.id)
        )
      );
      
      // Get unique user IDs the current user has conversations with
      const conversationUserIds = Array.from(
        new Set(
          allMessages.map(message => 
            message.senderId === req.user.id ? message.receiverId : message.senderId
          )
        )
      );
      
      // Get user details and last message for each conversation
      const conversations = await Promise.all(
        conversationUserIds.map(async userId => {
          const user = await storage.getUser(userId);
          
          if (!user) return null;
          
          // Get last message between users
          const messages = await storage.getMessagesBetweenUsers(req.user.id, userId);
          const lastMessage = messages.length > 0 
            ? messages[messages.length - 1] 
            : null;
          
          // Get unread count
          const unreadCount = messages.filter(
            m => m.receiverId === req.user.id && !m.read
          ).length;
          
          return {
            userId: user.id,
            username: user.username,
            fullName: user.fullName,
            userType: user.userType,
            avatarUrl: user.avatarUrl,
            lastMessage: lastMessage ? {
              id: lastMessage.id,
              content: lastMessage.content,
              createdAt: lastMessage.createdAt,
              senderId: lastMessage.senderId
            } : null,
            unreadCount
          };
        })
      );
      
      // Remove null entries and sort by last message time
      const validConversations = conversations
        .filter(Boolean)
        .sort((a, b) => {
          const timeA = a?.lastMessage?.createdAt ? new Date(a.lastMessage.createdAt).getTime() : 0;
          const timeB = b?.lastMessage?.createdAt ? new Date(b.lastMessage.createdAt).getTime() : 0;
          return timeB - timeA;
        });
      
      res.json(validConversations);
    } catch (error) {
      console.error('Error fetching conversations:', error);
      res.status(500).json({ message: 'Error fetching conversations' });
    }
  });
  
  return httpServer;
}
