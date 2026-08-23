import "dotenv/config";
import { createAdminUser } from "../src/lib/admin-auth";
import { prisma } from "../src/lib/prisma";

const SEED_ACCOUNTS: Array<{ env: string; role: string }> = [
  { env: "INITIAL_ADMIN", role: "ADMIN" },
  { env: "INITIAL_SUPPORT", role: "SUPPORT" },
];

async function ensureAccount(emailEnv: string, passwordEnv: string, role: string) {
  const email = process.env[emailEnv];
  const password = process.env[passwordEnv];

  if (!email || !password) {
    console.log(`Skipping ${role} seed: set ${emailEnv} and ${passwordEnv}`);
    return;
  }

  const existing = await prisma.adminUser.findUnique({
    where: { email: email.toLowerCase() },
  });

  if (existing) {
    console.log(`${role} already exists for ${email}`);
    return;
  }

  const admin = await createAdminUser(email, password, role);
  console.log(`Created ${role} ${admin.email}`);
}

async function main() {
  for (const account of SEED_ACCOUNTS) {
    await ensureAccount(`${account.env}_EMAIL`, `${account.env}_PASSWORD`, account.role);
  }
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
