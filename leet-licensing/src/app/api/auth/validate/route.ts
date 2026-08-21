import { LicenseStatus } from "@prisma/client";

import { writeAuditLog } from "@/lib/audit";
import { errorResponse, getClientIp, jsonResponse } from "@/lib/http";
import { registerGameFromRequest } from "@/lib/game-service";
import {
  findValidLoaderSession,
  markExpiredLicenses,
  resolveLicenseStatus,
  verifyHwidForLicense,
} from "@/lib/license-service";
import { checkRateLimit } from "@/lib/rate-limit";
import { validateSchema } from "@/lib/validation";

export async function POST(request: Request) {
  const ip = await getClientIp();

  let body: unknown;

  try {
    body = await request.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const parsed = validateSchema.safeParse(body);

  if (!parsed.success) {
    return errorResponse(parsed.error.issues[0]?.message ?? "Invalid request", 400);
  }

  const { sessionToken, hwid } = parsed.data;

  await registerGameFromRequest(parsed.data);

  const rateLimit = await checkRateLimit(
    `validate:${sessionToken.slice(0, 16)}`,
    120,
    60 * 1000,
  );

  if (!rateLimit.allowed) {
    return errorResponse("Rate limit exceeded", 429);
  }

  await markExpiredLicenses();

  const session = await findValidLoaderSession(sessionToken);

  if (!session) {
    return errorResponse("Invalid or expired session", 401);
  }

  const status = await resolveLicenseStatus(session.license);

  if (status !== LicenseStatus.ACTIVATED) {
    await writeAuditLog({
      licenseId: session.licenseId,
      event: "validate.inactive_license",
      ip,
      metadata: { status },
    });

    return jsonResponse({
      valid: false,
      licenseStatus: status,
    });
  }

  const hwidMatches = await verifyHwidForLicense(session.licenseId, hwid);

  if (!hwidMatches) {
    await writeAuditLog({
      licenseId: session.licenseId,
      event: "validate.hwid_mismatch",
      ip,
    });

    return jsonResponse({
      valid: false,
      licenseStatus: status,
      reason: "hwid_mismatch",
    });
  }

  return jsonResponse({
    valid: true,
    licenseStatus: status,
    expiresAt: session.expiresAt.toISOString(),
    sessionId: session.id,
  });
}
