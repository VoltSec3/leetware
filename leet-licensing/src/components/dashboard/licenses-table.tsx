"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

import { CopyButton } from "@/components/dashboard/copy-button";

type LicenseRow = {
  id: string;
  key: string | null;
  status: string;
  note: string | null;
  createdAt: string;
  expiresAt: string | null;
  activatedAt: string | null;
  activation: {
    hwidDisplay: string;
    firstIp: string | null;
    lastIp: string | null;
    clientVersion: string | null;
    lastSeen: string;
  } | null;
  activeSessions: number;
};

const statuses = ["", "UNUSED", "ACTIVATED", "REVOKED", "EXPIRED"];

function getCookie(name: string) {
  const match = document.cookie.match(new RegExp(`(?:^|; )${name}=([^;]*)`));
  return match ? decodeURIComponent(match[1]!) : null;
}

export function LicensesTable() {
  const [licenses, setLicenses] = useState<LicenseRow[]>([]);
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    let cancelled = false;

    async function loadLicenses() {
      const params = new URLSearchParams();
      if (query) params.set("q", query);
      if (status) params.set("status", status);

      const response = await fetch(`/api/admin/licenses?${params.toString()}`);
      const data = await response.json();

      if (cancelled) {
        return;
      }

      if (!response.ok) {
        setError(data.error ?? "Failed to load licenses");
        setLoading(false);
        return;
      }

      setLicenses(data.licenses ?? []);
      setLoading(false);
    }

    void loadLicenses();

    return () => {
      cancelled = true;
    };
  }, [query, status, reloadKey]);

  useEffect(() => {
    const handler = () => setReloadKey((key) => key + 1);

    window.addEventListener("licenses:generated", handler);
    return () => window.removeEventListener("licenses:generated", handler);
  }, []);

  async function revokeLicense(id: string) {
    const csrfCookie = getCookie("leet_csrf");

    const response = await fetch(`/api/admin/licenses/${id}/revoke`, {
      method: "POST",
      headers: {
        ...(csrfCookie ? { "x-csrf-token": csrfCookie } : {}),
      },
    });

    if (response.ok) {
      setReloadKey((key) => key + 1);
    }
  }

  return (
    <div className="rounded-xl border border-zinc-800 bg-zinc-950">
      <div className="flex flex-wrap items-end gap-4 border-b border-zinc-800 p-4">
        <label className="space-y-2">
          <span className="text-sm text-zinc-300">Search</span>
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Note or ID"
            className="rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-white"
          />
        </label>

        <label className="space-y-2">
          <span className="text-sm text-zinc-300">Status</span>
          <select
            value={status}
            onChange={(event) => setStatus(event.target.value)}
            className="rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-white"
          >
            {statuses.map((value) => (
              <option key={value || "all"} value={value}>
                {value || "All"}
              </option>
            ))}
          </select>
        </label>

        <button
          type="button"
          onClick={() => setReloadKey((key) => key + 1)}
          className="rounded-md border border-zinc-700 px-4 py-2 text-sm text-zinc-200 hover:bg-zinc-900"
        >
          Refresh
        </button>
      </div>

      {error ? (
        <p className="p-4 text-sm text-red-300">{error}</p>
      ) : loading ? (
        <p className="p-4 text-sm text-zinc-400">Loading licenses...</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full text-left text-sm">
            <thead className="border-b border-zinc-800 text-zinc-400">
              <tr>
                <th className="px-4 py-3 font-medium">License</th>
                <th className="px-4 py-3 font-medium">ID</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium">HWID</th>
                <th className="px-4 py-3 font-medium">Last seen</th>
                <th className="px-4 py-3 font-medium">Sessions</th>
                <th className="px-4 py-3 font-medium">Actions</th>
              </tr>
            </thead>
            <tbody>
              {licenses.map((license) => (
                <tr key={license.id} className="border-b border-zinc-900/80">
                  <td className="px-4 py-3">
                    {license.key ? (
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-zinc-200">{license.key}</span>
                        <CopyButton value={license.key} />
                      </div>
                    ) : (
                      <span className="text-zinc-600">—</span>
                    )}
                  </td>
                  <td className="px-4 py-3 font-mono text-zinc-300">
                    <Link
                      href={`/dashboard/licenses/${license.id}`}
                      className="hover:text-white"
                    >
                      {license.id.slice(0, 10)}…
                    </Link>
                  </td>
                  <td className="px-4 py-3">
                    <span className="rounded-full bg-zinc-900 px-2 py-1 text-xs text-zinc-200">
                      {license.status}
                    </span>
                  </td>
                  <td className="px-4 py-3 font-mono text-zinc-400">
                    {license.activation?.hwidDisplay ?? "—"}
                  </td>
                  <td className="px-4 py-3 text-zinc-400">
                    {license.activation?.lastSeen
                      ? new Date(license.activation.lastSeen).toLocaleString()
                      : "—"}
                  </td>
                  <td className="px-4 py-3 text-zinc-300">
                    {license.activeSessions}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex gap-2">
                      <Link
                        href={`/dashboard/licenses/${license.id}`}
                        className="text-violet-400 hover:text-violet-300"
                      >
                        View
                      </Link>
                      {license.status !== "REVOKED" ? (
                        <button
                          type="button"
                          onClick={() => void revokeLicense(license.id)}
                          className="text-red-400 hover:text-red-300"
                        >
                          Revoke
                        </button>
                      ) : null}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
