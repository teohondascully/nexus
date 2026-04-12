import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import { users } from "./schema";

const connection = postgres(process.env.DATABASE_URL!, { max: 1 });
const db = drizzle(connection);

try {
  // Clear existing users
  await db.delete(users);

  // Insert seed users
  await db.insert(users).values([
    {
      email: "admin@test.com",
      name: "Admin User",
      role: "admin",
    },
    {
      email: "member@test.com",
      name: "Member User",
      role: "member",
    },
  ]);

  console.log("Seed complete.");
} catch (err) {
  console.error("Seed failed:", err);
  process.exit(1);
} finally {
  await connection.end();
}
