import { redirect } from "next/navigation";

import { getAuthenticatedAdmin } from "@/lib/admin-auth";
import { DashboardNav } from "@/components/dashboard/nav";
import { GamesManager } from "@/components/dashboard/games-manager";

export default async function GamesPage() {
  const admin = await getAuthenticatedAdmin();

  if (!admin) {
    redirect("/dashboard/login");
  }

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100">
      <DashboardNav />
      <main className="mx-auto max-w-7xl space-y-6 px-6 py-8">
        <div>
          <h1 className="text-3xl font-semibold text-white">Games</h1>
          <p className="mt-2 text-zinc-400">
            Supported games, delivery modes, and gated payload sources.
          </p>
        </div>
        <GamesManager />
      </main>
    </div>
  );
}
