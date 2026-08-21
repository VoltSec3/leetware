"use client";

import { useEffect, useState } from "react";

type Overview = {
  totalLicenses: number;
  unusedLicenses: number;
  activatedLicenses: number;
  revokedLicenses: number;
  expiredLicenses: number;
  activeSessions: number;
  seenLast24h: number;
};

export function OverviewCards() {
  const [overview, setOverview] = useState<Overview | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function loadOverview() {
      const response = await fetch("/api/admin/stats/overview");
      const data = await response.json();

      if (!response.ok) {
        setError(data.error ?? "Failed to load overview");
        return;
      }

      setOverview(data.overview);
    }

    void loadOverview();
  }, []);

  if (error) {
    return <p className="text-sm text-red-300">{error}</p>;
  }

  if (!overview) {
    return <p className="text-sm text-zinc-400">Loading overview...</p>;
  }

  const cards = [
    { label: "Total licenses", value: overview.totalLicenses },
    { label: "Unused", value: overview.unusedLicenses },
    { label: "Activated", value: overview.activatedLicenses },
    { label: "Revoked", value: overview.revokedLicenses },
    { label: "Expired", value: overview.expiredLicenses },
    { label: "Active sessions", value: overview.activeSessions },
    { label: "Seen last 24h", value: overview.seenLast24h },
  ];

  return (
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      {cards.map((card) => (
        <div
          key={card.label}
          className="rounded-xl border border-zinc-800 bg-zinc-950 p-5"
        >
          <p className="text-sm text-zinc-400">{card.label}</p>
          <p className="mt-2 text-3xl font-semibold text-white">{card.value}</p>
        </div>
      ))}
    </div>
  );
}
