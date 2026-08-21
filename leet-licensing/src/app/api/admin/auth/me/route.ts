import { getAuthenticatedAdmin } from "@/lib/admin-auth";
import { jsonResponse } from "@/lib/http";

export async function GET() {
  const admin = await getAuthenticatedAdmin();

  if (!admin) {
    return jsonResponse({ authenticated: false }, 401);
  }

  return jsonResponse({
    authenticated: true,
    email: admin.email,
    id: admin.id,
  });
}
