import { publicProcedure, router } from "./trpc";
import { sql } from "drizzle-orm";
import { db } from "../db/client";

export const healthRouter = router({
  check: publicProcedure.query(async () => {
    let dbStatus: "connected" | "unreachable" = "unreachable";

    try {
      await db.execute(sql`SELECT 1`);
      dbStatus = "connected";
    } catch {
      dbStatus = "unreachable";
    }

    return {
      status: dbStatus === "connected" ? "healthy" : "degraded",
      uptime: process.uptime(),
      db: dbStatus,
      timestamp: new Date().toISOString(),
    };
  }),
});
