import {
  createCipheriv,
  createDecipheriv,
  createHash,
  createHmac,
  randomBytes,
  timingSafeEqual,
} from "crypto";

import { env } from "@/lib/env";

const LICENSE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export function generateLicenseKey(): string {
  const segments: string[] = [];

  for (let segment = 0; segment < 4; segment += 1) {
    let part = "";
    for (let index = 0; index < 4; index += 1) {
      const byte = randomBytes(1)[0]!;
      part += LICENSE_ALPHABET[byte % LICENSE_ALPHABET.length];
    }
    segments.push(part);
  }

  return segments.join("-");
}

export function normalizeLicenseKey(license: string): string {
  return license.trim().toUpperCase().replace(/\s+/g, "");
}

export function hashLicense(license: string): string {
  return createHmac("sha256", env.licenseHmacSecret)
    .update(normalizeLicenseKey(license))
    .digest("hex");
}

export function hashHwid(hwid: string): string {
  return createHmac("sha256", env.hwidHmacSecret)
    .update(hwid.trim())
    .digest("hex");
}

export function hashToken(token: string): string {
  return createHmac("sha256", env.adminSessionSecret)
    .update(token)
    .digest("hex");
}

export function generateSessionToken(): string {
  return randomBytes(32).toString("base64url");
}

export function safeEqual(a: string, b: string): boolean {
  const left = Buffer.from(a);
  const right = Buffer.from(b);

  if (left.length !== right.length) {
    return false;
  }

  return timingSafeEqual(left, right);
}

export function displayHwidHash(hwidHash: string): string {
  return `${hwidHash.slice(0, 8)}…${hwidHash.slice(-8)}`;
}

// ─── License key recovery (AES-256-GCM) ─────────────────────────────────────
// Plaintext keys are never stored, but an encrypted copy is kept so admins
// can retrieve keys after generation. The encryption key is derived from
// LICENSE_HMAC_SECRET, so rotating that secret also makes existing stored
// keys unrecoverable (they are already invalid after rotation anyway).

function licenseEncryptionKey(): Buffer {
  return createHash("sha256")
    .update(`leetware:license-enc:v1:${env.licenseHmacSecret}`)
    .digest();
}

export function encryptLicenseKey(plainKey: string): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-gcm", licenseEncryptionKey(), iv);
  const ciphertext = Buffer.concat([
    cipher.update(plainKey, "utf8"),
    cipher.final(),
  ]);
  const tag = cipher.getAuthTag();

  return Buffer.concat([iv, tag, ciphertext]).toString("base64");
}

export function decryptLicenseKey(payload: string | null | undefined): string | null {
  if (!payload) {
    return null;
  }

  try {
    const raw = Buffer.from(payload, "base64");
    const iv = raw.subarray(0, 12);
    const tag = raw.subarray(12, 28);
    const data = raw.subarray(28);

    const decipher = createDecipheriv(
      "aes-256-gcm",
      licenseEncryptionKey(),
      iv,
    );
    decipher.setAuthTag(tag);

    return Buffer.concat([decipher.update(data), decipher.final()]).toString(
      "utf8",
    );
  } catch {
    return null;
  }
}
