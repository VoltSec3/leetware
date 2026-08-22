import { redirect } from "next/navigation";

import { getAuthenticatedAdmin } from "@/lib/admin-auth";
import { DashboardNav } from "@/components/dashboard/nav";
import { OverviewCards } from "@/components/dashboard/overview-cards";

export default async function DashboardPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin) {
    redirect("/dashboard/login");
  }

  return (
    <div className="min-h-screen">
      <DashboardNav />
      <main className="mx-auto max-w-6xl space-y-5 px-4 py-5 pb-12">
        <div>
          <h1 className="lw-title text-[15px]">overview</h1>
          <p className="lw-muted mt-1 text-[12px]">
            signed in as {admin.email}
          </p>
        </div>
        <OverviewCards />
      </main>
    </div>
  );
}
