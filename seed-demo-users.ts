import { db } from "./server/db";
import { users, vendors, services } from "./shared/schema";
import { scrypt, randomBytes } from "crypto";
import { promisify } from "util";

const scryptAsync = promisify(scrypt);

async function hashPassword(password: string) {
  const salt = randomBytes(16).toString("hex");
  const buf = (await scryptAsync(password, salt, 64)) as Buffer;
  return `${buf.toString("hex")}.${salt}`;
}

async function main() {
  try {
    console.log("Creating demo users...");
    
    // Create demo client user
    const hashedClientPassword = await hashPassword("password");
    const [clientUser] = await db.insert(users).values({
      username: "demouser",
      password: hashedClientPassword,
      email: "demo@example.com",
      fullName: "Demo User",
      userType: "client",
    }).returning();
    
    console.log("Created client user:", clientUser.id);
    
    // Create demo vendor user
    const hashedVendorPassword = await hashPassword("password");
    const [vendorUser] = await db.insert(users).values({
      username: "demovendor",
      password: hashedVendorPassword,
      email: "vendor@example.com",
      fullName: "Demo Vendor",
      userType: "vendor",
    }).returning();
    
    console.log("Created vendor user:", vendorUser.id);
    
    // Create vendor profile
    const [vendorProfile] = await db.insert(vendors).values({
      userId: vendorUser.id,
      businessName: "Demo Event Services",
      category: "venue",
      description: "A beautiful venue for all your events",
      city: "New York",
      priceRange: "$$$",
    }).returning();
    
    console.log("Created vendor profile:", vendorProfile.id);
    
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