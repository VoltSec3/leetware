import { Prisma } from "@prisma/client";

import { prisma } from "@/lib/prisma";

export async function writeAuditLog(input: {
  licenseId?: string;
  event: string;
  ip?: string | null;
  metadata?: Prisma.InputJsonValue;
}) {
  await prisma.auditLog.create({
    data: {
      licenseId: input.licenseId,
      event: input.event,
      ip: input.ip ?? undefined,
      metadata: input.metadata,
    },
  });
}
