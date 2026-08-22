"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

import { CopyButton } from "@/components/dashboard/copy-button";

type ActivationInfo = {
  hwidDisplay: string;
  hwidHash: string;
  firstIp: string | null;
  lastIp: string | null;
  clientVersion: string | null;
  metadata: unknown;
  createdAt: string;
  lastSeen: string;
};

type SessionRow = {
  id: string;
  createdAt: string;
  expiresAt: string;
  lastSeen: string;
  revoked: boolean;
  active: boolean;
};

type AuditRow = {
  id: string;
  event: string;
  ip: string | null;
  metadata: unknown;
  createdAt: string;
};

type LicenseDetail = {
  id: string;
  key: string | null;
  status: string;
  note: string | null;
  alias: string | null;
  createdAt: string;
  expiresAt: string | null;
  activatedAt: string | null;
  activation: ActivationInfo | null;
  sessions: SessionRow[];
  auditLogs: AuditRow[];
};

type RobloxUserInfo = {
  userId: number;
  username: string;
  displayName: string;
  avatarUrl: string | null;
};

function getCookie(name: string) {
  const match = document.cookie.match(new RegExp(`(?:^|; )${name}=([^;]*)`));
  return match ? decodeURIComponent(match[1]!) : null;
}

type LicenseDetailProps = {
  licenseId: string;
};

