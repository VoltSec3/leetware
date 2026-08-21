import { cookies } from "next/headers";

import {
  ADMIN_SESSION_COOKIE,
  CSRF_COOKIE,
  destroyAdminSession,
} from "@/lib/admin-auth";
import { writeAuditLog } from "@/lib/audit";
import { getClientIp, jsonResponse } from "@/lib/http";

export async function POST() {
  const ip = await getClientIp();
  const cookieStore = await cookies();
  const token = cookieStore.get(ADMIN_SESSION_COOKIE)?.value;

  if (token) {
    await destroyAdminSession(token);
  }

  cookieStore.delete(ADMIN_SESSION_COOKIE);
  cookieStore.delete(CSRF_COOKIE);

  await writeAuditLog({
    event: "admin.logout",
    ip,
  });

  return jsonResponse({ success: true });
}
