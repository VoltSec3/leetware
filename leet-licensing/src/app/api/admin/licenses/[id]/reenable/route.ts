import { LicenseStatus } from "@prisma/client";

import { requireRole, requireCsrf } from "@/lib/admin-auth";
import { writeAuditLog } from "@/lib/audit";
import { errorResponse, getClientIp, jsonResponse } from "@/lib/http";
import { isLicenseExpired } from "@/lib/license-service";
import { prisma } from "@/lib/prisma";

type RouteContext = {
  params: Promise<{ id: string }>;
};

export async function POST(request: Request, context: RouteContext) {
  try {
    await requireRole(["ADMIN"]);
    await requireCsrf(request);
  } catch (error) {
    const message = error instanceof Error ? error.message : "UNAUTHORIZED";
    return errorResponse(
      message === "CSRF_INVALID" ? "Invalid CSRF token" : "Unauthorized",
      message === "CSRF_INVALID" ? 403 : 401,
    );
  }

  const { id } = await context.params;
  const ip = await getClientIp();

  const license = await prisma.license.findUnique({
    where: { id },
    include: { activation: true },
  });

  if (!license) {
    return errorResponse("License not found", 404);
  }

  if (license.status !== LicenseStatus.REVOKED) {
    return errorResponse("Only revoked licenses can be re-enabled", 400);
  }

  if (isLicenseExpired(license.expiresAt)) {
    return errorResponse("License is expired and cannot be re-enabled", 400);
  }

  const nextStatus = license.userId
    ? LicenseStatus.ACTIVATED
    : LicenseStatus.UNUSED;

  await prisma.license.update({
    where: { id },
    data: { status: nextStatus },
  });

  await writeAuditLog({
    licenseId: id,
    event: "admin.license_reenabled",
    ip,
    metadata: { status: nextStatus },
  });

  return jsonResponse({ success: true, status: nextStatus });
}