export function LicenseDetailPanel({ licenseId }: LicenseDetailProps) {
  const [license, setLicense] = useState<LicenseDetail | null>(null);
  const [totalSessions, setTotalSessions] = useState(0);
  const [robloxUser, setRobloxUser] = useState<RobloxUserInfo | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    let cancelled = false;

    async function loadLicense() {
      const response = await fetch(`/api/admin/licenses/${licenseId}`);
      const data = await response.json();

      if (cancelled) {
        return;
      }

      if (!response.ok) {
        setError(data.error ?? "Failed to load license");
        return;
      }

      setLicense(data.license);
      setTotalSessions(data.totalSessions ?? 0);
      setRobloxUser(data.robloxUser ?? null);
    }

    void loadLicense();

    return () => {
      cancelled = true;
    };
  }, [licenseId, reloadKey]);

  async function revokeLicense() {
    const csrfCookie = getCookie("leet_csrf");
    await fetch(`/api/admin/licenses/${licenseId}/revoke`, {
      method: "POST",
      headers: {
        ...(csrfCookie ? { "x-csrf-token": csrfCookie } : {}),
      },
    });
    setReloadKey((key) => key + 1);
  }

  async function reenableLicense() {
    const csrfCookie = getCookie("leet_csrf");
    await fetch(`/api/admin/licenses/${licenseId}/reenable`, {
      method: "POST",
      headers: {
        ...(csrfCookie ? { "x-csrf-token": csrfCookie } : {}),
      },
    });
    setReloadKey((key) => key + 1);
  }

  async function resetHwid() {
    const csrfCookie = getCookie("leet_csrf");
    const response = await fetch(`/api/admin/licenses/${licenseId}/reset-hwid`, {
      method: "POST",
      headers: {
        ...(csrfCookie ? { "x-csrf-token": csrfCookie } : {}),
      },
    });

    if (!response.ok) {
      const data = await response.json().catch(() => null);
      setError(data?.error ?? "Failed to reset HWID");
    }

    setReloadKey((key) => key + 1);
  }

  if (error) {
    return <p className="text-sm text-red-300">{error}</p>;
  }

  if (!license) {
    return <p className="text-sm text-zinc-400">Loading license...</p>;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <Link href="/dashboard/licenses" className="text-sm text-zinc-400 hover:text-zinc-200">
            ← Back to licenses
          </Link>
          <h1 className="mt-2 text-2xl font-semibold text-white">License detail</h1>
        </div>
        <div className="flex gap-2">
          {license.activation ? (
            <button
              type="button"
              onClick={() => void resetHwid()}
              className="rounded-md border border-amber-800 px-4 py-2 text-sm text-amber-300 hover:bg-amber-950/30"
            >
              Reset HWID
            </button>
          ) : null}
          {license.status !== "REVOKED" ? (
            <button
              type="button"
              onClick={() => void revokeLicense()}
              className="rounded-md border border-red-900 px-4 py-2 text-sm text-red-300 hover:bg-red-950/30"
            >
              Revoke
            </button>
          ) : (
            <button
              type="button"
              onClick={() => void reenableLicense()}
              className="rounded-md border border-emerald-900 px-4 py-2 text-sm text-emerald-300 hover:bg-emerald-950/30"
            >
              Re-enable
            </button>
          )}
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <div className="rounded-xl border border-zinc-800 bg-zinc-950 p-6">
          <h2 className="text-lg font-medium text-white">License</h2>
          <dl className="mt-4 space-y-3 text-sm">
            <div>
              <dt className="text-zinc-400">License key</dt>
              <dd className="mt-1">
                {license.key ? (
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-base text-emerald-300">{license.key}</span>
                    <CopyButton value={license.key} label="Copy key" />
                  </div>
                ) : (
                  <span className="text-zinc-500">
                    Not recoverable (generated before key storage was enabled)
                  </span>
                )}
              </dd>
            </div>
            <div>
              <dt className="text-zinc-400">ID</dt>
              <dd className="font-mono text-zinc-200">{license.id}</dd>
            </div>
            <div>
              <dt className="text-zinc-400">Status</dt>
              <dd className="text-zinc-200">{license.status}</dd>
            </div>
            <div>
              <dt className="text-zinc-400">Created</dt>
              <dd className="text-zinc-200">{new Date(license.createdAt).toLocaleString()}</dd>
            </div>
            <div>
              <dt className="text-zinc-400">Activated</dt>
              <dd className="text-zinc-200">
                {license.activatedAt
                  ? new Date(license.activatedAt).toLocaleString()
                  : "—"}
              </dd>
            </div>
            <div>
              <dt className="text-zinc-400">Expires</dt>
              <dd className="text-zinc-200">
                {license.expiresAt
                  ? new Date(license.expiresAt).toLocaleString()
                  : "Never"}
              </dd>
            </div>
            <div>
              <dt className="text-zinc-400">Alias</dt>
              <dd className="text-zinc-200">{license.alias ?? "—"}</dd>
            </div>
            <div>
              <dt className="text-zinc-400">Note</dt>
              <dd className="text-zinc-200">{license.note ?? "—"}</dd>
            </div>
          </dl>
        </div>

        <div className="rounded-xl border border-zinc-800 bg-zinc-950 p-6">
          <h2 className="text-lg font-medium text-white">Roblox account</h2>
          {robloxUser ? (
            <div className="mt-4 flex items-center gap-4">
              {robloxUser.avatarUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={robloxUser.avatarUrl}
                  alt={`${robloxUser.username} avatar`}
                  className="h-16 w-16 rounded-full border border-zinc-800"
                />
              ) : (
                <div className="flex h-16 w-16 items-center justify-center rounded-full border border-zinc-800 bg-zinc-900 text-xl text-zinc-500">
                  ?
                </div>
              )}
              <div className="space-y-1 text-sm">
                <p className="font-medium text-white">
                  {robloxUser.displayName}
                </p>
                <a
                  href={`https://www.roblox.com/users/${robloxUser.userId}/profile`}
                  target="_blank"
                  rel="noreferrer"
                  className="block font-mono text-violet-400 hover:text-violet-300"
                >
                  @{robloxUser.username}
                </a>
                <p className="text-zinc-500">ID: {robloxUser.userId}</p>
              </div>
            </div>
          ) : license.activation?.metadata ? (
            (() => {
              const metadata = license.activation!.metadata as {
                robloxUsername?: unknown;
              } | null;

              return typeof metadata?.robloxUsername === "string" ? (
                <p className="mt-4 text-sm text-zinc-400">
                  Roblox user: {metadata.robloxUsername} (profile lookup
                  unavailable)
                </p>
              ) : (
                <p className="mt-4 text-sm text-zinc-400">
                  No Roblox account attached.
                </p>
              );
            })()
          ) : (
            <p className="mt-4 text-sm text-zinc-400">
              No Roblox account attached.
            </p>
          )}
        </div>

        <div className="rounded-xl border border-zinc-800 bg-zinc-950 p-6">
          <h2 className="text-lg font-medium text-white">Activation</h2>
          {license.activation ? (
            <dl className="mt-4 space-y-3 text-sm">
              <div>
                <dt className="text-zinc-400">HWID</dt>
                <dd className="font-mono text-zinc-200">{license.activation.hwidDisplay}</dd>
              </div>
              <div>
                <dt className="text-zinc-400">First IP</dt>
                <dd className="text-zinc-200">{license.activation.firstIp ?? "—"}</dd>
              </div>
              <div>
                <dt className="text-zinc-400">Last IP</dt>
                <dd className="text-zinc-200">{license.activation.lastIp ?? "—"}</dd>
              </div>
              <div>
                <dt className="text-zinc-400">Last seen</dt>
                <dd className="text-zinc-200">
                  {new Date(license.activation.lastSeen).toLocaleString()}
                </dd>
              </div>
              <div>
                <dt className="text-zinc-400">Client version</dt>
                <dd className="text-zinc-200">{license.activation.clientVersion ?? "—"}</dd>
              </div>
            </dl>
          ) : (
            <p className="mt-4 text-sm text-zinc-400">Not activated yet.</p>
          )}
        </div>
      </div>

      <div className="rounded-xl border border-zinc-800 bg-zinc-950 p-6">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-medium text-white">Sessions</h2>
          <span className="text-sm text-zinc-400">
            Total sessions: {totalSessions}
          </span>
        </div>
        <div className="mt-4 overflow-x-auto">
          <table className="min-w-full text-left text-sm">
            <thead className="text-zinc-400">
              <tr>
                <th className="px-2 py-2">Created</th>
                <th className="px-2 py-2">Expires</th>
                <th className="px-2 py-2">Last seen</th>
                <th className="px-2 py-2">Status</th>
              </tr>
            </thead>
            <tbody>
              {license.sessions.map((session) => (
                <tr key={session.id} className="border-t border-zinc-900">
                  <td className="px-2 py-2 text-zinc-300">
                    {new Date(session.createdAt).toLocaleString()}
                  </td>
                  <td className="px-2 py-2 text-zinc-300">
                    {new Date(session.expiresAt).toLocaleString()}
                  </td>
                  <td className="px-2 py-2 text-zinc-300">
                    {new Date(session.lastSeen).toLocaleString()}
                  </td>
                  <td className="px-2 py-2 text-zinc-300">
                    {session.revoked
                      ? "Revoked"
                      : session.active
                        ? "Active"
                        : "Expired"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="rounded-xl border border-zinc-800 bg-zinc-950 p-6">
        <h2 className="text-lg font-medium text-white">Audit log</h2>
        <div className="mt-4 space-y-3">
          {license.auditLogs.map((log) => (
            <div key={log.id} className="rounded-lg border border-zinc-900 px-4 py-3 text-sm">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <span className="font-medium text-zinc-200">{log.event}</span>
                <span className="text-zinc-500">
                  {new Date(log.createdAt).toLocaleString()}
                </span>
              </div>
              {log.ip ? (
                <p className="mt-1 text-zinc-400">IP: {log.ip}</p>
              ) : null}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
