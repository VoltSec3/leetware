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
  totalUsers: number;
  expiringSoon: number;
  hwidResetsToday: number;
  authsToday: number;
  currentBuild: string;
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
    { label: "users", value: overview.totalUsers },
    { label: "online", value: overview.activeSessions },
    { label: "active licenses", value: overview.activatedLicenses },
    { label: "expiring soon", value: overview.expiringSoon },
    { label: "hwid resets today", value: overview.hwidResetsToday },
    { label: "authentications today", value: overview.authsToday },
    { label: "current build", value: overview.currentBuild },
  ];

  return (
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
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
