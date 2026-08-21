import { redirect } from "next/navigation";

import { getAuthenticatedAdmin } from "@/lib/admin-auth";
import { DashboardNav } from "@/components/dashboard/nav";
import { GenerateLicensesPanel } from "@/components/dashboard/generate-licenses";
import { LicensesTable } from "@/components/dashboard/licenses-table";

export default async function LicensesPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin) {
    redirect("/dashboard/login");
  }

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100">
      <DashboardNav />
      <main className="mx-auto max-w-7xl space-y-6 px-6 py-8">
        <div>
          <h1 className="text-3xl font-semibold text-white">Licenses</h1>
          <p className="mt-2 text-zinc-400">
            Generate, search, and manage loader licenses.
          </p>
        </div>
        <GenerateLicensesPanel />
        <LicensesTable />
      </main>
    </div>
  );
}
