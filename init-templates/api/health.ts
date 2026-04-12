import { publicProcedure, router } from "../trpc";

export const healthRouter = router({
  check: publicProcedure.query(async () => {
    let dbStatus: "connected" | "unreachable" = "unreachable";

    try {
      const pg = await import("postgres");
      const sql = pg.default(process.env.DATABASE_URL!);
      await sql`SELECT 1`;
      await sql.end();
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
