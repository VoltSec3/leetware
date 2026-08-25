import { redirect } from "next/navigation";

import { requireRole } from "@/lib/admin-auth";
import { DashboardNav } from "@/components/dashboard/nav";
import { GamesManager } from "@/components/dashboard/games-manager";

export default async function GamesPage() {
  const admin = await requireRole(["ADMIN"]).catch(() => null);

  if (!admin) {
    redirect("/dashboard");
  }

  return (
    <div className="min-h-screen">
      <DashboardNav />
      <main className="lw-main mx-auto max-w-6xl space-y-5 px-4 py-5 pb-12">
        <div>
          <h1 className="lw-title text-[15px]">Games</h1>
          <p className="mt-2 text-zinc-400">
            Supported games, delivery modes, and gated payload sources.
          </p>
        </div>
        <GamesManager />
      </main>
    </div>
  );
}
