import { db } from "./db";
import { 
  users, vendors, services, bookings, messages, reviews, adminPermissions,
  eventTypes, questionnaireItems, eventRequests, quotations,
  User, Vendor, Service, Booking, Message, Review, AdminPermission,
  EventType, QuestionnaireItem, EventRequest, Quotation,
  InsertUser, InsertVendor, InsertService, InsertBooking, InsertMessage, InsertReview, InsertAdminPermission,
  InsertEventType, InsertQuestionnaireItem, InsertEventRequest, InsertQuotation,
  BOOKING_STATUS, USER_TYPES, ADMIN_PERMISSIONS
} from "@shared/schema";
import { eq, and, or, ilike, desc, sql } from "drizzle-orm";
import session from "express-session";
import connectPg from "connect-pg-simple";
import { pool } from "./db";
import { scrypt, randomBytes, timingSafeEqual } from "crypto";
import { promisify } from "util";

const scryptAsync = promisify(scrypt);

async function hashPassword(password: string) {
  const salt = randomBytes(16).toString("hex");
  const buf = (await scryptAsync(password, salt, 64)) as Buffer;
  return `${buf.toString("hex")}.${salt}`;
}

async function comparePasswords(supplied: string, stored: string) {
  const [hashed, salt] = stored.split(".");
  const hashedBuf = Buffer.from(hashed, "hex");
  const suppliedBuf = (await scryptAsync(supplied, salt, 64)) as Buffer;
  return timingSafeEqual(hashedBuf, suppliedBuf);
}

const PostgresSessionStore = connectPg(session);

export interface IStorage {
  // Users
  getUser(id: number): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  getUserByEmail(email: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;
  updateUser(id: number, user: Partial<User>): Promise<User | undefined>;
  deleteUser(id: number): Promise<void>;
  
  // Admin Users
  getAdminUsers(): Promise<User[]>;
  
  // Admin Permissions
  getUserPermissions(userId: number): Promise<string[]>;
  checkAdminPermission(userId: number, permission: string): Promise<boolean>;
  addAdminPermission(permission: InsertAdminPermission): Promise<AdminPermission>;
  removeAdminPermission(userId: number, permission: string): Promise<void>;
  removeAllUserPermissions(userId: number): Promise<void>;
  
  // Vendors
  getVendor(id: number): Promise<Vendor | undefined>;
  getVendorByUserId(userId: number): Promise<Vendor | undefined>;
  getVendorsByCategory(category: string): Promise<Vendor[]>;
  getAllVendors(): Promise<Vendor[]>;
  searchVendors(query: string): Promise<Vendor[]>;
  createVendor(vendor: InsertVendor): Promise<Vendor>;
  updateVendor(id: number, vendor: Partial<Vendor>): Promise<Vendor | undefined>;
  
  // Services
  getService(id: number): Promise<Service | undefined>;
  getServicesByVendor(vendorId: number): Promise<Service[]>;
  createService(service: InsertService): Promise<Service>;
  updateService(id: number, service: Partial<Service>): Promise<Service | undefined>;
  
  // Bookings
  getBooking(id: number): Promise<Booking | undefined>;
  getBookingsByClient(clientId: number): Promise<Booking[]>;
  getBookingsByVendor(vendorId: number): Promise<Booking[]>;
  getAllBookings(): Promise<Booking[]>;
  createBooking(booking: InsertBooking): Promise<Booking>;
  updateBooking(id: number, booking: Partial<Booking>): Promise<Booking | undefined>;
  
  // Messages
  getMessage(id: number): Promise<Message | undefined>;
  getMessagesBetweenUsers(userId1: number, userId2: number): Promise<Message[]>;
  createMessage(message: InsertMessage): Promise<Message>;
  markMessageAsRead(id: number): Promise<Message | undefined>;
  
  // Reviews
  getReview(id: number): Promise<Review | undefined>;
  getReviewsByVendor(vendorId: number): Promise<Review[]>;
  createReview(review: InsertReview): Promise<Review>;
  
  // Session store
  sessionStore: session.Store;
  
  // Password verification
  verifyPassword(plaintext: string, hashed: string): Promise<boolean>;
  
  // Event Types Management (Admin)
  getEventType(id: number): Promise<EventType | undefined>;
  getAllEventTypes(): Promise<EventType[]>;
  getActiveEventTypes(): Promise<EventType[]>;
  createEventType(eventType: InsertEventType): Promise<EventType>;
  updateEventType(id: number, eventType: Partial<EventType>): Promise<EventType | undefined>;
  deleteEventType(id: number): Promise<void>;
  
  // Questionnaire Items Management
  getQuestionnaireItem(id: number): Promise<QuestionnaireItem | undefined>;
  getQuestionnaireItemsByEventType(eventTypeId: number): Promise<QuestionnaireItem[]>;
  createQuestionnaireItem(questionnaireItem: InsertQuestionnaireItem): Promise<QuestionnaireItem>;
  updateQuestionnaireItem(id: number, questionnaireItem: Partial<QuestionnaireItem>): Promise<QuestionnaireItem | undefined>;
  deleteQuestionnaireItem(id: number): Promise<void>;
  
  // Event Requests (Client)
  getEventRequest(id: number): Promise<EventRequest | undefined>;
  getEventRequestsByClient(clientId: number): Promise<EventRequest[]>;
  getEventRequestsByEventType(eventTypeId: number): Promise<EventRequest[]>;
  getAllEventRequests(): Promise<EventRequest[]>;
  createEventRequest(eventRequest: InsertEventRequest): Promise<EventRequest>;
  updateEventRequest(id: number, eventRequest: Partial<EventRequest>): Promise<EventRequest | undefined>;
  
  // Quotations (Admin)
  getQuotation(id: number): Promise<Quotation | undefined>;
  getQuotationsByEventRequest(eventRequestId: number): Promise<Quotation[]>;
  createQuotation(quotation: InsertQuotation): Promise<Quotation>;
  updateQuotation(id: number, quotation: Partial<Quotation>): Promise<Quotation | undefined>;
}

export class DatabaseStorage implements IStorage {
  sessionStore: session.Store;

