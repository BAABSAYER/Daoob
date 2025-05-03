import { 
  users, vendors, services, bookings, messages, reviews,
  type User, type InsertUser,
  type Vendor, type InsertVendor,
  type Service, type InsertService,
  type Booking, type InsertBooking,
  type Message, type InsertMessage, 
  type Review, type InsertReview
} from "@shared/schema";
import session from "express-session";
import createMemoryStore from "memorystore";
import { scrypt, randomBytes, timingSafeEqual } from "crypto";
import { promisify } from "util";

const scryptAsync = promisify(scrypt);
const MemoryStore = createMemoryStore(session);

// Helper for password hashing
async function hashPassword(password: string) {
  const salt = randomBytes(16).toString("hex");
  const buf = (await scryptAsync(password, salt, 64)) as Buffer;
  return `${buf.toString("hex")}.${salt}`;
}

export interface IStorage {
  // Users
  getUser(id: number): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  getUserByEmail(email: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;
  updateUser(id: number, user: Partial<User>): Promise<User | undefined>;
  
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
}

export class MemStorage implements IStorage {
  private users: Map<number, User>;
  private vendors: Map<number, Vendor>;
  private services: Map<number, Service>;
  private bookings: Map<number, Booking>;
  private messages: Map<number, Message>;
  private reviews: Map<number, Review>;
  
  sessionStore: session.Store;
  
  private userIdCounter: number;
  private vendorIdCounter: number;
  private serviceIdCounter: number;
  private bookingIdCounter: number;
  private messageIdCounter: number;
  private reviewIdCounter: number;
  
  constructor() {
    this.users = new Map();
    this.vendors = new Map();
    this.services = new Map();
    this.bookings = new Map();
    this.messages = new Map();
    this.reviews = new Map();
    
    this.userIdCounter = 1;
    this.vendorIdCounter = 1;
    this.serviceIdCounter = 1;
    this.bookingIdCounter = 1;
    this.messageIdCounter = 1;
    this.reviewIdCounter = 1;
    
    this.sessionStore = new MemoryStore({
      checkPeriod: 86400000 // 24 hours
    });
    
    // Initialize with some data
    this.initializeData();
  }
  
  // Initialize some sample data
  private async initializeData() {
    // This is only for initial app setup, not displaying mock data to users
  }
  
  // User methods
  async getUser(id: number): Promise<User | undefined> {
    return this.users.get(id);
  }
  
  async getUserByUsername(username: string): Promise<User | undefined> {
    return Array.from(this.users.values()).find(
      (user) => user.username.toLowerCase() === username.toLowerCase()
    );
  }
  
  async getUserByEmail(email: string): Promise<User | undefined> {
    return Array.from(this.users.values()).find(
      (user) => user.email.toLowerCase() === email.toLowerCase()
    );
  }
  
  async createUser(insertUser: InsertUser): Promise<User> {
    const id = this.userIdCounter++;
    const now = new Date();
    
    // Hash password if it's plaintext
    let password = insertUser.password;
    if (!password.includes('.')) {
      password = await hashPassword(password);
    }
    
    const user: User = { 
      ...insertUser, 
      id, 
      password,
      createdAt: now 
    };
    
    this.users.set(id, user);
    return user;
  }
  
  async updateUser(id: number, userData: Partial<User>): Promise<User | undefined> {
    const user = await this.getUser(id);
    if (!user) return undefined;
    
    const updatedUser = { ...user, ...userData };
    this.users.set(id, updatedUser);
    return updatedUser;
  }
  
  // Vendor methods
  async getVendor(id: number): Promise<Vendor | undefined> {
    return this.vendors.get(id);
  }
  
  async getVendorByUserId(userId: number): Promise<Vendor | undefined> {
    return Array.from(this.vendors.values()).find(
      (vendor) => vendor.userId === userId
    );
  }
  
  async getVendorsByCategory(category: string): Promise<Vendor[]> {
    return Array.from(this.vendors.values()).filter(
      (vendor) => vendor.category === category
    );
  }
  
  async getAllVendors(): Promise<Vendor[]> {
    return Array.from(this.vendors.values());
  }
  
  async searchVendors(query: string): Promise<Vendor[]> {
    query = query.toLowerCase();
    return Array.from(this.vendors.values()).filter(vendor => {
      const businessName = vendor.businessName.toLowerCase();
      const description = vendor.description?.toLowerCase() || '';
      const category = vendor.category.toLowerCase();
      const city = vendor.city?.toLowerCase() || '';
      
      return businessName.includes(query) || 
             description.includes(query) || 
             category.includes(query) || 
             city.includes(query);
    });
  }
  
  async createVendor(insertVendor: InsertVendor): Promise<Vendor> {
    const id = this.vendorIdCounter++;
    
    const vendor: Vendor = {
      ...insertVendor,
      id,
      rating: 0,
      reviewCount: 0
    };
    
    this.vendors.set(id, vendor);
    return vendor;
  }
  
