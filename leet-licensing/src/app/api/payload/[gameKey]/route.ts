import { LicenseStatus } from "@prisma/client";

import { errorResponse, getClientIp, jsonResponse } from "@/lib/http";
import {
  findValidLoaderSession,
  markExpiredLicenses,
  resolveLicenseStatus,
  verifyHwidForLicense,
} from "@/lib/license-service";
import { prisma } from "@/lib/prisma";

type RouteContext = {
  params: Promise<{ gameKey: string }>;
};

export async function GET(request: Request, context: RouteContext) {
  const { gameKey } = await context.params;
  const ip = await getClientIp();

  const authHeader = request.headers.get("authorization");
  const sessionToken = authHeader?.startsWith("Bearer ")
    ? authHeader.slice(7)
    : null;
  const hwid = request.headers.get("x-hwid");

  if (!sessionToken || !hwid) {
    return errorResponse("Missing authentication headers", 401);
  }

  await markExpiredLicenses();

  const session = await findValidLoaderSession(sessionToken);

  if (!session) {
    return errorResponse("Invalid or expired session", 401);
  }

  const status = await resolveLicenseStatus(session.license);

  if (status !== LicenseStatus.ACTIVATED) {
    return errorResponse("License is not active", 403);
  }

  const hwidMatches = await verifyHwidForLicense(session.licenseId, hwid);

  if (!hwidMatches) {
    return errorResponse("HWID mismatch", 403);
  }

  const game = await prisma.supportedGame.findFirst({
    where: {
      moduleKey: gameKey,
      enabled: true,
    },
  });

  if (!game) {
    return errorResponse("Unsupported game module", 404);
  }

  if (game.payloadSource) {
    return new Response(game.payloadSource, {
      status: 200,
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "Cache-Control": "no-store",
      },
    });
  }

  return jsonResponse({
    game: {
      id: game.gameId,
      name: game.name,
      moduleKey: game.moduleKey,
    },
    payload: {
      available: false,
      message:
        "This module is registered for gated delivery but no payload source has been uploaded yet. Add one in Dashboard > Games.",
    },
    telemetry: {
      ip,
      sessionId: session.id,
    },
  });
}
