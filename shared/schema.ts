import { pgTable, text, serial, integer, boolean, timestamp, doublePrecision, jsonb, varchar } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";
import { relations } from "drizzle-orm";

// Enum-like constants
export const USER_TYPES = {
  CLIENT: 'client',
  VENDOR: 'vendor',
  ADMIN: 'admin',
} as const;

export const SERVICE_CATEGORIES = {
  VENUE: 'venue',
  CATERING: 'catering',
  PHOTOGRAPHY: 'photography',
  DECORATION: 'decoration',
  ENTERTAINMENT: 'entertainment',
  OTHER: 'other',
} as const;

export const EVENT_TYPES = {
  WEDDING: 'wedding',
  CORPORATE: 'corporate',
  BIRTHDAY: 'birthday',
  GRADUATION: 'graduation',
  SOCIAL: 'social',
  OTHER: 'other',
} as const;

export const BOOKING_STATUS = {
  PENDING: 'pending',
  CONFIRMED: 'confirmed',
  CANCELLED: 'cancelled',
  COMPLETED: 'completed',
} as const;

export const ADMIN_PERMISSIONS = {
  MANAGE_USERS: 'manage_users',
  MANAGE_VENDORS: 'manage_vendors',
  MANAGE_BOOKINGS: 'manage_bookings',
  MANAGE_ADMINS: 'manage_admins',
  VIEW_ANALYTICS: 'view_analytics',
  MANAGE_SETTINGS: 'manage_settings',
} as const;

// Users table
export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
  email: text("email").notNull().unique(),
  fullName: text("full_name"),
  phone: text("phone"),
  userType: text("user_type").notNull(),
  avatarUrl: text("avatar_url"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Vendors table
export const vendors = pgTable("vendors", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull().references(() => users.id),
  businessName: text("business_name").notNull(),
  category: text("category").notNull(),
  description: text("description"),
  address: text("address"),
  city: text("city"),
  priceRange: text("price_range"),
  rating: doublePrecision("rating"),
  reviewCount: integer("review_count").default(0),
  capacity: integer("capacity"),
  amenities: jsonb("amenities"),
  features: jsonb("features"),
  photos: jsonb("photos"),
});

// Services table
export const services = pgTable("services", {
  id: serial("id").primaryKey(),
  vendorId: integer("vendor_id").notNull().references(() => vendors.id),
  name: text("name").notNull(),
  description: text("description"),
  price: doublePrecision("price"),
  duration: integer("duration"),
  isPackage: boolean("is_package").default(false),
});

// Bookings table
export const bookings = pgTable("bookings", {
  id: serial("id").primaryKey(),
  clientId: integer("client_id").notNull().references(() => users.id),
  vendorId: integer("vendor_id").notNull().references(() => vendors.id),
  serviceId: integer("service_id").references(() => services.id),
  status: text("status").notNull().default(BOOKING_STATUS.PENDING),
  eventType: text("event_type").notNull(),
  eventDate: timestamp("event_date").notNull(),
  guestCount: integer("guest_count"),
  specialRequests: text("special_requests"),
  totalPrice: doublePrecision("total_price"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Messages table
export const messages = pgTable("messages", {
  id: serial("id").primaryKey(),
  senderId: integer("sender_id").notNull().references(() => users.id),
  receiverId: integer("receiver_id").notNull().references(() => users.id),
  content: text("content").notNull(),
  read: boolean("read").default(false),
  createdAt: timestamp("created_at").defaultNow(),
});

// Reviews table
export const reviews = pgTable("reviews", {
  id: serial("id").primaryKey(),
  clientId: integer("client_id").notNull().references(() => users.id),
  vendorId: integer("vendor_id").notNull().references(() => vendors.id),
  bookingId: integer("booking_id").references(() => bookings.id),
  rating: integer("rating").notNull(),
  comment: text("comment"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Admin Permissions table
export const adminPermissions = pgTable("admin_permissions", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull().references(() => users.id),
  permission: text("permission").notNull(),
  granted: boolean("granted").default(true),
  grantedBy: integer("granted_by").references(() => users.id),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Zod schemas for validation
export const insertUserSchema = createInsertSchema(users).pick({
  username: true,
  password: true,
  email: true,
  fullName: true,
  phone: true,
  userType: true,
  avatarUrl: true,
});

export const insertVendorSchema = createInsertSchema(vendors).pick({
  userId: true,
  businessName: true,
  category: true,
  description: true,
  address: true,
  city: true,
  priceRange: true,
  capacity: true,
  amenities: true,
  features: true,
  photos: true,
});

export const insertServiceSchema = createInsertSchema(services);
export const insertBookingSchema = createInsertSchema(bookings);
export const insertMessageSchema = createInsertSchema(messages);
export const insertReviewSchema = createInsertSchema(reviews);
export const insertAdminPermissionSchema = createInsertSchema(adminPermissions);

// Relation definitions
export const usersRelations = relations(users, ({ many, one }) => ({
  vendor: one(vendors, { fields: [users.id], references: [vendors.userId] }),
  sentMessages: many(messages, { relationName: "sender" }),
  receivedMessages: many(messages, { relationName: "receiver" }),
  clientBookings: many(bookings, { relationName: "client" }),
  reviews: many(reviews, { relationName: "client" }),
  permissions: many(adminPermissions, { relationName: "user_permissions" }),
  grantedPermissions: many(adminPermissions, { relationName: "grantor" })
}));

export const vendorsRelations = relations(vendors, ({ one, many }) => ({
  user: one(users, { fields: [vendors.userId], references: [users.id] }),
  services: many(services),
  bookings: many(bookings),
  reviews: many(reviews)
}));

export const servicesRelations = relations(services, ({ one, many }) => ({
  vendor: one(vendors, { fields: [services.vendorId], references: [vendors.id] }),
  bookings: many(bookings)
}));

export const bookingsRelations = relations(bookings, ({ one, many }) => ({
  client: one(users, { fields: [bookings.clientId], references: [users.id] }),
  vendor: one(vendors, { fields: [bookings.vendorId], references: [vendors.id] }),
  service: one(services, { fields: [bookings.serviceId], references: [services.id] }),
  reviews: many(reviews)
}));

export const messagesRelations = relations(messages, ({ one }) => ({
  sender: one(users, { fields: [messages.senderId], references: [users.id], relationName: "sender" }),
  receiver: one(users, { fields: [messages.receiverId], references: [users.id], relationName: "receiver" })
}));

export const reviewsRelations = relations(reviews, ({ one }) => ({
  client: one(users, { fields: [reviews.clientId], references: [users.id], relationName: "client" }),
  vendor: one(vendors, { fields: [reviews.vendorId], references: [vendors.id] }),
  booking: one(bookings, { fields: [reviews.bookingId], references: [bookings.id] })
}));

// Type exports
export type User = typeof users.$inferSelect;
export type InsertUser = z.infer<typeof insertUserSchema>;

export type Vendor = typeof vendors.$inferSelect;
export type InsertVendor = z.infer<typeof insertVendorSchema>;

export type Service = typeof services.$inferSelect;
export type InsertService = z.infer<typeof insertServiceSchema>;

export type Booking = typeof bookings.$inferSelect;
export type InsertBooking = z.infer<typeof insertBookingSchema>;

export type Message = typeof messages.$inferSelect;
export type InsertMessage = z.infer<typeof insertMessageSchema>;

export type Review = typeof reviews.$inferSelect;
export type InsertReview = z.infer<typeof insertReviewSchema>;

export type AdminPermission = typeof adminPermissions.$inferSelect;
export type InsertAdminPermission = z.infer<typeof insertAdminPermissionSchema>;
