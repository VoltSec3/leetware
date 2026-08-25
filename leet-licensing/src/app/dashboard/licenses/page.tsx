import { redirect } from "next/navigation";

import { requireRole } from "@/lib/admin-auth";
import { DashboardNav } from "@/components/dashboard/nav";
import { GenerateLicensesPanel } from "@/components/dashboard/generate-licenses";
import { LicensesTable } from "@/components/dashboard/licenses-table";

export default async function LicensesPage() {
  const admin = await requireRole(["ADMIN"]).catch(() => null);

  if (!admin) {
    redirect("/dashboard");
  }

  return (
    <div className="min-h-screen">
      <DashboardNav />
      <main className="lw-main mx-auto max-w-6xl space-y-5 px-4 py-5 pb-12">
        <div>
          <h1 className="lw-title text-[15px]">Licenses</h1>
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