  async updateVendor(id: number, vendorData: Partial<Vendor>): Promise<Vendor | undefined> {
    const vendor = await this.getVendor(id);
    if (!vendor) return undefined;
    
    const updatedVendor = { ...vendor, ...vendorData };
    this.vendors.set(id, updatedVendor);
    return updatedVendor;
  }
  
  // Service methods
  async getService(id: number): Promise<Service | undefined> {
    return this.services.get(id);
  }
  
  async getServicesByVendor(vendorId: number): Promise<Service[]> {
    return Array.from(this.services.values()).filter(
      (service) => service.vendorId === vendorId
    );
  }
  
  async createService(insertService: InsertService): Promise<Service> {
    const id = this.serviceIdCounter++;
    
    const service: Service = {
      ...insertService,
      id
    };
    
    this.services.set(id, service);
    return service;
  }
  
  async updateService(id: number, serviceData: Partial<Service>): Promise<Service | undefined> {
    const service = await this.getService(id);
    if (!service) return undefined;
    
    const updatedService = { ...service, ...serviceData };
    this.services.set(id, updatedService);
    return updatedService;
  }
  
  // Booking methods
  async getBooking(id: number): Promise<Booking | undefined> {
    return this.bookings.get(id);
  }
  
  async getBookingsByClient(clientId: number): Promise<Booking[]> {
    return Array.from(this.bookings.values()).filter(
      (booking) => booking.clientId === clientId
    );
  }
  
  async getBookingsByVendor(vendorId: number): Promise<Booking[]> {
    return Array.from(this.bookings.values()).filter(
      (booking) => booking.vendorId === vendorId
    );
  }
  
  async createBooking(insertBooking: InsertBooking): Promise<Booking> {
    const id = this.bookingIdCounter++;
    const now = new Date();
    
    const booking: Booking = {
      ...insertBooking,
      id,
      createdAt: now,
      updatedAt: now
    };
    
    this.bookings.set(id, booking);
    return booking;
  }
  
  async updateBooking(id: number, bookingData: Partial<Booking>): Promise<Booking | undefined> {
    const booking = await this.getBooking(id);
    if (!booking) return undefined;
    
    const updatedBooking = { 
      ...booking, 
      ...bookingData,
      updatedAt: new Date()
    };
    
    this.bookings.set(id, updatedBooking);
    return updatedBooking;
  }
  
  // Message methods
  async getMessage(id: number): Promise<Message | undefined> {
    return this.messages.get(id);
  }
  
  async getMessagesBetweenUsers(userId1: number, userId2: number): Promise<Message[]> {
    return Array.from(this.messages.values()).filter(
      (message) => (
        (message.senderId === userId1 && message.receiverId === userId2) ||
        (message.senderId === userId2 && message.receiverId === userId1)
      )
    ).sort((a, b) => {
      return new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
    });
  }
  
  async createMessage(insertMessage: InsertMessage): Promise<Message> {
    const id = this.messageIdCounter++;
    const now = new Date();
    
    const message: Message = {
      ...insertMessage,
      id,
      read: false,
      createdAt: now
    };
    
    this.messages.set(id, message);
    return message;
  }
  
  async markMessageAsRead(id: number): Promise<Message | undefined> {
    const message = await this.getMessage(id);
    if (!message) return undefined;
    
    const updatedMessage = { ...message, read: true };
    this.messages.set(id, updatedMessage);
    return updatedMessage;
  }
  
  // Review methods
  async getReview(id: number): Promise<Review | undefined> {
    return this.reviews.get(id);
  }
  
  async getReviewsByVendor(vendorId: number): Promise<Review[]> {
    return Array.from(this.reviews.values()).filter(
      (review) => review.vendorId === vendorId
    );
  }
  
  async createReview(insertReview: InsertReview): Promise<Review> {
    const id = this.reviewIdCounter++;
    const now = new Date();
    
    const review: Review = {
      ...insertReview,
      id,
      createdAt: now
    };
    
    this.reviews.set(id, review);
    
    // Update vendor's average rating
    const vendor = await this.getVendor(insertReview.vendorId);
    if (vendor) {
      const reviews = await this.getReviewsByVendor(vendor.id);
      const totalRating = reviews.reduce((sum, r) => sum + r.rating, 0);
      const avgRating = reviews.length > 0 ? totalRating / reviews.length : 0;
      
      await this.updateVendor(vendor.id, {
        rating: avgRating,
        reviewCount: reviews.length
      });
    }
    
    return review;
  }
  
  // Password verification
  async verifyPassword(plaintext: string, hashed: string): Promise<boolean> {
    const [hashedPart, salt] = hashed.split('.');
    const hashedBuf = Buffer.from(hashedPart, 'hex');
    const suppliedBuf = (await scryptAsync(plaintext, salt, 64)) as Buffer;
    return timingSafeEqual(hashedBuf, suppliedBuf);
  }
}

export const storage = new MemStorage();
