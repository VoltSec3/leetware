import { Prisma } from "@prisma/client";

import { prisma } from "@/lib/prisma";

export type AuditActor = {
  type: "admin" | "user" | "loader" | "system";
  name: string;
};

export async function writeAuditLog(input: {
  licenseId?: string | null;
  event: string;
  ip?: string | null;
  actor?: AuditActor;
  metadata?: Prisma.InputJsonValue;
}) {
  await prisma.auditLog.create({
    data: {
      licenseId: input.licenseId ?? undefined,
      event: input.event,
      ip: input.ip ?? undefined,
      actorType: input.actor?.type,
      actorName: input.actor?.name,
      metadata: input.metadata,
    },
  });
}
