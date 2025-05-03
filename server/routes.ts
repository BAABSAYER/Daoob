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
      console.log("Booking request body:", req.body);
      
      const bookingData: InsertBooking = {
        ...req.body,
        clientId: req.user.id,
        status: BOOKING_STATUS.PENDING
      };
      
      console.log("Processed booking data:", bookingData);
      
      const booking = await storage.createBooking(bookingData);
      res.status(201).json(booking);
    } catch (error) {
      console.error("Booking creation error:", error);
      res.status(500).json({ message: 'Error creating booking', error: error.message });
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
