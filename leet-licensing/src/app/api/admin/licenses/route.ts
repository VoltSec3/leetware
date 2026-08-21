import { LicenseStatus } from "@prisma/client";

import { requireAdmin } from "@/lib/admin-auth";
import { decryptLicenseKey } from "@/lib/crypto";
import { errorResponse, jsonResponse } from "@/lib/http";
import { prisma } from "@/lib/prisma";

export async function GET(request: Request) {
  try {
    await requireAdmin();
  } catch {
    return errorResponse("Unauthorized", 401);
  }

  const url = new URL(request.url);
  const q = url.searchParams.get("q") ?? undefined;
  const statusParam = url.searchParams.get("status");
  const page = Math.max(Number(url.searchParams.get("page") ?? "1"), 1);
  const limit = Math.min(Math.max(Number(url.searchParams.get("limit") ?? "25"), 1), 100);
  const skip = (page - 1) * limit;

  const status =
    statusParam &&
    Object.values(LicenseStatus).includes(statusParam as LicenseStatus)
      ? (statusParam as LicenseStatus)
      : undefined;

  const where = {
    ...(status ? { status } : {}),
    ...(q
      ? {
          OR: [
            { note: { contains: q, mode: "insensitive" as const } },
            { id: { contains: q } },
          ],
        }
      : {}),
  };

  const [licenses, total] = await Promise.all([
    prisma.license.findMany({
      where,
      include: {
        activation: true,
        sessions: {
          where: {
            revoked: false,
            expiresAt: { gt: new Date() },
          },
        },
      },
      orderBy: { createdAt: "desc" },
      skip,
      take: limit,
    }),
    prisma.license.count({ where }),
  ]);

  return jsonResponse({
    licenses: licenses.map((license) => ({
      id: license.id,
      key: decryptLicenseKey(license.keyCipher),
      status: license.status,
      note: license.note,
      createdAt: license.createdAt.toISOString(),
      expiresAt: license.expiresAt?.toISOString() ?? null,
      activatedAt: license.activatedAt?.toISOString() ?? null,
      activation: license.activation
        ? {
            hwidDisplay: `${license.activation.hwidHash.slice(0, 8)}…${license.activation.hwidHash.slice(-8)}`,
            firstIp: license.activation.firstIp,
            lastIp: license.activation.lastIp,
            clientVersion: license.activation.clientVersion,
            lastSeen: license.activation.lastSeen.toISOString(),
          }
        : null,
      activeSessions: license.sessions.length,
    })),
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  });
}
