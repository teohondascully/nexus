import { auth, currentUser } from "@clerk/nextjs/server";

export async function requireAuth() {
  const session = await auth();
  if (!session.userId) {
    throw new Error("Unauthorized");
  }
  return session;
}

export async function getCurrentUser() {
  const user = await currentUser();
  if (!user) return null;
  return {
    id: user.id,
    email: user.emailAddresses[0]?.emailAddress ?? null,
    name: user.fullName,
    imageUrl: user.imageUrl,
  };
}
