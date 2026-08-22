import { requireAdmin } from "@/lib/admin-auth";
import { decryptLicenseKey, displayHwidHash } from "@/lib/crypto";
import { errorResponse, jsonResponse } from "@/lib/http";
import { markExpiredLicenses } from "@/lib/license-service";
import { prisma } from "@/lib/prisma";
import { resolveRobloxUser } from "@/lib/roblox";

type RouteContext = {
  params: Promise<{ id: string }>;
};

export async function GET(_request: Request, context: RouteContext) {
  try {
    await requireAdmin();
  } catch {
    return errorResponse("Unauthorized", 401);
  }

  const { id } = await context.params;

  await markExpiredLicenses(id);

  const [license, totalSessions] = await Promise.all([
    prisma.license.findUnique({
      where: { id },
      include: {
        activation: true,
        sessions: {
          orderBy: { createdAt: "desc" },
          take: 50,
        },
        auditLogs: {
          orderBy: { createdAt: "desc" },
          take: 50,
        },
      },
    }),
    prisma.loaderSession.count({ where: { licenseId: id } }),
  ]);

  if (!license) {
    return errorResponse("License not found", 404);
  }

  let robloxUserId: number | string | null = null;
  let robloxUsername: string | null = null;
  const metadata = license.activation?.metadata as Record<
    string,
    unknown
  > | null;

  if (metadata && typeof metadata === "object") {
    if (
      typeof metadata.robloxUserId === "number"
      || typeof metadata.robloxUserId === "string"
    ) {
      robloxUserId = metadata.robloxUserId;
    }

    if (typeof metadata.robloxUsername === "string") {
      robloxUsername = metadata.robloxUsername;
    }
  }

  const robloxUser = await resolveRobloxUser({
    userId: robloxUserId,
    username: robloxUsername,
  });

  return jsonResponse({
    license: {
      id: license.id,
      key: decryptLicenseKey(license.keyCipher),
      status: license.status,
      note: license.note,
      alias: license.alias,
      createdAt: license.createdAt.toISOString(),
      expiresAt: license.expiresAt?.toISOString() ?? null,
      activatedAt: license.activatedAt?.toISOString() ?? null,
      activation: license.activation
        ? {
            hwidDisplay: displayHwidHash(license.activation.hwidHash),
            hwidHash: license.activation.hwidHash,
            firstIp: license.activation.firstIp,
            lastIp: license.activation.lastIp,
            clientVersion: license.activation.clientVersion,
            metadata: license.activation.metadata,
            createdAt: license.activation.createdAt.toISOString(),
            lastSeen: license.activation.lastSeen.toISOString(),
          }
        : null,
      sessions: license.sessions.map((session) => ({
        id: session.id,
        createdAt: session.createdAt.toISOString(),
        expiresAt: session.expiresAt.toISOString(),
        lastSeen: session.lastSeen.toISOString(),
        revoked: session.revoked,
        active:
          !session.revoked && session.expiresAt.getTime() > Date.now(),
      })),
      auditLogs: license.auditLogs.map((log) => ({
        id: log.id,
        event: log.event,
        ip: log.ip,
        metadata: log.metadata,
        createdAt: log.createdAt.toISOString(),
      })),
    },
    totalSessions,
    robloxUser,
  });
}
