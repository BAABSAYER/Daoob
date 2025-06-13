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
  QUOTATION_SENT: 'quotation_sent',
  QUOTATION_ACCEPTED: 'quotation_accepted',
  QUOTATION_REJECTED: 'quotation_rejected',
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

// Bookings table (main flow - replaces event requests)
export const bookings = pgTable("bookings", {
  id: serial("id").primaryKey(),
  clientId: integer("client_id").notNull().references(() => users.id),
  eventTypeId: integer("event_type_id").references(() => eventTypes.id),
  vendorId: integer("vendor_id").references(() => vendors.id),
  serviceId: integer("service_id").references(() => services.id),
  status: text("status").notNull().default(BOOKING_STATUS.PENDING),
  eventType: text("event_type"), // Legacy field
  eventDate: timestamp("event_date").notNull(),
  eventTime: text("event_time"),
  location: text("location"),
  estimatedGuests: integer("estimated_guests"),
  guestCount: integer("guest_count"),
  budget: doublePrecision("budget"),
  specialRequests: text("special_requests"),
  questionnaireResponses: jsonb("questionnaire_responses"),
  notes: text("notes"),
  totalPrice: doublePrecision("total_price"),
  quotationDetails: jsonb("quotation_details"),
  quotationNotes: text("quotation_notes"),
  quotationValidUntil: timestamp("quotation_valid_until"),
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

// Event Types table (managed by admin)
export const eventTypes = pgTable("event_types", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  description: text("description"),
  icon: text("icon"),
  isActive: boolean("is_active").default(true),
  createdBy: integer("created_by").references(() => users.id),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Questionnaire table (questions for each event type)
export const questionnaireItems = pgTable("questionnaire_items", {
  id: serial("id").primaryKey(),
  eventTypeId: integer("event_type_id").notNull().references(() => eventTypes.id),
  questionText: text("question_text").notNull(),
  questionType: text("question_type").notNull(), // text, textarea, single_choice, multiple_choice, checkbox, number, date
  options: jsonb("options"), // For choice questions, array of options
  required: boolean("required").default(false),
  displayOrder: integer("display_order"),
  createdBy: integer("created_by").references(() => users.id),
  createdAt: timestamp("created_at").defaultNow(),
});

// Removed event requests and quotations tables - now using enhanced bookings table

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

// Event management schemas
export const insertEventTypeSchema = createInsertSchema(eventTypes);
export const insertQuestionnaireItemSchema = createInsertSchema(questionnaireItems);

// Relation definitions
export const usersRelations = relations(users, ({ many, one }) => ({
  vendor: one(vendors, { fields: [users.id], references: [vendors.userId] }),
  sentMessages: many(messages, { relationName: "sender" }),
  receivedMessages: many(messages, { relationName: "receiver" }),
  clientBookings: many(bookings, { relationName: "client" }),
  reviews: many(reviews, { relationName: "client" }),
  permissions: many(adminPermissions, { relationName: "user_permissions" }),
  grantedPermissions: many(adminPermissions, { relationName: "grantor" }),
  createdEventTypes: many(eventTypes),
  createdQuestionnaireItems: many(questionnaireItems),
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
  eventType: one(eventTypes, { fields: [bookings.eventTypeId], references: [eventTypes.id] }),
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

// Event management relations
export const eventTypesRelations = relations(eventTypes, ({ one, many }) => ({
  creator: one(users, { fields: [eventTypes.createdBy], references: [users.id] }),
  questionnaireItems: many(questionnaireItems),
  bookings: many(bookings)
}));

export const questionnaireItemsRelations = relations(questionnaireItems, ({ one }) => ({
  eventType: one(eventTypes, { fields: [questionnaireItems.eventTypeId], references: [eventTypes.id] }),
  creator: one(users, { fields: [questionnaireItems.createdBy], references: [users.id] })
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

// New type exports for the event flow
export type EventType = typeof eventTypes.$inferSelect;
export type InsertEventType = z.infer<typeof insertEventTypeSchema>;

export type QuestionnaireItem = typeof questionnaireItems.$inferSelect;
export type InsertQuestionnaireItem = z.infer<typeof insertQuestionnaireItemSchema>;

// Removed EventRequest and Quotation types - functionality moved to enhanced bookings table
