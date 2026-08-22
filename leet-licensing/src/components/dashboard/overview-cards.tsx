"use client";

import { useEffect, useState } from "react";

import { Panel } from "@/components/site/panel";

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
    return <p className="lw-error">{error}</p>;
  }

  if (!overview) {
    return <p className="lw-muted">loading overview...</p>;
  }

  const cards = [
    { label: "total licenses", value: overview.totalLicenses },
    { label: "unused", value: overview.unusedLicenses },
    { label: "activated", value: overview.activatedLicenses },
    { label: "revoked", value: overview.revokedLicenses },
    { label: "expired", value: overview.expiredLicenses },
    { label: "active sessions", value: overview.activeSessions },
    { label: "seen last 24h", value: overview.seenLast24h },
  ];

  return (
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      {cards.map((card) => (
        <Panel key={card.label}>
          <div className="p-3">
            <p className="lw-muted text-[12px]">{card.label}</p>
            <p className="lw-title mt-1 text-xl">{card.value}</p>
          </div>
        </Panel>
      ))}
    </div>
  );
}
