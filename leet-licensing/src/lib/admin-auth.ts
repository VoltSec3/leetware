import { cookies } from "next/headers";
import bcrypt from "bcryptjs";
import { createHmac, randomBytes, timingSafeEqual } from "crypto";

import { generateSessionToken, hashToken } from "@/lib/crypto";
import { env } from "@/lib/env";
import { prisma } from "@/lib/prisma";

export const ADMIN_SESSION_COOKIE = "leet_admin_session";
export const CSRF_COOKIE = "leet_csrf";

export async function createAdminUser(
  email: string,
  password: string,
  role: string = "ADMIN",
) {
  const passwordHash = await bcrypt.hash(password, 12);

  return prisma.adminUser.create({
    data: {
      email: email.toLowerCase(),
      passwordHash,
      role,
    },
  });
}

export async function verifyAdminCredentials(email: string, password: string) {
  const admin = await prisma.adminUser.findUnique({
    where: { email: email.toLowerCase() },
  });

  if (!admin) {
    return null;
  }

  const valid = await bcrypt.compare(password, admin.passwordHash);

  if (!valid) {
    return null;
  }

  return admin;
}

export async function createAdminSession(adminId: string) {
  const token = generateSessionToken();
  const tokenHash = hashToken(token);
  const expiresAt = new Date(
    Date.now() + env.adminSessionTtlHours * 60 * 60 * 1000,
  );

  await prisma.adminSession.create({
    data: {
      adminId,
      tokenHash,
      expiresAt,
    },
  });

  return { token, expiresAt };
}

export async function getAdminFromSessionToken(token: string) {
  const tokenHash = hashToken(token);

  const session = await prisma.adminSession.findFirst({
    where: {
      tokenHash,
      expiresAt: { gt: new Date() },
    },
    include: {
      admin: true,
    },
  });

  return session?.admin ?? null;
}

export async function getAuthenticatedAdmin() {
  const cookieStore = await cookies();
  const token = cookieStore.get(ADMIN_SESSION_COOKIE)?.value;

  if (!token) {
    return null;
  }

  return getAdminFromSessionToken(token);
}

export async function destroyAdminSession(token: string) {
  const tokenHash = hashToken(token);

  await prisma.adminSession.deleteMany({
    where: { tokenHash },
  });
}

export function createCsrfToken(): string {
  return randomBytes(32).toString("base64url");
}

export function signCsrfToken(token: string): string {
  const signature = createHmac("sha256", env.csrfSecret)
    .update(token)
    .digest("base64url");

  return `${token}.${signature}`;
}

export function verifyCsrfToken(signedToken: string): boolean {
  const [token, signature] = signedToken.split(".");

  if (!token || !signature) {
    return false;
  }

  const expected = createHmac("sha256", env.csrfSecret)
    .update(token)
    .digest("base64url");

  const left = Buffer.from(signature);
  const right = Buffer.from(expected);

  if (left.length !== right.length) {
    return false;
  }

  return timingSafeEqual(left, right);
}

export async function requireAdmin() {
  const admin = await getAuthenticatedAdmin();

  if (!admin) {
    throw new Error("UNAUTHORIZED");
  }

  return admin;
}

export async function requireRole(roles: string[]) {
  const admin = await getAuthenticatedAdmin();

  if (!admin) {
    throw new Error("UNAUTHORIZED");
  }

  if (!roles.includes(admin.role)) {
    throw new Error("FORBIDDEN");
  }

  return admin;
}

export async function requireCsrf(request: Request) {
  const cookieStore = await cookies();
  const cookieToken = cookieStore.get(CSRF_COOKIE)?.value;
  const headerToken = request.headers.get("x-csrf-token");

  if (!cookieToken || !headerToken) {
    throw new Error("CSRF_INVALID");
  }

  if (!verifyCsrfToken(cookieToken) || !verifyCsrfToken(headerToken)) {
    throw new Error("CSRF_INVALID");
  }

  const cookieValue = cookieToken.split(".")[0];
  const headerValue = headerToken.split(".")[0];

  if (!cookieValue || !headerValue || cookieValue !== headerValue) {
    throw new Error("CSRF_INVALID");
  }
}

export function adminCookieOptions(expiresAt: Date) {
  return {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict" as const,
    path: "/",
    expires: expiresAt,
  };
}

export function csrfCookieOptions() {
  return {
    httpOnly: false,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict" as const,
    path: "/",
  };
}
