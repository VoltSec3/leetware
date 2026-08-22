"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

import { CopyButton } from "@/components/dashboard/copy-button";
import { Panel, StatusPill } from "@/components/site/panel";

type LicenseRow = {
  id: string;
  key: string | null;
  status: string;
  note: string | null;
  alias: string | null;
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

const statuses = ["", "UNUSED", "ACTIVATED", "SUSPENDED", "REVOKED", "EXPIRED"];

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
    <Panel>
      <div className="flex flex-wrap items-end gap-3 border-b border-[#282828] p-4">
        <label className="space-y-1">
          <span className="lw-label">search</span>
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="alias, note or id"
            className="lw-input max-w-[200px]"
          />
        </label>

        <label className="space-y-1">
          <span className="lw-label">status</span>
          <select
            value={status}
            onChange={(event) => setStatus(event.target.value)}
            className="lw-select max-w-[140px]"
          >
            {statuses.map((value) => (
              <option key={value || "all"} value={value}>
                {value || "all"}
              </option>
            ))}
          </select>
        </label>

        <button
          type="button"
          onClick={() => setReloadKey((key) => key + 1)}
          className="lw-btn"
        >
          refresh
        </button>
      </div>

      {error ? (
        <p className="lw-error p-4 text-[12px]">{error}</p>
      ) : loading ? (
        <p className="lw-muted p-4 text-[12px]">loading licenses...</p>
      ) : (
        <div className="overflow-x-auto p-2">
          <table className="lw-table">
            <thead>
              <tr>
                <th>license</th>
                <th>alias</th>
                <th>id</th>
                <th>status</th>
                <th>hwid</th>
                <th>last seen</th>
                <th>sessions</th>
                <th>actions</th>
              </tr>
            </thead>
            <tbody>
              {licenses.map((license) => (
                <tr key={license.id}>
                  <td>
                    {license.key ? (
                      <span className="flex items-center gap-2">
                        <span className="lw-mono">{license.key}</span>
                        <CopyButton value={license.key} />
                      </span>
                    ) : (
                      <span className="lw-dim">—</span>
                    )}
                  </td>
                  <td>{license.alias ?? <span className="lw-dim">—</span>}</td>
                  <td className="lw-mono">
                    <Link
                      href={`/dashboard/licenses/${license.id}`}
                      className="hover:text-[#cce335]"
                    >
                      {license.id.slice(0, 10)}…
                    </Link>
                  </td>
                  <td>
                    <StatusPill value={license.status} />
                  </td>
                  <td className="lw-mono">
                    {license.activation?.hwidDisplay ?? "—"}
                  </td>
                  <td>
                    {license.activation?.lastSeen
                      ? new Date(license.activation.lastSeen).toLocaleString()
                      : "—"}
                  </td>
                  <td>{license.activeSessions}</td>
                  <td>
                    <div className="flex gap-2">
                      <Link
                        href={`/dashboard/licenses/${license.id}`}
                        className="hover:text-[#cce335]"
                      >
                        view
                      </Link>
                      {license.status !== "REVOKED" ? (
                        <button
                          type="button"
                          onClick={() => void revokeLicense(license.id)}
                          className="text-[#e05555] hover:text-[#ff7777]"
                        >
                          revoke
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
    </Panel>
  );
}
