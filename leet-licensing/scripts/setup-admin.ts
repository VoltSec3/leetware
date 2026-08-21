import "dotenv/config";
import { createAdminUser } from "../src/lib/admin-auth";
import { prisma } from "../src/lib/prisma";

async function main() {
  const email = process.env.INITIAL_ADMIN_EMAIL;
  const password = process.env.INITIAL_ADMIN_PASSWORD;

  if (!email || !password) {
    throw new Error(
      "Set INITIAL_ADMIN_EMAIL and INITIAL_ADMIN_PASSWORD before running setup:admin",
    );
  }

  const existing = await prisma.adminUser.findUnique({
    where: { email: email.toLowerCase() },
  });

  if (existing) {
    console.log(`Admin already exists for ${email}`);
    return;
  }

  const admin = await createAdminUser(email, password);
  console.log(`Created admin ${admin.email}`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
