import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

function randomToken(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);

  let binary = "";

  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function signCsrfToken(token: string): Promise<string> {
  const secret = process.env.CSRF_SECRET ?? "dev-csrf-secret";

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(token),
  );

  const bytes = new Uint8Array(signature);
  let binary = "";

  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  const encoded = btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  return `${token}.${encoded}`;
}

export async function proxy(request: NextRequest) {
  if (
    request.nextUrl.protocol !== "https:" &&
    process.env.NODE_ENV === "production"
  ) {
    const url = request.nextUrl.clone();
    url.protocol = "https:";
    return NextResponse.redirect(url);
  }

  const response = NextResponse.next();

  if (!request.cookies.get("leet_csrf")?.value) {
    response.cookies.set({
      name: "leet_csrf",
      value: await signCsrfToken(randomToken()),
      httpOnly: false,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      path: "/",
    });
  }

  return response;
}

export const config = {
  matcher: ["/", "/account/:path*", "/dashboard/:path*", "/api/:path*"],
};