  constructor() {
    this.sessionStore = new PostgresSessionStore({ 
      pool, 
      createTableIfMissing: true 
    });
  }

  // Users
  async getUser(id: number): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.id, id));
    return user;
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.username, username));
    return user;
  }

  async getUserByEmail(email: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.email, email));
    return user;
  }

  async createUser(insertUser: InsertUser): Promise<User> {
    // Hash password before storing
    const hashedPassword = await hashPassword(insertUser.password);
    const userWithHashedPassword = {
      ...insertUser,
      password: hashedPassword
    };

    const [user] = await db.insert(users).values(userWithHashedPassword).returning();
    return user;
  }

  async updateUser(id: number, userData: Partial<User>): Promise<User | undefined> {
    const [user] = await db
      .update(users)
      .set(userData)
      .where(eq(users.id, id))
      .returning();
    return user;
  }

  // Vendors
  async getVendor(id: number): Promise<Vendor | undefined> {
    const [vendor] = await db.select().from(vendors).where(eq(vendors.id, id));
    return vendor;
  }

  async getVendorByUserId(userId: number): Promise<Vendor | undefined> {
    const [vendor] = await db.select().from(vendors).where(eq(vendors.userId, userId));
    return vendor;
  }

  async getVendorsByCategory(category: string): Promise<Vendor[]> {
    return await db.select().from(vendors).where(eq(vendors.category, category));
  }

  async getAllVendors(): Promise<Vendor[]> {
    return await db.select().from(vendors);
  }

  async searchVendors(query: string): Promise<Vendor[]> {
    return await db
      .select()
      .from(vendors)
      .where(
        or(
          ilike(vendors.businessName, `%${query}%`),
          ilike(vendors.description, `%${query}%`),
          ilike(vendors.category, `%${query}%`)
        )
      );
  }

  async createVendor(insertVendor: InsertVendor): Promise<Vendor> {
    const [vendor] = await db.insert(vendors).values(insertVendor).returning();
    return vendor;
  }

  async updateVendor(id: number, vendorData: Partial<Vendor>): Promise<Vendor | undefined> {
    const [vendor] = await db
      .update(vendors)
      .set(vendorData)
      .where(eq(vendors.id, id))
      .returning();
    return vendor;
  }

  // Services
  async getService(id: number): Promise<Service | undefined> {
    const [service] = await db.select().from(services).where(eq(services.id, id));
    return service;
  }

  async getServicesByVendor(vendorId: number): Promise<Service[]> {
    return await db.select().from(services).where(eq(services.vendorId, vendorId));
  }

  async createService(insertService: InsertService): Promise<Service> {
    const [service] = await db.insert(services).values(insertService).returning();
    return service;
  }

  async updateService(id: number, serviceData: Partial<Service>): Promise<Service | undefined> {
    const [service] = await db
      .update(services)
      .set(serviceData)
      .where(eq(services.id, id))
      .returning();
    return service;
  }

  // Bookings
  async getBooking(id: number): Promise<Booking | undefined> {
    const [booking] = await db.select().from(bookings).where(eq(bookings.id, id));
    return booking;
  }

  async getBookingsByClient(clientId: number): Promise<Booking[]> {
    return await db.select().from(bookings).where(eq(bookings.clientId, clientId));
  }

  async getBookingsByVendor(vendorId: number): Promise<Booking[]> {
    return await db.select().from(bookings).where(eq(bookings.vendorId, vendorId));
  }
  
  async getAllBookings(): Promise<Booking[]> {
    return await db.select().from(bookings);
  }

  async createBooking(insertBooking: InsertBooking): Promise<Booking> {
    try {
      console.log("Database - creating booking with data:", JSON.stringify(insertBooking, null, 2));
      
      // Ensure all required fields are present
      if (!insertBooking.clientId) throw new Error("clientId is required");
      if (!insertBooking.vendorId) throw new Error("vendorId is required");
      if (!insertBooking.eventType) throw new Error("eventType is required");
      if (!insertBooking.eventDate) throw new Error("eventDate is required");
      
      // Format eventDate properly if it's a string
      if (typeof insertBooking.eventDate === 'string') {
        insertBooking.eventDate = new Date(insertBooking.eventDate);
      }
      
      // Convert guestCount to number if it's a string
      if (typeof insertBooking.guestCount === 'string') {
        insertBooking.guestCount = parseInt(insertBooking.guestCount, 10);
      }
      
      // Convert totalPrice to number if it's a string
      if (typeof insertBooking.totalPrice === 'string') {
        insertBooking.totalPrice = parseFloat(insertBooking.totalPrice);
      }
      
      // Set default values if not provided
      const bookingToCreate = {
        ...insertBooking,
        status: insertBooking.status || BOOKING_STATUS.PENDING,
        specialRequests: insertBooking.specialRequests || null,
        serviceId: insertBooking.serviceId || null
      };
      
      console.log("Database - final booking data:", JSON.stringify(bookingToCreate, null, 2));
      
      const [booking] = await db.insert(bookings).values(bookingToCreate).returning();
      return booking;
    } catch (error) {
      console.error("Database error in createBooking:", error);
      throw error;
    }
  }

  async updateBooking(id: number, bookingData: Partial<Booking>): Promise<Booking | undefined> {
    const [booking] = await db
      .update(bookings)
      .set(bookingData)
      .where(eq(bookings.id, id))
      .returning();
    return booking;
  }

  // Messages
  async getMessage(id: number): Promise<Message | undefined> {
    const [message] = await db.select().from(messages).where(eq(messages.id, id));
    return message;
  }

  async getMessagesBetweenUsers(userId1: number, userId2: number): Promise<Message[]> {
    return await db
      .select()
      .from(messages)
      .where(
        or(
          and(
            eq(messages.senderId, userId1),
            eq(messages.receiverId, userId2)
          ),
          and(
            eq(messages.senderId, userId2),
            eq(messages.receiverId, userId1)
          )
        )
      )
      .orderBy(messages.createdAt);
  }

  async createMessage(insertMessage: InsertMessage): Promise<Message> {
    const [message] = await db.insert(messages).values(insertMessage).returning();
    return message;
  }

  async markMessageAsRead(id: number): Promise<Message | undefined> {
    const [message] = await db
      .update(messages)
      .set({ read: true })
      .where(eq(messages.id, id))
      .returning();
    return message;
  }

  // Reviews
  async getReview(id: number): Promise<Review | undefined> {
    const [review] = await db.select().from(reviews).where(eq(reviews.id, id));
    return review;
  }

  async getReviewsByVendor(vendorId: number): Promise<Review[]> {
    return await db
      .select()
      .from(reviews)
      .where(eq(reviews.vendorId, vendorId))
      .orderBy(desc(reviews.createdAt));
  }

  async createReview(insertReview: InsertReview): Promise<Review> {
    const [review] = await db.insert(reviews).values(insertReview).returning();
    return review;
  }

  // Admin Users
  async getAdminUsers(): Promise<User[]> {
    return await db
      .select()
      .from(users)
      .where(eq(users.userType, USER_TYPES.ADMIN));
  }
  
  // Admin Permissions
  async getUserPermissions(userId: number): Promise<string[]> {
    const perms = await db
      .select()
      .from(adminPermissions)
      .where(
        and(
          eq(adminPermissions.userId, userId),
          eq(adminPermissions.granted, true)
        )
      );
    
    return perms.map(p => p.permission);
  }
  
  async checkAdminPermission(userId: number, permission: string): Promise<boolean> {
    // First check if user is an admin
    const user = await this.getUser(userId);
    if (!user || user.userType !== USER_TYPES.ADMIN) {
      return false;
    }
    
    // Super admin has all permissions by default
    const permissions = await this.getUserPermissions(userId);
    
    // If user has no permissions but is the first admin, grant all permissions (super admin)
    if (permissions.length === 0) {
      // Check if this is the first admin user
      const adminUsers = await this.getAdminUsers();
      if (adminUsers.length === 1 && adminUsers[0].id === userId) {
        // First admin is automatically a super admin
        return true;
      }
      return false;
    }
    
    return permissions.includes(permission);
  }
  
  async addAdminPermission(permission: InsertAdminPermission): Promise<AdminPermission> {
    try {
      const [adminPermission] = await db
        .insert(adminPermissions)
        .values(permission)
        .returning();
      return adminPermission;
    } catch (error) {
      console.error("Error adding admin permission:", error);
      throw error;
    }
  }
  
  async removeAdminPermission(userId: number, permission: string): Promise<void> {
    await db
      .delete(adminPermissions)
      .where(
        and(
          eq(adminPermissions.userId, userId),
          eq(adminPermissions.permission, permission)
        )
      );
  }
  
  async removeAllUserPermissions(userId: number): Promise<void> {
    await db
      .delete(adminPermissions)
      .where(eq(adminPermissions.userId, userId));
  }
  
  async deleteUser(id: number): Promise<void> {
    // Delete all permissions first to avoid foreign key constraints
    await this.removeAllUserPermissions(id);
    
    // Delete user
    await db
      .delete(users)
      .where(eq(users.id, id));
  }

  // Password verification
  async verifyPassword(plaintext: string, hashed: string): Promise<boolean> {
    return comparePasswords(plaintext, hashed);
  }

  // Event Types Management methods
  async getEventType(id: number): Promise<EventType | undefined> {
    const [eventType] = await db.select().from(eventTypes).where(eq(eventTypes.id, id));
    return eventType;
  }

  async getAllEventTypes(): Promise<EventType[]> {
    return db.select().from(eventTypes).orderBy(eventTypes.name);
  }

  async getActiveEventTypes(): Promise<EventType[]> {
    return db.select().from(eventTypes).where(eq(eventTypes.isActive, true)).orderBy(eventTypes.name);
  }

  async createEventType(eventTypeData: InsertEventType): Promise<EventType> {
    const [eventType] = await db.insert(eventTypes).values(eventTypeData).returning();
    return eventType;
  }

  async updateEventType(id: number, eventTypeData: Partial<EventType>): Promise<EventType | undefined> {
    const [updatedEventType] = await db
      .update(eventTypes)
      .set({ ...eventTypeData, updatedAt: new Date() })
      .where(eq(eventTypes.id, id))
      .returning();
    return updatedEventType;
  }

  async deleteEventType(id: number): Promise<void> {
    await db.delete(eventTypes).where(eq(eventTypes.id, id));
  }

  // Questionnaire Items Management methods
  async getQuestionnaireItem(id: number): Promise<QuestionnaireItem | undefined> {
    const [item] = await db.select().from(questionnaireItems).where(eq(questionnaireItems.id, id));
    return item;
  }

  async getQuestionnaireItemsByEventType(eventTypeId: number): Promise<QuestionnaireItem[]> {
    return db
      .select()
      .from(questionnaireItems)
      .where(eq(questionnaireItems.eventTypeId, eventTypeId))
      .orderBy(questionnaireItems.displayOrder);
  }

  async createQuestionnaireItem(itemData: InsertQuestionnaireItem): Promise<QuestionnaireItem> {
    const [item] = await db.insert(questionnaireItems).values(itemData).returning();
    return item;
  }

  async updateQuestionnaireItem(
    id: number, 
    itemData: Partial<QuestionnaireItem>
  ): Promise<QuestionnaireItem | undefined> {
    const [updatedItem] = await db
      .update(questionnaireItems)
      .set(itemData)
      .where(eq(questionnaireItems.id, id))
      .returning();
    return updatedItem;
  }

  async deleteQuestionnaireItem(id: number): Promise<void> {
    await db.delete(questionnaireItems).where(eq(questionnaireItems.id, id));
  }

  // Event Requests methods
  async getEventRequest(id: number): Promise<EventRequest | undefined> {
    const [request] = await db.select().from(eventRequests).where(eq(eventRequests.id, id));
    return request;
  }

  async getEventRequestsByClient(clientId: number): Promise<EventRequest[]> {
    return db
      .select()
      .from(eventRequests)
      .where(eq(eventRequests.clientId, clientId))
      .orderBy(desc(eventRequests.createdAt));
  }

  async getEventRequestsByEventType(eventTypeId: number): Promise<EventRequest[]> {
    return db
      .select()
      .from(eventRequests)
      .where(eq(eventRequests.eventTypeId, eventTypeId))
      .orderBy(desc(eventRequests.createdAt));
  }

  async getAllEventRequests(): Promise<EventRequest[]> {
    return db.select().from(eventRequests).orderBy(desc(eventRequests.createdAt));
  }

  async createEventRequest(requestData: InsertEventRequest): Promise<EventRequest> {
    // Ensure eventDate is a proper Date object or null
    const data = {
      ...requestData,
      eventDate: requestData.eventDate ? new Date(requestData.eventDate as any) : null
    };
    
    const [request] = await db.insert(eventRequests).values(data).returning();
    return request;
  }

  async updateEventRequest(id: number, requestData: Partial<EventRequest>): Promise<EventRequest | undefined> {
    const [updatedRequest] = await db
      .update(eventRequests)
      .set({ ...requestData, updatedAt: new Date() })
      .where(eq(eventRequests.id, id))
      .returning();
    return updatedRequest;
  }

  // Quotations methods
  async getQuotation(id: number): Promise<Quotation | undefined> {
    const [quotation] = await db.select().from(quotations).where(eq(quotations.id, id));
    return quotation;
  }

  async getQuotationsByEventRequest(eventRequestId: number): Promise<Quotation[]> {
    return db
      .select()
      .from(quotations)
      .where(eq(quotations.eventRequestId, eventRequestId))
      .orderBy(desc(quotations.createdAt));
  }

  async createQuotation(quotationData: InsertQuotation): Promise<Quotation> {
    const [quotation] = await db.insert(quotations).values(quotationData).returning();
    return quotation;
  }

  async updateQuotation(id: number, quotationData: Partial<Quotation>): Promise<Quotation | undefined> {
    const [updatedQuotation] = await db
      .update(quotations)
      .set({ ...quotationData, updatedAt: new Date() })
      .where(eq(quotations.id, id))
      .returning();
    return updatedQuotation;
  }
}

export const storage = new DatabaseStorage();