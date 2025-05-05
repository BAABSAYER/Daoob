import { db } from "./server/db";
import { 
  insertUserSchema, 
  InsertVendor, 
  InsertService, 
  InsertBooking,
  users, 
  vendors, 
  services, 
  bookings,
  USER_TYPES, 
  SERVICE_CATEGORIES,
  EVENT_TYPES,
  BOOKING_STATUS
} from "./shared/schema";
import { count } from "drizzle-orm";
import { scrypt, randomBytes } from "crypto";
import { promisify } from "util";

const scryptAsync = promisify(scrypt);

async function hashPassword(password: string) {
  const salt = randomBytes(16).toString("hex");
  const buf = (await scryptAsync(password, salt, 64)) as Buffer;
  return `${buf.toString("hex")}.${salt}`;
}

async function main() {
  console.log("Creating demo data...");
  
  try {
    // Create demo users if they don't exist
    const demoClientUser = await db.query.users.findFirst({
      where: (users, { eq }) => eq(users.username, "demouser")
    });
    
    if (!demoClientUser) {
      console.log("Creating demo client user...");
      const clientUser = await db.insert(users).values({
        username: "demouser",
        password: await hashPassword("password"),
        email: "client@example.com",
        fullName: "Demo Client",
        userType: USER_TYPES.CLIENT,
        phone: "+1234567890",
        createdAt: new Date(),
        updatedAt: new Date()
      }).returning();
      console.log("Created demo client user:", clientUser[0].id);
    }
    
    const demoVendorUser = await db.query.users.findFirst({
      where: (users, { eq }) => eq(users.username, "demovendor")
    });
    
    if (!demoVendorUser) {
      console.log("Creating demo vendor user...");
      const vendorUser = await db.insert(users).values({
        username: "demovendor",
        password: await hashPassword("password"),
        email: "vendor@example.com",
        fullName: "Demo Vendor",
        userType: USER_TYPES.VENDOR,
        phone: "+1987654321",
        createdAt: new Date(),
        updatedAt: new Date()
      }).returning();
      console.log("Created demo vendor user:", vendorUser[0].id);
      
      // Create vendor profile for the vendor user
      const vendorData: InsertVendor = {
        userId: vendorUser[0].id,
        businessName: "Demo Event Services",
        category: "catering",
        description: "We provide top-notch catering services for all types of events.",
        address: "123 Main St",
        city: "New York",
        priceRange: "moderate",
        capacity: 500,
        amenities: ["Customized menus", "Professional staff", "Setup and cleanup"],
        features: ["Vegetarian options", "Halal options", "Kosher options"],
        photos: []
      };
      
      const vendor = await db.insert(vendors).values(vendorData).returning();
      console.log("Created demo vendor profile:", vendor[0].id);
      
      // Create some services for the vendor
      const serviceData1 = {
        vendorId: vendor[0].id,
        name: "Basic Catering Package",
        description: "Basic catering service for small events",
        price: 1000,
        duration: 4,
        capacity: 50,
        availability: ["weekdays", "weekends"],
        category: "catering",
        features: ["Setup", "Cleanup", "Staff"]
      };
      
      const serviceData2 = {
        vendorId: vendor[0].id,
        name: "Premium Catering Package",
        description: "Premium catering service for medium to large events",
        price: 2500,
        duration: 6,
        capacity: 200,
        availability: ["weekends"],
        category: "catering",
        features: ["Setup", "Cleanup", "Staff", "Custom menu", "Bar service"]
      };
      
      await db.insert(services).values(serviceData1);
      await db.insert(services).values(serviceData2);
      console.log("Created demo services");
    }
    
    // Check if admin exists and get ID
    const adminUser = await db.query.users.findFirst({
      where: (users, { eq }) => eq(users.username, "admin")
    });
    
    if (!adminUser) {
      console.log("Admin user not found, please run create-admin-user.ts first");
      process.exit(1);
    }
    
    // Get client user and vendor for bookings
    const clientUser = await db.query.users.findFirst({
      where: (users, { eq }) => eq(users.username, "demouser")
    });
    
    const vendorProfile = await db.query.vendors.findFirst({
      with: {
        user: {
          where: (users, { eq }) => eq(users.username, "demovendor")
        }
      }
    });
    
    if (!clientUser || !vendorProfile) {
      console.log("Demo users not created properly");
      process.exit(1);
    }
    
    // Create demo bookings if they don't exist
    const existingBookingsCount = await db.select({ count: count() }).from(bookings);
    
    if (existingBookingsCount[0].count === 0) {
      console.log("Creating demo bookings...");
      
      // Create various bookings with different statuses
      const bookingData1: InsertBooking = {
        clientId: clientUser.id,
        vendorId: vendorProfile.id,
        eventType: "wedding",
        eventDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
        guestCount: 150,
        specialRequests: "Need vegetarian options for 50 guests",
        totalPrice: 5000,
        status: BOOKING_STATUS.PENDING
      };
      
      const bookingData2: InsertBooking = {
        clientId: clientUser.id,
        vendorId: vendorProfile.id,
        eventType: "corporate",
        eventDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // 14 days from now
        guestCount: 50,
        specialRequests: "Business meeting setup",
        totalPrice: 2000,
        status: BOOKING_STATUS.CONFIRMED
      };
      
      const bookingData3: InsertBooking = {
        clientId: clientUser.id,
        vendorId: vendorProfile.id,
        eventType: "birthday",
        eventDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 7 days ago
        guestCount: 30,
        specialRequests: "Birthday cake needed",
        totalPrice: 1200,
        status: BOOKING_STATUS.COMPLETED
      };
      
      const bookingData4: InsertBooking = {
        clientId: clientUser.id,
        vendorId: vendorProfile.id,
        eventType: "other",
        eventDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3 days from now
        guestCount: 25,
        specialRequests: "Family gathering",
        totalPrice: 800,
        status: BOOKING_STATUS.CANCELLED
      };
      
      await db.insert(bookings).values(bookingData1);
      await db.insert(bookings).values(bookingData2);
      await db.insert(bookings).values(bookingData3);
      await db.insert(bookings).values(bookingData4);
      
      console.log("Created 4 demo bookings");
    } else {
      console.log(`${existingBookingsCount[0].count} bookings already exist, skipping creation`);
    }
    
    console.log("Demo data creation complete!");
    
  } catch (error) {
    console.error("Error creating demo data:", error);
  } finally {
    process.exit(0);
  }
}

main();