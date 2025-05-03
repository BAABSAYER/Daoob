import { db } from "./server/db";
import { users, vendors, services } from "./shared/schema";
import { scrypt, randomBytes } from "crypto";
import { promisify } from "util";
import { eq } from "drizzle-orm";

const scryptAsync = promisify(scrypt);

async function hashPassword(password: string) {
  const salt = randomBytes(16).toString("hex");
  const buf = (await scryptAsync(password, salt, 64)) as Buffer;
  return `${buf.toString("hex")}.${salt}`;
}

async function main() {
  try {
    console.log("Creating demo users...");
    
    // Check if admin user already exists
    const existingAdmin = await db.select().from(users).where(eq(users.username, "admin")).limit(1);
    
    if (existingAdmin.length === 0) {
      // Create demo admin user since it doesn't exist
      const hashedAdminPassword = await hashPassword("password");
      const [adminUser] = await db.insert(users).values({
        username: "admin",
        password: hashedAdminPassword,
        email: "admin@example.com",
        fullName: "Admin User",
        userType: "admin",
      }).returning();
      
      console.log("Created admin user:", adminUser.id);
    } else {
      console.log("Admin user already exists");
    }
    
    // Check if client user already exists
    const existingClient = await db.select().from(users).where(eq(users.username, "demouser")).limit(1);
    
    let clientUser;
    if (existingClient.length === 0) {
      // Create demo client user
      const hashedClientPassword = await hashPassword("password");
      [clientUser] = await db.insert(users).values({
        username: "demouser",
        password: hashedClientPassword,
        email: "demo@example.com",
        fullName: "Demo User",
        userType: "client",
      }).returning();
      
      console.log("Created client user:", clientUser.id);
    } else {
      console.log("Client user already exists");
      clientUser = existingClient[0];
    }
    
    // Check if vendor user already exists
    const existingVendor = await db.select().from(users).where(eq(users.username, "demovendor")).limit(1);
    
    let vendorUser;
    if (existingVendor.length === 0) {
      // Create demo vendor user
      const hashedVendorPassword = await hashPassword("password");
      [vendorUser] = await db.insert(users).values({
        username: "demovendor",
        password: hashedVendorPassword,
        email: "vendor@example.com",
        fullName: "Demo Vendor",
        userType: "vendor",
      }).returning();
      
      console.log("Created vendor user:", vendorUser.id);
    } else {
      console.log("Vendor user already exists");
      vendorUser = existingVendor[0];
    }
    
    // Check if vendor profile already exists
    const existingVendorProfile = await db.select().from(vendors).where(eq(vendors.userId, vendorUser.id)).limit(1);
    
    let vendorProfile;
    if (existingVendorProfile.length === 0) {
      // Create vendor profile
      [vendorProfile] = await db.insert(vendors).values({
        userId: vendorUser.id,
        businessName: "Demo Event Services",
        category: "venue",
        description: "A beautiful venue for all your events",
        city: "New York",
        priceRange: "$$$",
      }).returning();
      
      console.log("Created vendor profile:", vendorProfile.id);
    } else {
      console.log("Vendor profile already exists");
      vendorProfile = existingVendorProfile[0];
    }
    
    // Create services for the vendor
    await db.insert(services).values([
      {
        vendorId: vendorProfile.id,
        name: "Standard Venue Rental",
        description: "Basic venue rental for up to 100 guests",
        price: 2500.00,
        duration: 240,
      },
      {
        vendorId: vendorProfile.id,
        name: "Premium Venue Package",
        description: "Full-service venue rental with catering and decoration",
        price: 5000.00,
        duration: 360,
      },
      {
        vendorId: vendorProfile.id,
        name: "Corporate Meeting Space",
        description: "Professional space for corporate events and meetings",
        price: 1200.00,
        duration: 180,
      }
    ]);
    
    console.log("Created vendor services");
    console.log("Demo users created successfully");
  } catch (error) {
    console.error("Error creating demo users:", error);
  } finally {
    process.exit(0);
  }
}

main();