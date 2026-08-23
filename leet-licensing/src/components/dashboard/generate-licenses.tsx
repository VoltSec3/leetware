"use client";

import { FormEvent, useEffect, useState } from "react";

import { Panel } from "@/components/site/panel";
import { TIER_NAMES, TIERS, formatCooldown } from "@/lib/tiers";

function getCookie(name: string) {
  if (typeof document === "undefined") {
    return null;
  }

  const match = document.cookie.match(new RegExp(`(?:^|; )${name}=([^;]*)`));
  return match ? decodeURIComponent(match[1]!) : null;
}

export function GenerateLicensesPanel() {
  const [count, setCount] = useState(1);
  const [note, setNote] = useState("");
  const [alias, setAlias] = useState("");
  const [tier, setTier] = useState("standard");
  const [expiresAt, setExpiresAt] = useState("");
  const [generated, setGenerated] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();

    if (alias.trim().length < 2) {
      setError("Alias is required (min 2 characters).");
      return;
    }

    setLoading(true);
    setError(null);

    const csrfCookie = getCookie("leet_csrf");

    const response = await fetch("/api/admin/licenses/generate", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(csrfCookie ? { "x-csrf-token": csrfCookie } : {}),
      },
      body: JSON.stringify({
        count,
        note: note || undefined,
        alias: alias.trim(),
        tier,
        expiresAt: expiresAt ? new Date(expiresAt).toISOString() : undefined,
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      setError(data.error ?? "Failed to generate licenses");
      setLoading(false);
      return;
    }

    setGenerated(data.licenses ?? []);
    setLoading(false);
  }

  useEffect(() => {
    if (generated.length === 0) {
      return;
    }

    window.dispatchEvent(new CustomEvent("licenses:generated"));
  }, [generated]);

  return (
    <Panel>
      <div className="p-4">
        <h2 className="lw-title">generate licenses</h2>
        <p className="lw-muted mt-1 text-[12px]">
          plaintext keys are shown once. only hashes are stored server-side.
        </p>

        <form onSubmit={handleSubmit} className="mt-3 grid gap-3 md:grid-cols-5">
          <label className="space-y-1">
            <span className="lw-label">count</span>
            <input
              type="number"
              min={1}
              max={100}
              value={count}
              onChange={(event) => setCount(Number(event.target.value))}
              className="lw-input"
            />
          </label>

          <label className="space-y-1">
            <span className="lw-label">alias (username)</span>
            <input
              type="text"
              required
              minLength={2}
              maxLength={64}
              value={alias}
              onChange={(event) => setAlias(event.target.value)}
              placeholder="who is this for?"
              className="lw-input"
            />
          </label>

          <label className="space-y-1">
            <span className="lw-label">tier</span>
            <select
              value={tier}
              onChange={(event) => setTier(event.target.value)}
              className="lw-select"
            >
              {TIER_NAMES.map((name) => (
                <option key={name} value={name}>
                  {name}
                </option>
              ))}
            </select>
          </label>

          <label className="space-y-1">
            <span className="lw-label">note (optional)</span>
            <input
              type="text"
              value={note}
              onChange={(event) => setNote(event.target.value)}
              className="lw-input"
            />
          </label>

          <label className="space-y-1">
            <span className="lw-label">expires (optional)</span>
            <input
              type="datetime-local"
              value={expiresAt}
              onChange={(event) => setExpiresAt(event.target.value)}
              className="lw-input"
            />
          </label>

          <div className="md:col-span-5">
            <button type="submit" disabled={loading} className="lw-btn lw-btn-accent">
              {loading ? "generating..." : "generate"}
            </button>
            <span className="lw-dim ml-3 text-[11px]">
              {TIER_NAMES.map((name) => {
                const perks = TIERS[name];
                return `${name}: /${formatCooldown(perks.hwidResetCooldownSeconds)} hwid, ${perks.maxRobloxAccounts ?? "∞"} roblox`;
              }).join(" · ")}
            </span>
          </div>
        </form>

        {error ? (
          <p className="lw-error mt-3 text-[12px]">{error}</p>
        ) : null}

        {generated.length > 0 ? (
          <div className="mt-3 border border-[#24502e] p-3">
            <p className="text-[#57d977] text-[12px] font-bold">
              generated {generated.length} license{generated.length === 1 ? "" : "s"}
            </p>
            <div className="lw-mono mt-2 space-y-1 text-[13px]">
              {generated.map((license) => (
                <div key={license}>{license}</div>
              ))}
            </div>
          </div>
        ) : null}
      </div>
    </Panel>
  );
}
