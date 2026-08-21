import { prisma } from "@/lib/prisma";

export async function checkRateLimit(
  key: string,
  limit: number,
  windowMs: number,
): Promise<{ allowed: boolean; retryAfterSeconds?: number }> {
  const now = new Date();
  const resetAt = new Date(now.getTime() + windowMs);

  const existing = await prisma.rateLimitEntry.findUnique({
    where: { key },
  });

  if (!existing || existing.resetAt <= now) {
    await prisma.rateLimitEntry.upsert({
      where: { key },
      create: {
        key,
        count: 1,
        resetAt,
      },
      update: {
        count: 1,
        resetAt,
      },
    });

    return { allowed: true };
  }

  if (existing.count >= limit) {
    const retryAfterSeconds = Math.ceil(
      (existing.resetAt.getTime() - now.getTime()) / 1000,
    );

    return {
      allowed: false,
      retryAfterSeconds: Math.max(retryAfterSeconds, 1),
    };
  }

  await prisma.rateLimitEntry.update({
    where: { key },
    data: {
      count: existing.count + 1,
    },
  });

  return { allowed: true };
}

export async function cleanupExpiredRateLimits() {
  await prisma.rateLimitEntry.deleteMany({
    where: {
      resetAt: {
        lt: new Date(),
      },
    },
  });
}
