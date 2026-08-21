import { cookies } from "next/headers";

import { writeAuditLog } from "@/lib/audit";
import {
  ADMIN_SESSION_COOKIE,
  CSRF_COOKIE,
  adminCookieOptions,
  createAdminSession,
  createCsrfToken,
  csrfCookieOptions,
  signCsrfToken,
  verifyAdminCredentials,
} from "@/lib/admin-auth";
import { errorResponse, getClientIp, jsonResponse } from "@/lib/http";
import { checkRateLimit } from "@/lib/rate-limit";
import { loginSchema } from "@/lib/validation";

export async function POST(request: Request) {
  const ip = await getClientIp();
  const rateLimit = await checkRateLimit(
    `admin-login:${ip ?? "unknown"}`,
    10,
    15 * 60 * 1000,
  );

  if (!rateLimit.allowed) {
    return errorResponse("Too many login attempts", 429);
  }

  let body: unknown;

  try {
    body = await request.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const parsed = loginSchema.safeParse(body);

  if (!parsed.success) {
    return errorResponse(parsed.error.issues[0]?.message ?? "Invalid request", 400);
  }

  const admin = await verifyAdminCredentials(
    parsed.data.email,
    parsed.data.password,
  );

  if (!admin) {
    await writeAuditLog({
      event: "admin.login_failed",
      ip,
      metadata: { email: parsed.data.email },
    });

    return errorResponse("Invalid credentials", 401);
  }

  const session = await createAdminSession(admin.id);
  const csrfToken = createCsrfToken();
  const cookieStore = await cookies();

  cookieStore.set(
    ADMIN_SESSION_COOKIE,
    session.token,
    adminCookieOptions(session.expiresAt),
  );
  cookieStore.set(CSRF_COOKIE, signCsrfToken(csrfToken), csrfCookieOptions());

  await writeAuditLog({
    event: "admin.login_success",
    ip,
    metadata: { adminId: admin.id },
  });

  return jsonResponse({
    email: admin.email,
    csrfToken,
  });
}
