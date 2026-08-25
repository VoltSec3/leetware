import { redirect } from "next/navigation";

import { requireRole } from "@/lib/admin-auth";
import { DashboardNav } from "@/components/dashboard/nav";
import { LicenseDetailPanel } from "@/components/dashboard/license-detail";

type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function LicenseDetailPage({ params }: PageProps) {
  const admin = await requireRole(["ADMIN"]).catch(() => null);

  if (!admin) {
    redirect("/dashboard");
  }

  const { id } = await params;

  return (
    <div className="min-h-screen">
      <DashboardNav />
      <main className="lw-main mx-auto max-w-6xl px-4 py-5 pb-12">
        <LicenseDetailPanel licenseId={id} />
      </main>
    </div>
  );
}
