import type { Express } from "express";
import { createServer, type Server } from "http";
import { WebSocketServer, WebSocket } from "ws";
import { storage } from "./storage";
import { db } from "./db";
import { setupAuth } from "./auth";
import { 
  InsertVendor, InsertBooking, InsertMessage, InsertEventType, InsertQuestionnaireItem, 
  InsertEventRequest, InsertQuotation, BOOKING_STATUS, USER_TYPES, messages,
  eventRequests, quotations
} from "@shared/schema";
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
  
  // Add a simple test endpoint
  app.get('/api/test', (req, res) => {
    res.json({ message: 'API is working!' });
  });
  
  // Event Type routes
  app.get('/api/event-types', async (req, res) => {
    try {
      const eventTypes = await storage.getAllEventTypes();
      res.json(eventTypes);
    } catch (error) {
      console.error('Error fetching event types:', error);
      res.status(500).json({ message: 'Failed to fetch event types' });
    }
  });
  
  app.get('/api/event-types/active', async (req, res) => {
    try {
      const eventTypes = await storage.getActiveEventTypes();
      res.json(eventTypes);
    } catch (error) {
      console.error('Error fetching active event types:', error);
      res.status(500).json({ message: 'Failed to fetch active event types' });
    }
  });
  
  app.get('/api/event-types/:id', async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: 'Invalid event type ID' });
      }
      
      const eventType = await storage.getEventType(id);
      if (!eventType) {
        return res.status(404).json({ message: 'Event type not found' });
      }
      
      res.json(eventType);
    } catch (error) {
      console.error('Error fetching event type:', error);
      res.status(500).json({ message: 'Failed to fetch event type' });
    }
  });
  
  app.post('/api/event-types', async (req, res) => {
    // Only admin can create event types
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    const hasPermission = await storage.checkAdminPermission(req.user.id, 'manage_event_types');
    if (!hasPermission) {
      return res.status(403).json({ message: 'Forbidden: Insufficient permissions' });
    }
    
    try {
      const eventTypeData: InsertEventType = {
        name: req.body.name,
        description: req.body.description,
        icon: req.body.icon,
        isActive: req.body.isActive ?? true,
      };
      
      const eventType = await storage.createEventType(eventTypeData);
      res.status(201).json(eventType);
    } catch (error) {
      console.error('Error creating event type:', error);
      res.status(500).json({ message: 'Failed to create event type' });
    }
  });
  
  app.patch('/api/event-types/:id', async (req, res) => {
    // Only admin can update event types
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    const hasPermission = await storage.checkAdminPermission(req.user.id, 'manage_event_types');
    if (!hasPermission) {
      return res.status(403).json({ message: 'Forbidden: Insufficient permissions' });
    }
    
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: 'Invalid event type ID' });
      }
      
      const eventType = await storage.updateEventType(id, req.body);
      if (!eventType) {
        return res.status(404).json({ message: 'Event type not found' });
      }
      
      res.json(eventType);
    } catch (error) {
      console.error('Error updating event type:', error);
      res.status(500).json({ message: 'Failed to update event type' });
    }
  });
  
  // Questionnaire Item routes
  app.get('/api/questionnaire-items', async (req, res) => {
    try {
      // You'd need to add a method to get all questionnaire items
      // This is an admin function, so we could add permissions check here
      const questionnaireItems = await db.query.questionnaireItems.findMany();
      res.json(questionnaireItems);
    } catch (error) {
      console.error('Error fetching questionnaire items:', error);
      res.status(500).json({ message: 'Failed to fetch questionnaire items' });
    }
  });
  
  app.get('/api/event-types/:eventTypeId/questions', async (req, res) => {
    try {
      const eventTypeId = parseInt(req.params.eventTypeId);
      if (isNaN(eventTypeId)) {
        return res.status(400).json({ message: 'Invalid event type ID' });
      }
      
      const questions = await storage.getQuestionnaireItemsByEventType(eventTypeId);
      res.json(questions);
    } catch (error) {
      console.error('Error fetching questions for event type:', error);
      res.status(500).json({ message: 'Failed to fetch questions' });
    }
  });
  
  app.post('/api/questionnaire-items', async (req, res) => {
    // Only admin can create questionnaire items
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    const hasPermission = await storage.checkAdminPermission(req.user.id, 'manage_event_types');
    if (!hasPermission) {
      return res.status(403).json({ message: 'Forbidden: Insufficient permissions' });
    }
    
    try {
      const questionnaireItemData: InsertQuestionnaireItem = {
        eventTypeId: req.body.eventTypeId,
        questionText: req.body.questionText,
        questionType: req.body.questionType,
        options: req.body.options,
        required: req.body.required ?? false,
        displayOrder: req.body.displayOrder,
      };
      
      const questionnaireItem = await storage.createQuestionnaireItem(questionnaireItemData);
      res.status(201).json(questionnaireItem);
    } catch (error) {
      console.error('Error creating questionnaire item:', error);
      res.status(500).json({ message: 'Failed to create questionnaire item' });
    }
  });
  
  app.patch('/api/questionnaire-items/:id', async (req, res) => {
    // Only admin can update questionnaire items
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    const hasPermission = await storage.checkAdminPermission(req.user.id, 'manage_event_types');
    if (!hasPermission) {
      return res.status(403).json({ message: 'Forbidden: Insufficient permissions' });
    }
    
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: 'Invalid questionnaire item ID' });
      }
      
      const questionnaireItem = await storage.updateQuestionnaireItem(id, req.body);
      if (!questionnaireItem) {
        return res.status(404).json({ message: 'Questionnaire item not found' });
      }
      
      res.json(questionnaireItem);
    } catch (error) {
      console.error('Error updating questionnaire item:', error);
      res.status(500).json({ message: 'Failed to update questionnaire item' });
    }
  });
  
  app.delete('/api/questionnaire-items/:id', async (req, res) => {
    // Only admin can delete questionnaire items
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    const hasPermission = await storage.checkAdminPermission(req.user.id, 'manage_event_types');
    if (!hasPermission) {
      return res.status(403).json({ message: 'Forbidden: Insufficient permissions' });
    }
    
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: 'Invalid questionnaire item ID' });
      }
      
      await storage.deleteQuestionnaireItem(id);
      res.status(204).end();
    } catch (error) {
      console.error('Error deleting questionnaire item:', error);
      res.status(500).json({ message: 'Failed to delete questionnaire item' });
    }
  });
  
  // Event Request routes
  app.get('/api/event-requests', async (req, res) => {
    // Check authentication
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      let requestsList;
      
      // If admin, can see all requests, optionally filtered by status
      const isAdmin = await storage.checkAdminPermission(req.user.id, 'view_event_requests');
      if (isAdmin) {
        if (req.query.status) {
          // Filter by status if provided
          const status = req.query.status as string;
          requestsList = await db
            .select()
            .from(eventRequests)
            .where(eq(eventRequests.status, status));
        } else {
          requestsList = await storage.getAllEventRequests();
        }
      } else {
        // Regular clients can only see their own requests
        requestsList = await storage.getEventRequestsByClient(req.user.id);
      }
      
      res.json(requestsList);
    } catch (error) {
      console.error('Error fetching event requests:', error);
      res.status(500).json({ message: 'Failed to fetch event requests' });
    }
  });
  
  app.get('/api/event-requests/:id', async (req, res) => {
    // Check authentication
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: 'Invalid event request ID' });
      }
      
      const eventRequest = await storage.getEventRequest(id);
      if (!eventRequest) {
        return res.status(404).json({ message: 'Event request not found' });
      }
      
      // Check permissions: either admin or the client who created the request
      const isAdmin = await storage.checkAdminPermission(req.user.id, 'view_event_requests');
      if (!isAdmin && eventRequest.clientId !== req.user.id) {
        return res.status(403).json({ message: 'Forbidden: You do not have permission to view this request' });
      }
      
      res.json(eventRequest);
    } catch (error) {
      console.error('Error fetching event request:', error);
      res.status(500).json({ message: 'Failed to fetch event request' });
    }
  });
  
  app.post('/api/event-requests', async (req, res) => {
    // Check authentication
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      // Convert eventDate string to a Date object if it exists
      let eventDate = null;
      if (req.body.eventDate) {
        eventDate = new Date(req.body.eventDate);
        // Validate the date is valid
        if (isNaN(eventDate.getTime())) {
          return res.status(400).json({ message: 'Invalid event date format' });
        }
      }
      
      const eventRequestData: InsertEventRequest = {
        clientId: req.user.id,
        eventTypeId: req.body.eventTypeId,
        status: 'pending',
        responses: req.body.responses || {},
        eventDate: eventDate,
        budget: req.body.budget,
        specialRequests: req.body.specialRequests,
      };
      
      const eventRequest = await storage.createEventRequest(eventRequestData);
      res.status(201).json(eventRequest);
    } catch (error) {
      console.error('Error creating event request:', error);
      res.status(500).json({ message: 'Failed to create event request' });
    }
  });
  
  app.patch('/api/event-requests/:id', async (req, res) => {
    // Check authentication
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: 'Invalid event request ID' });
      }
      
      const eventRequest = await storage.getEventRequest(id);
      if (!eventRequest) {
        return res.status(404).json({ message: 'Event request not found' });
      }
      
      // Check permissions: either admin or the client who created the request
      const isAdmin = await storage.checkAdminPermission(req.user.id, 'manage_event_requests');
      if (!isAdmin && eventRequest.clientId !== req.user.id) {
        return res.status(403).json({ message: 'Forbidden: You do not have permission to update this request' });
      }
      
      // For clients, only allow updating to 'cancelled' status
      if (!isAdmin && req.body.status && req.body.status !== 'cancelled') {
        return res.status(403).json({ message: 'Forbidden: You do not have permission to update the status to this value' });
      }
      
      const updatedEventRequest = await storage.updateEventRequest(id, req.body);
      res.json(updatedEventRequest);
    } catch (error) {
      console.error('Error updating event request:', error);
      res.status(500).json({ message: 'Failed to update event request' });
    }
  });
  
  // Quotation routes
  app.get('/api/quotations', async (req, res) => {
    // Check authentication
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const isAdmin = await storage.checkAdminPermission(req.user.id, 'view_quotations');
      
      // If admin, can see all quotations
      if (isAdmin) {
        // Get all quotations
        const quotations = await db.query.quotations.findMany();
        return res.json(quotations);
      }
      
      // For clients, fetch their event requests first
      const eventRequests = await storage.getEventRequestsByClient(req.user.id);
      const requestIds = eventRequests.map(request => request.id);
      
      // Then fetch quotations for those requests
      const quotations = [];
      for (const requestId of requestIds) {
        const requestQuotations = await storage.getQuotationsByEventRequest(requestId);
        quotations.push(...requestQuotations);
      }
      
      res.json(quotations);
    } catch (error) {
      console.error('Error fetching quotations:', error);
      res.status(500).json({ message: 'Failed to fetch quotations' });
    }
  });
  
  app.get('/api/event-requests/:requestId/quotations', async (req, res) => {
    // Check authentication
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const requestId = parseInt(req.params.requestId);
      if (isNaN(requestId)) {
        return res.status(400).json({ message: 'Invalid event request ID' });
      }
      
      const eventRequest = await storage.getEventRequest(requestId);
      if (!eventRequest) {
        return res.status(404).json({ message: 'Event request not found' });
      }
      
      // Check permissions: either admin or the client who created the request
      const isAdmin = await storage.checkAdminPermission(req.user.id, 'view_quotations');
      if (!isAdmin && eventRequest.clientId !== req.user.id) {
        return res.status(403).json({ message: 'Forbidden: You do not have permission to view quotations for this request' });
      }
      
      const quotations = await storage.getQuotationsByEventRequest(requestId);
      res.json(quotations);
    } catch (error) {
      console.error('Error fetching quotations for event request:', error);
      res.status(500).json({ message: 'Failed to fetch quotations' });
    }
  });
  
  app.post('/api/quotations', async (req, res) => {
    // Only admins can create quotations
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    const hasPermission = await storage.checkAdminPermission(req.user.id, 'manage_quotations');
    if (!hasPermission) {
      return res.status(403).json({ message: 'Forbidden: Insufficient permissions' });
    }
    
    try {
      const quotationData: InsertQuotation = {
        eventRequestId: req.body.eventRequestId,
        adminId: req.user.id,
        totalPrice: req.body.totalAmount, // Use totalPrice instead of totalAmount
        details: { // Convert description to JSON details
          description: req.body.description,
          items: [] // Can be populated with line items in the future
        },
        status: 'pending',
        expiryDate: req.body.expiryDate,
      };
      
      const quotation = await storage.createQuotation(quotationData);
      
      // Also update the event request status to 'quoted'
      await storage.updateEventRequest(req.body.eventRequestId, { status: 'quoted' });
      
      res.status(201).json(quotation);
    } catch (error) {
      console.error('Error creating quotation:', error);
      res.status(500).json({ message: 'Failed to create quotation' });
    }
  });
  
  app.patch('/api/quotations/:id', async (req, res) => {
    // Check authentication
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ message: 'Invalid quotation ID' });
      }
      
      const quotation = await storage.getQuotation(id);
      if (!quotation) {
        return res.status(404).json({ message: 'Quotation not found' });
      }
      
      // Get the associated event request
      const eventRequest = await storage.getEventRequest(quotation.eventRequestId);
      if (!eventRequest) {
        return res.status(404).json({ message: 'Associated event request not found' });
      }
      
      // Check permissions
      const isAdmin = await storage.checkAdminPermission(req.user.id, 'manage_quotations');
      
      // For clients, only allow updating the status to 'accepted' or 'declined'
      if (!isAdmin) {
        if (eventRequest.clientId !== req.user.id) {
          return res.status(403).json({ message: 'Forbidden: You do not have permission to update this quotation' });
        }
        
        if (!req.body.status || (req.body.status !== 'accepted' && req.body.status !== 'declined')) {
          return res.status(403).json({ message: 'Forbidden: You can only accept or decline a quotation' });
        }
        
        // Only allow fields the client can change
        const allowedFields = { status: req.body.status };
        const updatedQuotation = await storage.updateQuotation(id, allowedFields);
        
        // Also update the event request status
        await storage.updateEventRequest(quotation.eventRequestId, { status: req.body.status });
        
        return res.json(updatedQuotation);
      }
      
      // For admins, allow updating any field
      const updatedQuotation = await storage.updateQuotation(id, req.body);
      res.json(updatedQuotation);
    } catch (error) {
      console.error('Error updating quotation:', error);
      res.status(500).json({ message: 'Failed to update quotation' });
    }
  });
  
  // Users map for admin dashboard
  app.get('/api/users/map', async (req, res) => {
    // Only admins can access user map
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    const hasPermission = await storage.checkAdminPermission(req.user.id, 'view_users');
    if (!hasPermission) {
      return res.status(403).json({ message: 'Forbidden: Insufficient permissions' });
    }
    
    try {
      const users = await db.query.users.findMany({
        columns: {
          id: true,
          username: true,
          email: true,
        }
      });
      
      // Convert to a map
      const userMap = users.reduce((acc, user) => {
        acc[user.id] = {
          username: user.username,
          email: user.email
        };
        return acc;
      }, {} as Record<number, { username: string; email: string }>);
      
      res.json(userMap);
    } catch (error) {
      console.error('Error creating user map:', error);
      res.status(500).json({ message: 'Failed to create user map' });
    }
  });
  
  // Admin routes
  app.get('/api/admin/check-permission', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    // Check if user is admin
    if (req.user.userType !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }
    
    try {
      const { permission } = req.query;
      if (!permission) {
        return res.status(400).json({ message: 'Permission parameter is required' });
      }
      
      const hasPermission = await storage.checkAdminPermission(req.user.id, permission as string);
      res.json(hasPermission);
    } catch (error) {
      console.error('Error checking admin permission:', error);
      res.status(500).json({ message: 'Error checking admin permission' });
    }
  });
  
  app.get('/api/admin/bookings', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    // Check if user is admin
    if (req.user.userType !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }
    
    try {
      // Get all bookings for admin
      const bookings = await storage.getAllBookings();
      
      // Enhance bookings with vendor/client data
      const enhancedBookings = await Promise.all(
        bookings.map(async booking => {
          const vendor = await storage.getVendor(booking.vendorId);
          const client = await storage.getUser(booking.clientId);
          
          return {
            ...booking,
            vendor,
            clientName: client?.fullName || client?.username
          };
        })
      );
      
      res.json(enhancedBookings);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching bookings for admin' });
    }
  });
  
  // Admin Users Management Endpoints
  
  // Get all admin users
  app.get('/api/admin/users', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    // Check if user is admin
    if (req.user.userType !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }
    
    try {
      // Check if current admin has permission to manage admins
      const hasPermission = await storage.checkAdminPermission(req.user.id, 'manage_admins');
      if (!hasPermission) {
        return res.status(403).json({ message: 'You do not have permission to manage admin users' });
      }
      
      // Get all admin users
      const adminUsers = await storage.getAdminUsers();
      
      // Enhance admin users with their permissions
      const enhancedAdmins = await Promise.all(
        adminUsers.map(async admin => {
          const permissions = await storage.getUserPermissions(admin.id);
          
          // Don't include password in the response
          const { password, ...adminWithoutPassword } = admin;
          
          return {
            ...adminWithoutPassword,
            permissions
          };
        })
      );
      
      res.json(enhancedAdmins);
    } catch (error) {
      console.error('Error fetching admin users:', error);
      res.status(500).json({ message: 'Error fetching admin users' });
    }
  });
  
  // Create a new admin user
  app.post('/api/admin/users', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    // Check if user is admin
    if (req.user.userType !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }
    
    try {
      // Check if current admin has permission to manage admins
      const hasPermission = await storage.checkAdminPermission(req.user.id, 'manage_admins');
      if (!hasPermission) {
        return res.status(403).json({ message: 'You do not have permission to manage admin users' });
      }
      
      const { username, password, email, fullName, phone, permissions = [] } = req.body;
      
      // Create the new admin user
      const newAdmin = await storage.createUser({
        username,
        password,
        email,
        fullName,
        phone,
        userType: USER_TYPES.ADMIN
      });
      
      // Add permissions for the new admin
      if (permissions.length > 0) {
        await Promise.all(
          permissions.map((permission: string) => 
            storage.addAdminPermission({
              userId: newAdmin.id,
              permission,
              granted: true,
              grantedBy: req.user.id
            })
          )
        );
      }
      
      // Don't return the password
      const { password: _, ...adminWithoutPassword } = newAdmin;
      
      res.status(201).json({
        ...adminWithoutPassword,
        permissions
      });
    } catch (error) {
      console.error('Error creating admin user:', error);
      res.status(500).json({ message: 'Error creating admin user' });
    }
  });
  
  // Update an admin user's permissions
  app.put('/api/admin/users/:id/permissions', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    // Check if user is admin
    if (req.user.userType !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }
    
    try {
      // Check if current admin has permission to manage admins
      const hasPermission = await storage.checkAdminPermission(req.user.id, 'manage_admins');
      if (!hasPermission) {
        return res.status(403).json({ message: 'You do not have permission to manage admin users' });
      }
      
      const adminId = parseInt(req.params.id);
      
      // Can't modify your own permissions
      if (adminId === req.user.id) {
        return res.status(403).json({ message: 'You cannot modify your own permissions' });
      }
      
      const { permissions } = req.body;
      
      // Verify the user exists and is an admin
      const adminUser = await storage.getUser(adminId);
      if (!adminUser) {
        return res.status(404).json({ message: 'Admin user not found' });
      }
      
      if (adminUser.userType !== USER_TYPES.ADMIN) {
        return res.status(400).json({ message: 'User is not an admin' });
      }
      
      // Delete current permissions
      await storage.removeAllUserPermissions(adminId);
      
      // Add new permissions
      if (permissions && permissions.length > 0) {
        await Promise.all(
          permissions.map((permission: string) => 
            storage.addAdminPermission({
              userId: adminId,
              permission,
              granted: true,
              grantedBy: req.user.id
            })
          )
        );
      }
      
      // Return updated user with permissions
      const updatedPermissions = await storage.getUserPermissions(adminId);
      
      res.json({
        id: adminId,
        permissions: updatedPermissions
      });
    } catch (error) {
      console.error('Error updating admin permissions:', error);
      res.status(500).json({ message: 'Error updating admin permissions' });
    }
  });
  
  // Delete an admin user
  app.delete('/api/admin/users/:id', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    // Check if user is admin
    if (req.user.userType !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }
    
    try {
      // Check if current admin has permission to manage admins
      const hasPermission = await storage.checkAdminPermission(req.user.id, 'manage_admins');
      if (!hasPermission) {
        return res.status(403).json({ message: 'You do not have permission to manage admin users' });
      }
      
      const adminId = parseInt(req.params.id);
      
      // Can't delete yourself
      if (adminId === req.user.id) {
        return res.status(403).json({ message: 'You cannot delete your own account' });
      }
      
      // Verify the user exists and is an admin
      const adminUser = await storage.getUser(adminId);
      if (!adminUser) {
        return res.status(404).json({ message: 'Admin user not found' });
      }
      
      if (adminUser.userType !== USER_TYPES.ADMIN) {
        return res.status(400).json({ message: 'User is not an admin' });
      }
      
      // Delete permissions first
      await storage.removeAllUserPermissions(adminId);
      
      // Delete the admin user
      await storage.deleteUser(adminId);
      
      res.status(204).end();
    } catch (error) {
      console.error('Error deleting admin user:', error);
      res.status(500).json({ message: 'Error deleting admin user' });
    }
  });
  
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
  
  app.patch('/api/bookings/:id', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const id = parseInt(req.params.id);
      const booking = await storage.getBooking(id);
      
      if (!booking) {
        return res.status(404).json({ message: 'Booking not found' });
      }
      
      // Check authorization: client who made booking, vendor who received it, or admin
      const vendor = await storage.getVendorByUserId(req.user.id);
      const isAdmin = req.user.userType === 'admin';
      const isClient = booking.clientId === req.user.id;
      const isVendor = vendor && booking.vendorId === vendor.id;
      
      if (!isAdmin && !isClient && !isVendor) {
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
  
  // ========== NEW EVENT-BASED BOOKING FLOW ROUTES ==========
  
  // EVENT TYPES ROUTES (Admin)
  
  // Get all event types 
  app.get('/api/event-types', async (req, res) => {
    try {
      // For public access (no authentication required)
      // Users can see active event types even when not logged in
      const isClient = req.isAuthenticated() && req.user.userType === USER_TYPES.CLIENT;
      
      // If client or not authenticated, only show active event types
      if (!req.isAuthenticated() || isClient) {
        const activeEventTypes = await storage.getActiveEventTypes();
        return res.json(activeEventTypes);
      }
      
      // Admin can see all event types including inactive ones
      const allEventTypes = await storage.getAllEventTypes();
      res.json(allEventTypes);
    } catch (error) {
      console.error('Error fetching event types:', error);
      res.status(500).json({ message: 'Error fetching event types' });
    }
  });
  
  // Get a specific event type by ID
  app.get('/api/event-types/:id', async (req, res) => {
    try {
      const eventType = await storage.getEventType(parseInt(req.params.id));
      
      if (!eventType) {
        return res.status(404).json({ message: 'Event type not found' });
      }
      
      // Non-admins can only see active event types
      if ((!req.isAuthenticated() || req.user.userType !== USER_TYPES.ADMIN) && !eventType.isActive) {
        return res.status(404).json({ message: 'Event type not found' });
      }
      
      res.json(eventType);
    } catch (error) {
      console.error('Error fetching event type:', error);
      res.status(500).json({ message: 'Error fetching event type' });
    }
  });
  
  // Create a new event type (Admin only)
  app.post('/api/admin/event-types', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== USER_TYPES.ADMIN) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    try {
      // Validate the request body
      const eventTypeData: InsertEventType = {
        name: req.body.name,
        description: req.body.description || '',
        icon: req.body.icon || '',
        isActive: req.body.isActive !== undefined ? req.body.isActive : true,
        createdBy: req.user.id,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      const eventType = await storage.createEventType(eventTypeData);
      res.status(201).json(eventType);
    } catch (error) {
      console.error('Error creating event type:', error);
      res.status(500).json({ message: 'Error creating event type' });
    }
  });
  
  // Update an event type (Admin only)
  app.put('/api/admin/event-types/:id', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== USER_TYPES.ADMIN) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    try {
      const id = parseInt(req.params.id);
      const eventType = await storage.getEventType(id);
      
      if (!eventType) {
        return res.status(404).json({ message: 'Event type not found' });
      }
      
      // Update the event type
      const updatedEventType = await storage.updateEventType(id, {
        name: req.body.name !== undefined ? req.body.name : eventType.name,
        description: req.body.description !== undefined ? req.body.description : eventType.description,
        icon: req.body.icon !== undefined ? req.body.icon : eventType.icon,
        isActive: req.body.isActive !== undefined ? req.body.isActive : eventType.isActive,
        updatedAt: new Date()
      });
      
      res.json(updatedEventType);
    } catch (error) {
      console.error('Error updating event type:', error);
      res.status(500).json({ message: 'Error updating event type' });
    }
  });
  
  // Delete an event type (Admin only)
  app.delete('/api/admin/event-types/:id', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== USER_TYPES.ADMIN) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    try {
      const id = parseInt(req.params.id);
      const eventType = await storage.getEventType(id);
      
      if (!eventType) {
        return res.status(404).json({ message: 'Event type not found' });
      }
      
      // Instead of deleting, we can just mark it as inactive
      await storage.updateEventType(id, { isActive: false });
      
      res.status(204).end();
    } catch (error) {
      console.error('Error deleting event type:', error);
      res.status(500).json({ message: 'Error deleting event type' });
    }
  });
  
  // QUESTIONNAIRE ITEMS ROUTES (Admin)
  
  // Get questionnaire items for an event type
  app.get('/api/event-types/:eventTypeId/questions', async (req, res) => {
    try {
      const eventTypeId = parseInt(req.params.eventTypeId);
      const eventType = await storage.getEventType(eventTypeId);
      
      if (!eventType) {
        return res.status(404).json({ message: 'Event type not found' });
      }
      
      // Non-admins can only see questions for active event types
      if ((!req.isAuthenticated() || req.user.userType !== USER_TYPES.ADMIN) && !eventType.isActive) {
        return res.status(404).json({ message: 'Event type not found' });
      }
      
      const questions = await storage.getQuestionnaireItemsByEventType(eventTypeId);
      res.json(questions);
    } catch (error) {
      console.error('Error fetching questionnaire items:', error);
      res.status(500).json({ message: 'Error fetching questionnaire items' });
    }
  });
  
  // Create a new questionnaire item (Admin only)
  app.post('/api/admin/event-types/:eventTypeId/questions', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== USER_TYPES.ADMIN) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    try {
      const eventTypeId = parseInt(req.params.eventTypeId);
      const eventType = await storage.getEventType(eventTypeId);
      
      if (!eventType) {
        return res.status(404).json({ message: 'Event type not found' });
      }
      
      // Validate the request body
      const questionData: InsertQuestionnaireItem = {
        eventTypeId,
        questionText: req.body.questionText,
        questionType: req.body.questionType,
        options: req.body.options,
        required: req.body.required !== undefined ? req.body.required : false,
        displayOrder: req.body.displayOrder,
        createdBy: req.user.id,
        createdAt: new Date()
      };
      
      const question = await storage.createQuestionnaireItem(questionData);
      res.status(201).json(question);
    } catch (error) {
      console.error('Error creating questionnaire item:', error);
      res.status(500).json({ message: 'Error creating questionnaire item' });
    }
  });
  
  // Update a questionnaire item (Admin only)
  app.put('/api/admin/questions/:id', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== USER_TYPES.ADMIN) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    try {
      const id = parseInt(req.params.id);
      const question = await storage.getQuestionnaireItem(id);
      
      if (!question) {
        return res.status(404).json({ message: 'Question not found' });
      }
      
      // Update the question
      const updatedQuestion = await storage.updateQuestionnaireItem(id, {
        questionText: req.body.questionText !== undefined ? req.body.questionText : question.questionText,
        questionType: req.body.questionType !== undefined ? req.body.questionType : question.questionType,
        options: req.body.options !== undefined ? req.body.options : question.options,
        required: req.body.required !== undefined ? req.body.required : question.required,
        displayOrder: req.body.displayOrder !== undefined ? req.body.displayOrder : question.displayOrder
      });
      
      res.json(updatedQuestion);
    } catch (error) {
      console.error('Error updating questionnaire item:', error);
      res.status(500).json({ message: 'Error updating questionnaire item' });
    }
  });
  
  // Delete a questionnaire item (Admin only)
  app.delete('/api/admin/questions/:id', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== USER_TYPES.ADMIN) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    try {
      const id = parseInt(req.params.id);
      const question = await storage.getQuestionnaireItem(id);
      
      if (!question) {
        return res.status(404).json({ message: 'Question not found' });
      }
      
      await storage.deleteQuestionnaireItem(id);
      res.status(204).end();
    } catch (error) {
      console.error('Error deleting questionnaire item:', error);
      res.status(500).json({ message: 'Error deleting questionnaire item' });
    }
  });
  
  // EVENT REQUESTS ROUTES (Client)
  
  // Create a new event request (Client)
  app.post('/api/event-requests', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const eventTypeId = parseInt(req.body.eventTypeId);
      const eventType = await storage.getEventType(eventTypeId);
      
      if (!eventType || !eventType.isActive) {
        return res.status(404).json({ message: 'Event type not found or inactive' });
      }
      
      // Validate the request body
      if (!req.body.responses) {
        return res.status(400).json({ message: 'Responses are required' });
      }
      
      // Create the event request
      const eventRequestData: InsertEventRequest = {
        clientId: req.user.id,
        eventTypeId,
        status: BOOKING_STATUS.PENDING,
        responses: req.body.responses,
        eventDate: req.body.eventDate ? new Date(req.body.eventDate) : null,
        budget: req.body.budget || null,
        specialRequests: req.body.specialRequests || '',
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      const eventRequest = await storage.createEventRequest(eventRequestData);
      res.status(201).json(eventRequest);
    } catch (error) {
      console.error('Error creating event request:', error);
      res.status(500).json({ message: 'Error creating event request' });
    }
  });
  
  // Get all event requests for a client
  app.get('/api/event-requests', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      let eventRequests;
      
      if (req.user.userType === USER_TYPES.CLIENT) {
        // Clients can only see their own requests
        eventRequests = await storage.getEventRequestsByClient(req.user.id);
      } else if (req.user.userType === USER_TYPES.ADMIN) {
        // Admins can see all requests
        eventRequests = await storage.getAllEventRequests();
      } else {
        return res.status(403).json({ message: 'Not authorized' });
      }
      
      // Enhance the requests with event type names
      const enhancedRequests = await Promise.all(
        eventRequests.map(async request => {
          const eventType = await storage.getEventType(request.eventTypeId);
          return {
            ...request,
            eventTypeName: eventType?.name || 'Unknown Event Type'
          };
        })
      );
      
      res.json(enhancedRequests);
    } catch (error) {
      console.error('Error fetching event requests:', error);
      res.status(500).json({ message: 'Error fetching event requests' });
    }
  });
  
  // Get a specific event request by ID
  app.get('/api/event-requests/:id', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const id = parseInt(req.params.id);
      const eventRequest = await storage.getEventRequest(id);
      
      if (!eventRequest) {
        return res.status(404).json({ message: 'Event request not found' });
      }
      
      // Clients can only view their own requests
      if (req.user.userType === USER_TYPES.CLIENT && eventRequest.clientId !== req.user.id) {
        return res.status(403).json({ message: 'Not authorized' });
      }
      
      // Enhance with event type and client info
      const eventType = await storage.getEventType(eventRequest.eventTypeId);
      const client = await storage.getUser(eventRequest.clientId);
      
      // Get quotations for this request
      const quotations = await storage.getQuotationsByEventRequest(id);
      
      const enhancedRequest = {
        ...eventRequest,
        eventTypeName: eventType?.name || 'Unknown Event Type',
        clientName: client?.fullName || client?.username || 'Unknown Client',
        quotations
      };
      
      res.json(enhancedRequest);
    } catch (error) {
      console.error('Error fetching event request:', error);
      res.status(500).json({ message: 'Error fetching event request' });
    }
  });
  
  // QUOTATION ROUTES (Admin)
  
  // Create a quotation for an event request (Admin only)
  app.post('/api/admin/event-requests/:eventRequestId/quotations', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    if (req.user.userType !== USER_TYPES.ADMIN) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    try {
      const eventRequestId = parseInt(req.params.eventRequestId);
      const eventRequest = await storage.getEventRequest(eventRequestId);
      
      if (!eventRequest) {
        return res.status(404).json({ message: 'Event request not found' });
      }
      
      // Update the event request status to quotation sent
      await storage.updateEventRequest(eventRequestId, {
        status: BOOKING_STATUS.QUOTATION_SENT,
        updatedAt: new Date()
      });
      
      // Create the quotation
      const quotationData: InsertQuotation = {
        eventRequestId,
        adminId: req.user.id,
        totalPrice: req.body.totalPrice,
        details: req.body.details,
        notes: req.body.notes || '',
        expiryDate: req.body.expiryDate ? new Date(req.body.expiryDate) : null,
        status: BOOKING_STATUS.QUOTATION_SENT,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      const quotation = await storage.createQuotation(quotationData);
      res.status(201).json(quotation);
    } catch (error) {
      console.error('Error creating quotation:', error);
      res.status(500).json({ message: 'Error creating quotation' });
    }
  });
  
  // Update an event request quotation status (Client)
  app.patch('/api/event-requests/:id/quotation/:quotationId', async (req, res) => {
    if (!req.isAuthenticated()) {
      return res.status(401).json({ message: 'Not authenticated' });
    }
    
    try {
      const eventRequestId = parseInt(req.params.id);
      const quotationId = parseInt(req.params.quotationId);
      
      const eventRequest = await storage.getEventRequest(eventRequestId);
      if (!eventRequest) {
        return res.status(404).json({ message: 'Event request not found' });
      }
      
      // Clients can only update their own requests
      if (req.user.userType === USER_TYPES.CLIENT && eventRequest.clientId !== req.user.id) {
        return res.status(403).json({ message: 'Not authorized' });
      }
      
      const quotation = await storage.getQuotation(quotationId);
      if (!quotation || quotation.eventRequestId !== eventRequestId) {
        return res.status(404).json({ message: 'Quotation not found' });
      }
      
      // Process the client's response to the quotation
      const { action } = req.body;
      let newStatus;
      
      if (action === 'accept') {
        newStatus = BOOKING_STATUS.QUOTATION_ACCEPTED;
      } else if (action === 'reject') {
        newStatus = BOOKING_STATUS.QUOTATION_REJECTED;
      } else {
        return res.status(400).json({ message: 'Invalid action. Use "accept" or "reject".' });
      }
      
      // Update both the quotation and the event request status
      await storage.updateQuotation(quotationId, { 
        status: newStatus,
        updatedAt: new Date()
      });
      
      await storage.updateEventRequest(eventRequestId, {
        status: newStatus,
        updatedAt: new Date()
      });
      
      // If accepted, additional steps might be needed
      if (newStatus === BOOKING_STATUS.QUOTATION_ACCEPTED) {
        // In the future: create an actual booking, schedule the event, etc.
      }
      
      res.json({ message: `Quotation ${action}ed successfully` });
    } catch (error) {
      console.error('Error updating quotation status:', error);
      res.status(500).json({ message: 'Error updating quotation status' });
    }
  });
  
  return httpServer;
}
