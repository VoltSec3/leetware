"use client";

import { FormEvent, useEffect, useState } from "react";

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
    <div className="rounded-xl border border-zinc-800 bg-zinc-950 p-6">
      <h2 className="text-lg font-medium text-white">Generate licenses</h2>
      <p className="mt-1 text-sm text-zinc-400">
        Plaintext keys are shown once. Only hashes are stored server-side.
      </p>

      <form onSubmit={handleSubmit} className="mt-4 grid gap-4 md:grid-cols-4">
        <label className="space-y-2">
          <span className="text-sm text-zinc-300">Count</span>
          <input
            type="number"
            min={1}
            max={100}
            value={count}
            onChange={(event) => setCount(Number(event.target.value))}
            className="w-full rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-white"
          />
        </label>

        <label className="space-y-2">
          <span className="text-sm text-zinc-300">Alias (username)</span>
          <input
            type="text"
            required
            minLength={2}
            maxLength={64}
            value={alias}
            onChange={(event) => setAlias(event.target.value)}
            placeholder="Who is this license for?"
            className="w-full rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-white"
          />
        </label>

        <label className="space-y-2">
          <span className="text-sm text-zinc-300">Note (optional)</span>
          <input
            type="text"
            value={note}
            onChange={(event) => setNote(event.target.value)}
            className="w-full rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-white"
          />
        </label>

        <label className="space-y-2">
          <span className="text-sm text-zinc-300">Expires (optional)</span>
          <input
            type="datetime-local"
            value={expiresAt}
            onChange={(event) => setExpiresAt(event.target.value)}
            className="w-full rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-white"
          />
        </label>

        <div className="md:col-span-4">
          <button
            type="submit"
            disabled={loading}
            className="rounded-md bg-violet-600 px-4 py-2 text-sm font-medium text-white hover:bg-violet-500 disabled:opacity-60"
          >
            {loading ? "Generating..." : "Generate"}
          </button>
        </div>
      </form>

      {error ? (
        <p className="mt-4 text-sm text-red-300">{error}</p>
      ) : null}

      {generated.length > 0 ? (
        <div className="mt-4 rounded-lg border border-emerald-900/50 bg-emerald-950/20 p-4">
          <p className="text-sm font-medium text-emerald-200">
            Generated {generated.length} license{generated.length === 1 ? "" : "s"}
          </p>
          <div className="mt-3 space-y-2 font-mono text-sm text-emerald-100">
            {generated.map((license) => (
              <div key={license}>{license}</div>
            ))}
          </div>
        </div>
      ) : null}
    </div>
  );
}
