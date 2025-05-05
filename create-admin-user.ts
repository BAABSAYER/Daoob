import { db } from "./server/db";
import { insertUserSchema, users, USER_TYPES } from "./shared/schema";
import { scrypt, randomBytes } from "crypto";
import { promisify } from "util";

const scryptAsync = promisify(scrypt);

async function hashPassword(password: string) {
  const salt = randomBytes(16).toString("hex");
  const buf = (await scryptAsync(password, salt, 64)) as Buffer;
  return `${buf.toString("hex")}.${salt}`;
}

async function main() {
  console.log("Creating admin user...");
  
  try {
    // Check if admin user already exists
    const existingAdmin = await db.query.users.findFirst({
      where: (users, { eq }) => eq(users.username, "admin")
    });
    
    if (existingAdmin) {
      console.log("Admin user already exists.");
      process.exit(0);
    }
    
    // Create admin user
    const adminUser = {
      username: "admin",
      password: await hashPassword("password"),
      email: "admin@example.com",
      fullName: "Admin User",
      userType: USER_TYPES.ADMIN,
      phone: null,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    const result = await db.insert(users).values(adminUser).returning();
    console.log("Admin user created:", result[0]);
    
  } catch (error) {
    console.error("Error creating admin user:", error);
  } finally {
    process.exit(0);
  }
}

main();