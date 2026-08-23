import { z } from "zod";

const gameContextSchema = {
  gameId: z.union([z.string(), z.number()]).optional(),
  gameName: z.string().max(128).optional(),
};

export const activateSchema = z.object({
  license: z.string().min(10).max(64),
  hwid: z.string().min(8).max(512),
  clientVersion: z.string().max(64).optional(),
  metadata: z.record(z.string(), z.unknown()).optional(),
  ...gameContextSchema,
});

export const sessionSchema = z.object({
  license: z.string().min(10).max(64).optional(),
  sessionToken: z.string().min(16).max(256).optional(),
  hwid: z.string().min(8).max(512),
  clientVersion: z.string().max(64).optional(),
  metadata: z.record(z.string(), z.unknown()).optional(),
  ...gameContextSchema,
}).refine(
  (value) => Boolean(value.license || value.sessionToken),
  { message: "Either license or sessionToken is required" },
);

export const validateSchema = z.object({
  sessionToken: z.string().min(16).max(256),
  hwid: z.string().min(8).max(512),
  ...gameContextSchema,
});

export const heartbeatSchema = validateSchema;

export const generateLicensesSchema = z.object({
  count: z.number().int().min(1).max(100).default(1),
  expiresAt: z.string().datetime().optional(),
  note: z.string().max(256).optional(),
  tier: z
    .string()
    .trim()
    .min(2)
    .max(32)
    .regex(/^[a-z0-9-]+$/, "lowercase letters, digits, dashes")
    .optional(),
  alias: z
    .string()
    .trim()
    .min(2, "Alias must be at least 2 characters")
    .max(64, "Alias must be at most 64 characters"),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(128),
});

const emailField = z
  .string()
  .trim()
  .toLowerCase()
  .email("Enter a valid email address")
  .max(200);

export const userLoginSchema = z.object({
  username: z.string().trim().min(1).max(32),
  password: z.string().min(1).max(128),
});

export const verifyEmailSchema = z.object({
  email: emailField,
  code: z.string().trim().regex(/^\d{6}$/, "Code must be 6 digits"),
});

export const resendVerificationSchema = z.object({
  email: emailField,
});

export const forgotPasswordSchema = z.object({
  email: emailField,
});

export const resetPasswordSchema = z.object({
  email: emailField,
  code: z.string().trim().regex(/^\d{6}$/, "Code must be 6 digits"),
  newPassword: z.string().min(8).max(128),
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1).max(128),
  newPassword: z.string().min(8).max(128),
});

export const addRobloxAccountSchema = z.object({
  username: z
    .string()
    .trim()
    .min(3)
    .max(20)
    .regex(/^[A-Za-z0-9_]+$/, "Invalid Roblox username"),
  robloxUserId: z.coerce.number().int().positive().optional(),
});

export const suspendLicenseSchema = z.object({
  reason: z.string().trim().max(256).optional(),
  lift: z.boolean().optional(),
});

export const extendLicenseSchema = z.object({
  days: z.number().int().min(-3650).max(3650).optional(),
  expiresAt: z.string().datetime().nullable().optional(),
}).refine(
  (value) => value.days !== undefined || value.expiresAt !== undefined,
  { message: "days or expiresAt is required" },
);

export const tierLicenseSchema = z.object({
  tier: z.string().trim().min(2).max(32).regex(/^[a-z0-9-]+$/, "lowercase letters, digits, dashes"),
});

export const assignLicenseSchema = z.object({
  userId: z.string().min(1).nullable(),
});

export const transferLicenseSchema = z.object({
  targetUserId: z.string().min(1),
});

export const licenseListSchema = z.object({
  q: z.string().max(128).optional(),
  status: z.enum(["UNUSED", "ACTIVATED", "REVOKED", "EXPIRED"]).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(25),
});

export const upsertGameSchema = z.object({
  gameId: z
    .union([z.string(), z.number()])
    .transform((value) => String(value))
    .refine((value) => /^\d{1,20}$/.test(value), {
      message: "gameId must be a Roblox GameId (numeric string)",
    }),
  name: z.string().min(1).max(128),
  moduleKey: z
    .string()
    .min(1)
    .max(64)
    .regex(/^[a-z0-9]+(-[a-z0-9]+)*$/, "lowercase letters, digits, dashes")
    .optional(),
  delivery: z.enum(["direct", "api"]).optional(),
  scriptUrl: z.string().url().max(512).optional().or(z.literal("")),
  payloadSource: z.string().max(1_000_000).optional(),
  enabled: z.boolean().optional(),
});

export const updateGameSchema = z.object({
  name: z.string().min(1).max(128).optional(),
  moduleKey: z
    .string()
    .min(1)
    .max(64)
    .regex(/^[a-z0-9]+(-[a-z0-9]+)*$/, "lowercase letters, digits, dashes")
    .optional(),
  delivery: z.enum(["direct", "api"]).optional(),
  scriptUrl: z.string().url().max(512).optional().or(z.literal("")),
  payloadSource: z.string().max(1_000_000).optional(),
  enabled: z.boolean().optional(),
});

export const userSuspendSchema = z.object({
  suspendedUntil: z
    .string()
    .datetime({ offset: true })
    .nullable()
    .optional(),
});

export const userBanSchema = z.object({
  reason: z.string().trim().min(3).max(256),
});

export const userUnbanSchema = z.object({
  liftIpBan: z.boolean().optional(),
});
