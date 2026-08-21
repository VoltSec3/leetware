import { LicenseStatus } from "@prisma/client";

import { requireAdmin, requireCsrf } from "@/lib/admin-auth";
import { writeAuditLog } from "@/lib/audit";
import { errorResponse, getClientIp, jsonResponse } from "@/lib/http";
import { revokeLicenseSessions } from "@/lib/license-service";
import { prisma } from "@/lib/prisma";

type RouteContext = {
  params: Promise<{ id: string }>;
};

export async function POST(request: Request, context: RouteContext) {
  try {
    await requireAdmin();
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

  const license = await prisma.license.findUnique({ where: { id } });

  if (!license) {
    return errorResponse("License not found", 404);
  }

  await prisma.license.update({
    where: { id },
    data: { status: LicenseStatus.REVOKED },
  });

  await revokeLicenseSessions(id);

  await writeAuditLog({
    licenseId: id,
    event: "admin.license_revoked",
    ip,
  });

  return jsonResponse({ success: true, status: LicenseStatus.REVOKED });
}
