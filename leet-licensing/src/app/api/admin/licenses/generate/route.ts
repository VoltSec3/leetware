import { requireRole, requireCsrf } from "@/lib/admin-auth";
import { writeAuditLog } from "@/lib/audit";
import {
  encryptLicenseKey,
  generateLicenseKey,
  hashLicense,
} from "@/lib/crypto";
import { errorResponse, getClientIp, jsonResponse } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { TIER_NAMES } from "@/lib/tiers";
import { generateLicensesSchema } from "@/lib/validation";

export async function POST(request: Request) {
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

  let body: unknown;

  try {
    body = await request.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const parsed = generateLicensesSchema.safeParse(body);

  if (!parsed.success) {
    return errorResponse(parsed.error.issues[0]?.message ?? "Invalid request", 400);
  }

  const { count, expiresAt, note, alias } = parsed.data;
  const tier =
    parsed.data.tier && TIER_NAMES.includes(parsed.data.tier as never)
      ? parsed.data.tier
      : "standard";
  const ip = await getClientIp();
  const generated: string[] = [];

  for (let index = 0; index < count; index += 1) {
    let licenseKey = generateLicenseKey();
    let licenseHash = hashLicense(licenseKey);

    while (await prisma.license.findUnique({ where: { licenseHash } })) {
      licenseKey = generateLicenseKey();
      licenseHash = hashLicense(licenseKey);
    }

    await prisma.license.create({
      data: {
        licenseHash,
        keyCipher: encryptLicenseKey(licenseKey),
        note,
        alias,
        tier,
        expiresAt: expiresAt ? new Date(expiresAt) : undefined,
      },
    });

    generated.push(licenseKey);
  }

  await writeAuditLog({
    event: "admin.licenses_generated",
    ip,
    metadata: { count: generated.length, alias, tier },
  });

  return jsonResponse({
    licenses: generated,
    count: generated.length,
  });
}
