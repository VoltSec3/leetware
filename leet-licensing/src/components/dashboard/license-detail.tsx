"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

import { CopyButton } from "@/components/dashboard/copy-button";
import { Panel, Rainbow, StatusPill } from "@/components/site/panel";
import { api } from "@/lib/client";
import { TIER_NAMES, TIERS, formatCooldown } from "@/lib/tiers";

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
  actorType?: string | null;
  actorName?: string | null;
  ip: string | null;
  metadata: unknown;
  createdAt: string;
};

type RobloxAccountRow = {
  id: string;
  robloxUserId: string;
  username: string | null;
  displayName: string | null;
  avatarUrl: string | null;
  verification: string;
  addedAt: string;
  lastSeen: string | null;
};

type LicenseDetail = {
  id: string;
  key: string | null;
  status: string;
  note: string | null;
  alias: string | null;
  tier: string;
  userId: string | null;
  user: { id: string; username: string } | null;
  createdAt: string;
  expiresAt: string | null;
  activatedAt: string | null;
  robloxAccounts: RobloxAccountRow[];
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

type LicenseDetailProps = {
  licenseId: string;
};

export function LicenseDetailPanel({ licenseId }: LicenseDetailProps) {
  const [license, setLicense] = useState<LicenseDetail | null>(null);
  const [totalSessions, setTotalSessions] = useState(0);
  const [robloxUser, setRobloxUser] = useState<RobloxUserInfo | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  const [extendDays, setExtendDays] = useState("30");
  const [tierValue, setTierValue] = useState("");
  const [assignUsername, setAssignUsername] = useState("");

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
      setTierValue(data.license?.tier ?? "");
    }

    void loadLicense();

    return () => {
      cancelled = true;
    };
  }, [licenseId, reloadKey]);

  async function action(path: string, body?: unknown) {
    setError(null);
    setNotice(null);

    const result = await api(`/api/admin/licenses/${licenseId}${path}`, {
      method: "POST",
      ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
    });

    if (!result.ok) {
      setError(
        typeof result.data.error === "string" ? result.data.error : "Action failed",
      );
      return false;
    }

    setReloadKey((key) => key + 1);
    return true;
  }

  async function removeRobloxAccount(accountId: string) {
    setError(null);

    const result = await api(
      `/api/admin/licenses/${licenseId}/roblox-accounts/${accountId}`,
      { method: "DELETE" },
    );

    if (!result.ok) {
      setError(
        typeof result.data.error === "string"
          ? result.data.error
          : "Failed to remove account",
      );
      return;
    }

    setReloadKey((key) => key + 1);
  }

  if (error && !license) {
    return <p className="lw-error">{error}</p>;
  }

  if (!license) {
    return <p className="lw-muted">loading license...</p>;
  }

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <Link href="/dashboard/licenses" className="lw-muted hover:text-[#cce335]">
          ← back to licenses
        </Link>
        <div className="flex flex-wrap gap-2">
          {license.activation ? (
            <button
              type="button"
              className="lw-btn lw-btn-danger"
              onClick={() =>
                void action("/reset-hwid").then((ok) => {
                  if (ok) setNotice("hwid reset");
                })
              }
            >
              reset hwid
            </button>
          ) : null}
          <button
            type="button"
            className="lw-btn"
            onClick={() =>
              void action("/force-logout").then((ok) => {
                if (ok) setNotice("loader sessions revoked");
              })
            }
          >
            force logout loader
          </button>
          {license.status === "SUSPENDED" ? (
            <button
              type="button"
              className="lw-btn lw-btn-accent"
              onClick={() =>
                void action("/suspend", { lift: true }).then((ok) => {
                  if (ok) setNotice("suspension lifted");
                })
              }
            >
              unsuspend
            </button>
          ) : license.status !== "REVOKED" ? (
            <button
              type="button"
              className="lw-btn lw-btn-accent"
              onClick={() =>
                void action("/suspend", { reason: "suspended via admin panel" }).then(
                  (ok) => {
                    if (ok) setNotice("license suspended");
                  },
                )
              }
            >
              suspend
            </button>
          ) : null}
          {license.status !== "REVOKED" ? (
            <button
              type="button"
              className="lw-btn lw-btn-danger"
              onClick={() =>
                void action("/revoke").then((ok) => {
                  if (ok) setNotice("license revoked");
                })
              }
            >
              revoke
            </button>
          ) : (
            <button
              type="button"
              className="lw-btn"
              onClick={() =>
                void action("/reenable").then((ok) => {
                  if (ok) setNotice("license re-enabled");
                })
              }
            >
              re-enable
            </button>
          )}
        </div>
      </div>

      {error && (
        <p className="lw-error text-[12px]" role="alert">
          {error}
        </p>
      )}
      {notice && !error && (
        <p className="lw-success text-[12px]">{notice}</p>
      )}

      <div className="grid gap-5 lg:grid-cols-2">
        <Panel>
          <div className="p-4">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="lw-title">license</h2>
              <StatusPill value={license.status} />
            </div>
            <dl className="space-y-2 text-[12px]">
              <Row label="key">
                {license.key ? (
                  <span className="flex items-center gap-2">
                    <span className="lw-mono">{license.key}</span>
                    <CopyButton value={license.key} label="copy" />
                  </span>
                ) : (
                  "not recoverable"
                )}
              </Row>
              <Row label="id">
                <span className="lw-mono">{license.id}</span>
              </Row>
              <Row label="alias">{license.alias ?? "—"}</Row>
              <Row label="note">{license.note ?? "—"}</Row>
              <Row label="tier">{license.tier ?? "standard"}</Row>
              <Row label="created">
                {new Date(license.createdAt).toLocaleString()}
              </Row>
              <Row label="activated">
                {license.activatedAt
                  ? new Date(license.activatedAt).toLocaleString()
                  : "—"}
              </Row>
              <Row label="expires">
                {license.expiresAt
                  ? new Date(license.expiresAt).toLocaleString()
                  : "never"}
              </Row>
            </dl>

            <div className="mt-4 space-y-3 border-t border-[#282828] pt-3">
              <div className="flex items-center gap-2">
                <span className="lw-muted w-16 text-[12px]">extend</span>
                <input
                  className="lw-input max-w-[90px]"
                  value={extendDays}
                  onChange={(event) => setExtendDays(event.target.value)}
                  inputMode="numeric"
                />
                <span className="lw-dim text-[12px]">days</span>
                <button
                  type="button"
                  className="lw-btn lw-btn-sm ml-auto"
                  onClick={() =>
                    void action("/extend", { days: Number(extendDays) }).then(
                      (ok) => {
                        if (ok) setNotice(`extended by ${extendDays} days`);
                      },
                    )
                  }
                >
                  apply
                </button>
              </div>

              <div className="flex items-center gap-2">
                <span className="lw-muted w-16 text-[12px]">tier</span>
                <select
                  className="lw-select max-w-[140px]"
                  value={tierValue}
                  onChange={(event) => setTierValue(event.target.value)}
                >
                  {TIER_NAMES.map((name) => (
                    <option key={name} value={name}>
                      {name}
                    </option>
                  ))}
                </select>
                <button
                  type="button"
                  className="lw-btn lw-btn-sm ml-auto"
                  onClick={() =>
                    void action("/tier", { tier: tierValue }).then((ok) => {
                      if (ok) setNotice(`tier set to ${tierValue}`);
                    })
                  }
                >
                  apply
                </button>
              </div>

              <p className="lw-dim text-[11px]">
                {TIER_NAMES.map((name) => {
                  const perks = TIERS[name];
                  return `${name}: hwid reset /${formatCooldown(perks.hwidResetCooldownSeconds)}, ${perks.maxRobloxAccounts ?? "∞"} roblox slots`;
                }).join(" · ")}
              </p>
            </div>
          </div>
        </Panel>

        <Panel>
          <div className="p-4">
            <h2 className="lw-title mb-3">site account</h2>
            {license.user ? (
              <div className="space-y-2 text-[12px]">
                <div className="flex items-center gap-2">
                  <Link
                    href={`/dashboard/users/${license.user.id}`}
                    className="font-bold hover:text-[#cce335]"
                  >
                    {license.user.username}
                  </Link>
                  <span className="lw-dim">(linked)</span>
                </div>
                <button
                  type="button"
                  className="lw-btn lw-btn-sm lw-btn-danger"
                  onClick={() =>
                    void action("/assign", { userId: null }).then((ok) => {
                      if (ok) setNotice("account unassigned");
                    })
                  }
                >
                  unassign account
                </button>
              </div>
            ) : (
              <div className="space-y-2 text-[12px]">
                <p className="lw-muted">no site account linked.</p>
                <div className="flex items-center gap-2">
                  <input
                    className="lw-input max-w-[200px]"
                    placeholder="username to assign"
                    value={assignUsername}
                    onChange={(event) => setAssignUsername(event.target.value)}
                  />
                  <button
                    type="button"
                    className="lw-btn lw-btn-sm"
                    onClick={async () => {
                      if (!assignUsername.trim()) {
                        return;
                      }

                      setError(null);

                      const searchResult = await api(
                        `/api/admin/users?search=${encodeURIComponent(assignUsername.trim())}`,
                      );

                      if (!searchResult.ok) {
                        setError("user lookup failed");
                        return;
                      }

                      const users = (searchResult.data.users ?? []) as Array<{
                        id: string;
                        username: string;
                      }>;

                      const match = users.find(
                        (candidate) =>
                          candidate.username.toLowerCase()
                          === assignUsername.trim().toLowerCase(),
                      );

                      if (!match) {
                        setError("no user found by that name");
                        return;
                      }

                      const ok = await action("/assign", { userId: match.id });

                      if (ok) {
                        setNotice(`assigned to ${match.username}`);
                        setAssignUsername("");
                      }
                    }}
                  >
                    assign
                  </button>
                </div>
              </div>
            )}

            <h2 className="lw-title mt-5 mb-2">activation</h2>
            {license.activation ? (
              <dl className="space-y-2 text-[12px]">
                <Row label="hwid">
                  <span className="lw-mono">{license.activation.hwidDisplay}</span>
                </Row>
                <Row label="first ip">{license.activation.firstIp ?? "—"}</Row>
                <Row label="last ip">{license.activation.lastIp ?? "—"}</Row>
                <Row label="last seen">
                  {new Date(license.activation.lastSeen).toLocaleString()}
                </Row>
                <Row label="client">{license.activation.clientVersion ?? "—"}</Row>
              </dl>
            ) : (
              <p className="lw-muted text-[12px]">not activated yet.</p>
            )}
          </div>
        </Panel>

        <Panel>
          <Rainbow />
          <div className="p-4">
            <h2 className="lw-title mb-1">roblox accounts</h2>
            <p className="lw-muted mb-3 text-[12px]">
              allowlist enforced by the backend on every loader request.
            </p>
            {robloxUser && license.robloxAccounts.length === 0 ? (
              <div className="mb-3 flex items-center gap-3 border border-[#282828] p-2">
                {robloxUser.avatarUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={robloxUser.avatarUrl}
                    alt={`${robloxUser.username} avatar`}
                    className="h-10 w-10"
                  />
                ) : null}
                <div className="text-[12px]">
                  <p>{robloxUser.displayName}</p>
                  <a
                    href={`https://www.roblox.com/users/${robloxUser.userId}/profile`}
                    target="_blank"
                    rel="noreferrer"
                    className="hover:text-[#cce335]"
                  >
                    @{robloxUser.username} ({robloxUser.userId})
                  </a>
                </div>
              </div>
            ) : null}
            {license.robloxAccounts.length > 0 ? (
              <table className="lw-table">
                <thead>
                  <tr>
                    <th>username</th>
                    <th>id</th>
                    <th>status</th>
                    <th>last seen</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {license.robloxAccounts.map((account) => (
                    <tr key={account.id}>
                      <td>{account.displayName ?? account.username ?? "-"}</td>
                      <td className="lw-mono">{account.robloxUserId}</td>
                      <td>
                        <StatusPill value={account.verification} />
                      </td>
                      <td>
                        {account.lastSeen
                          ? new Date(account.lastSeen).toLocaleString()
                          : "never"}
                      </td>
                      <td className="text-right">
                        <button
                          type="button"
                          className="lw-btn lw-btn-sm lw-btn-danger"
                          onClick={() => void removeRobloxAccount(account.id)}
                        >
                          remove
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <p className="lw-dim text-[12px]">
                no allowlisted accounts — unrestricted.
              </p>
            )}
          </div>
        </Panel>

        <Panel>
          <div className="p-4">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="lw-title">loader sessions</h2>
              <span className="lw-dim text-[12px]">total: {totalSessions}</span>
            </div>
            <table className="lw-table">
              <thead>
                <tr>
                  <th>created</th>
                  <th>expires</th>
                  <th>last seen</th>
                  <th>status</th>
                </tr>
              </thead>
              <tbody>
                {license.sessions.map((session) => (
                  <tr key={session.id}>
                    <td>{new Date(session.createdAt).toLocaleString()}</td>
                    <td>{new Date(session.expiresAt).toLocaleString()}</td>
                    <td>{new Date(session.lastSeen).toLocaleString()}</td>
                    <td>
                      {session.revoked ? (
                        <StatusPill value="REVOKED" />
                      ) : session.active ? (
                        <StatusPill value="ACTIVATED" />
                      ) : (
                        <StatusPill value="EXPIRED" />
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Panel>
      </div>

      <Panel>
        <div className="p-4">
          <h2 className="lw-title mb-3">audit log</h2>
          <ul className="text-[12px]">
            {license.auditLogs.map((log) => (
              <li
                key={log.id}
                className="flex flex-wrap items-baseline justify-between gap-x-3 border-b border-[#161616] py-1.5 last:border-b-0"
              >
                <span className="min-w-[160px]">{log.event}</span>
                <span className="lw-mono lw-dim">
                  {[log.actorName, log.ip].filter(Boolean).join(" · ") || "-"}
                </span>
                <span className="lw-muted ml-auto whitespace-nowrap">
                  {new Date(log.createdAt).toLocaleString()}
                </span>
              </li>
            ))}
          </ul>
        </div>
      </Panel>
    </div>
  );
}

function Row({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="flex justify-between gap-3">
      <dt className="lw-muted whitespace-nowrap">{label}</dt>
      <dd className="text-right break-all">{children}</dd>
    </div>
  );
}
