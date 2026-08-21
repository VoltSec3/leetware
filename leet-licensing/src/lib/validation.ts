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
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(128),
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
