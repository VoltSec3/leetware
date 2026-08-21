import { redirect } from "next/navigation";

import { getAuthenticatedAdmin } from "@/lib/admin-auth";
import { DashboardNav } from "@/components/dashboard/nav";
import { LicenseDetailPanel } from "@/components/dashboard/license-detail";

type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function LicenseDetailPage({ params }: PageProps) {
  const admin = await getAuthenticatedAdmin();

  if (!admin) {
    redirect("/dashboard/login");
  }

  const { id } = await params;

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100">
      <DashboardNav />
      <main className="mx-auto max-w-7xl px-6 py-8">
        <LicenseDetailPanel licenseId={id} />
      </main>
    </div>
  );
}
