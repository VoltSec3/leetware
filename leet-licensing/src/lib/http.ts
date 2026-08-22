import { headers } from "next/headers";

export async function getClientIp(): Promise<string | null> {
  const headerList = await headers();
  const forwarded = headerList.get("x-forwarded-for");

  if (forwarded) {
    return forwarded.split(",")[0]?.trim() ?? null;
  }

  return headerList.get("x-real-ip");
}

export function jsonResponse(
  body: unknown,
  status = 200,
  extraHeaders: Record<string, string> = {},
) {
  return Response.json(body, {
    status,
    headers: {
      "Cache-Control": "no-store",
      ...extraHeaders,
    },
  });
}

export function errorResponse(
  message: string,
  status: number,
  extra: Record<string, unknown> = {},
) {
  return jsonResponse({ error: message, ...extra }, status);
}
