import { db } from "./server/db";
import { 
  eventTypes,
  questionnaireItems,
  users,
  USER_TYPES
} from "./shared/schema";
import { eq } from "drizzle-orm";

async function main() {
  console.log("Creating event types...");
  
  // First, let's check if we have an admin user
  const [adminUser] = await db
    .select()
    .from(users)
    .where(eq(users.userType, USER_TYPES.ADMIN));
  
  const adminId = adminUser ? adminUser.id : null;
  
  // Delete existing event types to avoid duplicates
  await db.delete(questionnaireItems);
  await db.delete(eventTypes);
  
  console.log("Creating new event types...");
  
  // Wedding event type
  const [wedding] = await db.insert(eventTypes).values({
    name: "Wedding",
    description: "Full wedding planning and coordination services",
    icon: "💍",
    isActive: true,
    createdBy: adminId,
  }).returning();
  
  // Add questionnaire items for weddings
  await db.insert(questionnaireItems).values([
    {
      eventTypeId: wedding.id,
      questionText: "What's your wedding date?",
      questionType: "date",
      required: true,
      displayOrder: 1,
      createdBy: adminId,
    },
    {
      eventTypeId: wedding.id,
      questionText: "How many guests are you expecting?",
      questionType: "number",
      required: true,
      displayOrder: 2,
      createdBy: adminId,
    },
    {
      eventTypeId: wedding.id,
      questionText: "What's your budget range?",
      questionType: "single_choice",
      options: JSON.stringify(["Under $5,000", "$5,000 - $10,000", "$10,000 - $20,000", "$20,000 - $30,000", "Above $30,000"]),
      required: true,
      displayOrder: 3,
      createdBy: adminId,
    },
    {
      eventTypeId: wedding.id,
      questionText: "Do you need any of these services?",
      questionType: "multiple_choice",
      options: JSON.stringify(["Venue", "Catering", "Photography", "Videography", "Music/DJ", "Decoration", "Wedding Planner", "Cake", "Transportation"]),
      required: true,
      displayOrder: 4,
      createdBy: adminId,
    },
    {
      eventTypeId: wedding.id,
      questionText: "Any special requests or additional information?",
      questionType: "text",
      required: false,
      displayOrder: 5,
      createdBy: adminId,
    },
  ]);
  
  // Corporate event type
  const [corporate] = await db.insert(eventTypes).values({
    name: "Corporate Event",
    description: "Business meetings, conferences, and team-building events",
    icon: "🏢",
    isActive: true,
    createdBy: adminId,
  }).returning();
  
  // Add questionnaire items for corporate events
  await db.insert(questionnaireItems).values([
    {
      eventTypeId: corporate.id,
      questionText: "What's the date of your corporate event?",
      questionType: "date",
      required: true,
      displayOrder: 1,
      createdBy: adminId,
    },
    {
      eventTypeId: corporate.id,
      questionText: "What type of corporate event are you planning?",
      questionType: "single_choice",
      options: JSON.stringify(["Conference", "Team Building", "Product Launch", "Annual Meeting", "Training Session", "Client Appreciation", "Other"]),
      required: true,
      displayOrder: 2,
      createdBy: adminId,
    },
    {
      eventTypeId: corporate.id,
      questionText: "How many attendees are expected?",
      questionType: "number",
      required: true,
      displayOrder: 3,
      createdBy: adminId,
    },
    {
      eventTypeId: corporate.id,
      questionText: "What's your budget range?",
      questionType: "single_choice",
      options: JSON.stringify(["Under $2,000", "$2,000 - $5,000", "$5,000 - $10,000", "$10,000 - $20,000", "Above $20,000"]),
      required: true,
      displayOrder: 4,
      createdBy: adminId,
    },
    {
      eventTypeId: corporate.id,
      questionText: "Which services will you need?",
      questionType: "multiple_choice",
      options: JSON.stringify(["Venue", "Catering", "Audio/Visual Equipment", "Speakers/Entertainment", "Transportation", "Accommodation", "Marketing Materials", "Photography"]),
      required: true,
      displayOrder: 5,
      createdBy: adminId,
    },
  ]);
  
  // Birthday event type
  const [birthday] = await db.insert(eventTypes).values({
    name: "Birthday Party",
    description: "Birthday celebrations for all ages",
    icon: "🎂",
    isActive: true,
    createdBy: adminId,
  }).returning();
  
  // Add questionnaire items for birthdays
  await db.insert(questionnaireItems).values([
    {
      eventTypeId: birthday.id,
      questionText: "What's the date of the birthday party?",
      questionType: "date",
      required: true,
      displayOrder: 1,
      createdBy: adminId,
    },
    {
      eventTypeId: birthday.id,
      questionText: "What is the age of the birthday person?",
      questionType: "number",
      required: true,
      displayOrder: 2,
      createdBy: adminId,
    },
    {
      eventTypeId: birthday.id,
      questionText: "How many guests will attend?",
      questionType: "number",
      required: true,
      displayOrder: 3,
      createdBy: adminId,
    },
    {
      eventTypeId: birthday.id,
      questionText: "What's your budget range?",
      questionType: "single_choice",
      options: JSON.stringify(["Under $500", "$500 - $1,000", "$1,000 - $2,000", "$2,000 - $5,000", "Above $5,000"]),
      required: true,
      displayOrder: 4,
      createdBy: adminId,
    },
    {
      eventTypeId: birthday.id,
      questionText: "Which services do you need?",
      questionType: "multiple_choice",
      options: JSON.stringify(["Venue", "Catering", "Entertainment", "Decoration", "Photography", "Cake", "Party Favors", "Invitations"]),
      required: true,
      displayOrder: 5,
      createdBy: adminId,
    },
  ]);
  
  // Graduation event type
  const [graduation] = await db.insert(eventTypes).values({
    name: "Graduation",
    description: "Graduation ceremonies and celebrations",
    icon: "🎓",
    isActive: true,
    createdBy: adminId,
  }).returning();
  
  // Add questionnaire items for graduation
  await db.insert(questionnaireItems).values([
    {
      eventTypeId: graduation.id,
      questionText: "When is the graduation celebration?",
      questionType: "date",
      required: true,
      displayOrder: 1,
      createdBy: adminId,
    },
    {
      eventTypeId: graduation.id,
      questionText: "What level of graduation is being celebrated?",
      questionType: "single_choice",
      options: JSON.stringify(["High School", "Bachelor's Degree", "Master's Degree", "Doctorate", "Other"]),
      required: true,
      displayOrder: 2,
      createdBy: adminId,
    },
    {
      eventTypeId: graduation.id,
      questionText: "Estimated number of guests?",
      questionType: "number",
      required: true,
      displayOrder: 3,
      createdBy: adminId,
    },
    {
      eventTypeId: graduation.id,
      questionText: "What's your budget range?",
      questionType: "single_choice",
      options: JSON.stringify(["Under $500", "$500 - $1,000", "$1,000 - $2,000", "$2,000 - $5,000", "Above $5,000"]),
      required: true,
      displayOrder: 4,
      createdBy: adminId,
    },
  ]);
  
  // Cultural event type
  const [cultural] = await db.insert(eventTypes).values({
    name: "Cultural Event",
    description: "Cultural celebrations and traditional ceremonies",
    icon: "🎭",
    isActive: true,
    createdBy: adminId,
  }).returning();
  
  // Add questionnaire items for cultural events
  await db.insert(questionnaireItems).values([
    {
      eventTypeId: cultural.id,
      questionText: "When is your cultural event taking place?",
      questionType: "date",
      required: true,
      displayOrder: 1,
      createdBy: adminId,
    },
    {
      eventTypeId: cultural.id,
      questionText: "What type of cultural event are you planning?",
      questionType: "text",
      required: true,
      displayOrder: 2,
      createdBy: adminId,
    },
    {
      eventTypeId: cultural.id,
      questionText: "How many attendees do you expect?",
      questionType: "number",
      required: true,
      displayOrder: 3,
      createdBy: adminId,
    },
    {
      eventTypeId: cultural.id,
      questionText: "What's your budget range?",
      questionType: "single_choice",
      options: JSON.stringify(["Under $1,000", "$1,000 - $3,000", "$3,000 - $5,000", "$5,000 - $10,000", "Above $10,000"]),
      required: true,
      displayOrder: 4,
      createdBy: adminId,
    },
    {
      eventTypeId: cultural.id,
      questionText: "Any special cultural requirements or considerations?",
      questionType: "text",
      required: false,
      displayOrder: 5,
      createdBy: adminId,
    },
  ]);
  
  console.log("Event types created successfully!");
  console.log(`Created ${5} event types with their respective questionnaire items.`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Error creating event types:", err);
    process.exit(1);
  });