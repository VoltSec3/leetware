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
    <div className="min-h-screen bg-zinc-950 text-zinc-100">
      <DashboardNav />
      <main className="mx-auto max-w-7xl space-y-6 px-6 py-8">
        <div>
          <h1 className="text-3xl font-semibold text-white">Overview</h1>
          <p className="mt-2 text-zinc-400">
            Signed in as {admin.email}
          </p>
        </div>
        <OverviewCards />
      </main>
    </div>
  );
}
