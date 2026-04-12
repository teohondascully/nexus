import {
  pgTable,
  uuid,
  timestamp,
  text,
} from "drizzle-orm/pg-core";

const baseColumns = {
  id: uuid("id").defaultRandom().primaryKey(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
  deletedAt: timestamp("deleted_at", { withTimezone: true }),
};

export const users = pgTable("users", {
  ...baseColumns,
  email: text("email").unique().notNull(),
  name: text("name"),
  role: text("role").default("member"),
});
