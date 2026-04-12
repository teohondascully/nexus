import { initTRPC, TRPCError } from "@trpc/server";
import { auth } from "@clerk/nextjs/server";

export async function createTRPCContext() {
  const { userId } = await auth();
  return { userId };
}

type Context = Awaited<ReturnType<typeof createTRPCContext>>;

const t = initTRPC.context<Context>().create();

export const router = t.router;

export const publicProcedure = t.procedure;

export const protectedProcedure = t.procedure.use(({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: "UNAUTHORIZED" });
  }
  return next({ ctx: { ...ctx, userId: ctx.userId } });
});
