"use client";

import { useEffect, useState } from "react";

import { Panel } from "@/components/site/panel";

type GameRow = {
  id: string;
  gameId: string;
  name: string;
  moduleKey: string;
  delivery: string;
  kind: string;
  locked: boolean;
  scriptUrl: string | null;
  enabled: boolean;
  autoRegistered: boolean;
  hasPayloadSource: boolean;
  lastSeenAt: string | null;
  updatedAt: string;
};

type GameKind = "game" | "module";

function draftKey(id: string) {
  return `leet_payload_draft_${id}`;
}

function snapshotKey(id: string) {
  return `leet_payload_snapshot_${id}`;
}

function getCookie(name: string) {
  const match = document.cookie.match(new RegExp(`(?:^|; )${name}=([^;]*)`));
  return match ? decodeURIComponent(match[1]!) : null;
}

function csrfHeaders(): Record<string, string> {
  const csrfCookie = getCookie("leet_csrf");
  return csrfCookie ? { "x-csrf-token": csrfCookie } : {};
}

export function GamesManager() {
  const [kind, setKind] = useState<GameKind>("game");
  const [games, setGames] = useState<GameRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editing, setEditing] = useState<GameRow | null>(null);
  const [editingMode, setEditingMode] = useState<"payload" | "url" | null>(null);
  const [payloadDraft, setPayloadDraft] = useState("");
  const [payloadSnapshot, setPayloadSnapshot] = useState("");
  const [urlDraft, setUrlDraft] = useState("");

  const [form, setForm] = useState({
    gameId: "",
    name: "",
    moduleKey: "",
    delivery: "direct",
    kind: "game" as GameKind,
    scriptUrl: "",
  });
  const [formError, setFormError] = useState<string | null>(null);

  async function loadGames() {
    const response = await fetch("/api/admin/games");
    const data = await response.json();

    if (!response.ok) {
      setError(data.error ?? "Failed to load games");
      return;
    }

    setGames(data.games ?? []);
  }

  useEffect(() => {
    let cancelled = false;

    async function load() {
      const response = await fetch("/api/admin/games");
      const data = await response.json();

      if (cancelled) {
        return;
      }

      if (!response.ok) {
        setError(data.error ?? "Failed to load games");
        setLoading(false);
        return;
      }

      setGames(data.games ?? []);
      setLoading(false);
    }

    void load();

    return () => {
      cancelled = true;
    };
  }, []);

  async function registerGame(event: React.FormEvent) {
    event.preventDefault();
    setFormError(null);

    const isModule = form.kind === "module";

    const response = await fetch("/api/admin/games", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...csrfHeaders(),
      },
      body: JSON.stringify({
        gameId: form.gameId,
        name: form.name,
        moduleKey: form.moduleKey || undefined,
        delivery: isModule ? "api" : form.delivery,
        kind: form.kind,
        scriptUrl: !isModule && form.delivery === "direct" ? form.scriptUrl || "" : "",
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      setFormError(data.error ?? "Failed to register game");
      return;
    }

    setForm({ gameId: "", name: "", moduleKey: "", delivery: "direct", kind: "game", scriptUrl: "" });
    await loadGames();
  }

  async function patchGame(id: string, body: Record<string, unknown>) {
    const response = await fetch(`/api/admin/games/${id}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        ...csrfHeaders(),
      },
      body: JSON.stringify(body),
    });

    const data = await response.json();

    if (!response.ok) {
      setError(data.error ?? "Update failed");
      return false;
    }

    await loadGames();
    return true;
  }

  async function deleteGame(id: string) {
    const response = await fetch(`/api/admin/games/${id}`, {
      method: "DELETE",
      headers: csrfHeaders(),
    });

    if (!response.ok) {
      const data = await response.json();
      setError(data.error ?? "Delete failed");
      return;
    }

    if (editing?.id === id) {
      setEditing(null);
    }

    await loadGames();
  }

  async function openPayload(game: GameRow) {
    setEditing(game);
    setEditingMode("payload");
    setError(null);

    const dKey = draftKey(game.id);
    const sKey = snapshotKey(game.id);
    const savedDraft = localStorage.getItem(dKey);

    let current = savedDraft;

    if (current === null) {
      // Fetch the actual stored payload so the editor opens with the source
      // that is currently live. Cache it as the "last good" snapshot.
      try {
        const res = await fetch(`/api/admin/games/${game.id}`);
        const data = await res.json();
        current = data?.game?.payloadSource ?? "";
      } catch {
        current = "";
      }

      localStorage.setItem(sKey, current ?? "");
    }

    setPayloadDraft(current ?? "");
    setPayloadSnapshot(localStorage.getItem(sKey) ?? "");
  }

  function onPayloadChange(value: string) {
    setPayloadDraft(value);

    if (editing) {
      localStorage.setItem(draftKey(editing.id), value);
    }
  }

  async function savePayloadSource(clear = false) {
    if (!editing) {
      return;
    }

    const ok = await patchGame(editing.id, {
      payloadSource: clear ? "" : payloadDraft,
    });

    if (ok) {
      const sKey = snapshotKey(editing.id);
      const dKey = draftKey(editing.id);

      if (clear) {
        localStorage.removeItem(sKey);
        localStorage.removeItem(dKey);
        setPayloadSnapshot("");
      } else {
        localStorage.setItem(sKey, payloadDraft);
        localStorage.removeItem(dKey);
        setPayloadSnapshot(payloadDraft);
      }

      setEditing(null);
    }
  }

  function restoreSnapshot() {
    setPayloadDraft(payloadSnapshot);

    if (editing) {
      localStorage.setItem(draftKey(editing.id), payloadSnapshot);
    }
  }

  function openUrl(game: GameRow) {
    setEditing(game);
    setEditingMode("url");
    setUrlDraft(game.scriptUrl ?? "");
    setError(null);
  }

  async function saveUrl(clear = false) {
    if (!editing) {
      return;
    }

    const ok = await patchGame(editing.id, {
      scriptUrl: clear ? "" : urlDraft,
    });

    if (ok) {
      setEditing(null);
    }
  }

  const visibleGames = games.filter((game) => (game.kind ?? "game") === kind);

  return (
    <div className="space-y-5">
      <Panel>
        <div className="flex flex-wrap gap-2 border-b border-zinc-800 p-4">
          {(["game", "module"] as GameKind[]).map((value) => (
            <button
              key={value}
              type="button"
              onClick={() => setKind(value)}
              className={
                kind === value
                  ? "lw-btn lw-btn-accent"
                  : "lw-btn lw-btn-ghost"
              }
            >
              {value === "game" ? "games" : "modules"}
            </button>
          ))}
        </div>

        <div className="p-4">
          <h2 className="lw-title">
            register a {kind === "module" ? "module" : "game"}
          </h2>
          <p className="lw-muted mt-1 text-[12px]">
            {kind === "module"
              ? "modules are always api-delivered and pulled by the loader. add a module here, then edit its payload below. the five built-in modules are locked and cannot be removed."
              : "registration is optional - games also self-register the first time a loader runs them. use this to control delivery mode or upload gated payloads."}
          </p>

          <form onSubmit={registerGame} className="mt-3 grid gap-3 md:grid-cols-6">
            <label className="space-y-1">
              <span className="lw-label">
                {kind === "module" ? "module id" : "gameid"}
              </span>
              <input
                required
                value={form.gameId}
                onChange={(event) => setForm({ ...form, gameId: event.target.value })}
                placeholder={kind === "module" ? "esp" : "155615604"}
                className="lw-input"
              />
            </label>

            <label className="space-y-1 md:col-span-2">
              <span className="lw-label">name</span>
              <input
                required
                value={form.name}
                onChange={(event) => setForm({ ...form, name: event.target.value })}
                placeholder={kind === "module" ? "ESP" : "Prison Life"}
                className="lw-input"
              />
            </label>

            <label className="space-y-1">
              <span className="lw-label">kind</span>
              <select
                value={form.kind}
                onChange={(event) => setForm({ ...form, kind: event.target.value as GameKind })}
                className="lw-select"
              >
                <option value="game">game</option>
                <option value="module">module</option>
              </select>
            </label>

            {form.kind === "module" ? (
              <p className="lw-muted md:col-span-2 text-center text-[12px]">
                api delivery - set the script via the payload editor after saving.
              </p>
            ) : form.delivery === "direct" ? (
              <label className="space-y-1 md:col-span-2">
                <span className="lw-label">script url</span>
                <input
                  value={form.scriptUrl}
                  onChange={(event) => setForm({ ...form, scriptUrl: event.target.value })}
                  placeholder="https://raw.githubusercontent.com/..."
                  className="lw-input"
                />
              </label>
            ) : (
              <p className="lw-muted md:col-span-2 text-center text-[12px]">
                api delivery - set the script via the payload editor after saving.
              </p>
            )}

            {form.kind !== "module" ? (
              <label className="space-y-1">
                <span className="lw-label">delivery</span>
                <select
                  value={form.delivery}
                  onChange={(event) => setForm({ ...form, delivery: event.target.value })}
                  className="lw-select"
                >
                  <option value="direct">direct</option>
                  <option value="api">api</option>
                </select>
              </label>
            ) : null}

            <div className="md:col-span-6">
              <button type="submit" className="lw-btn lw-btn-accent">
                save {kind === "module" ? "module" : "game"}
              </button>
            </div>
          </form>

          {formError ? (
            <p className="lw-error mt-3 text-[12px]">{formError}</p>
          ) : null}
        </div>
      </Panel>

      {error ? <p className="lw-error">{error}</p> : null}

      <Panel>
        {loading ? (
          <p className="lw-muted p-4 text-[12px]">loading {kind}s...</p>
        ) : (
          <div className="overflow-x-auto p-2">
            <table className="lw-table">
              <thead>
                <tr>
                  <th>name</th>
                  <th>{kind === "module" ? "module id" : "gameid"}</th>
                  <th>module key</th>
                  <th>delivery</th>
                  <th>flags</th>
                  <th>last seen</th>
                  <th>actions</th>
                </tr>
              </thead>
              <tbody>
                {visibleGames.map((game) => (
                  <tr key={game.id}>
                    <td>{game.name}</td>
                    <td className="lw-mono">{game.gameId}</td>
                    <td className="lw-mono">{game.moduleKey}</td>
                    <td>{game.delivery}</td>
                    <td>
                      <div className="flex flex-wrap gap-1">
                        {!game.enabled ? (
                          <span className="lw-pill lw-pill-red">disabled</span>
                        ) : null}
                        {game.locked ? (
                          <span className="lw-pill lw-pill-amber">locked</span>
                        ) : null}
                        {game.autoRegistered ? (
                          <span className="lw-pill lw-pill-blue">auto</span>
                        ) : null}
                        {game.hasPayloadSource ? (
                          <span className="lw-pill lw-pill-green">payload</span>
                        ) : null}
                      </div>
                    </td>
                    <td>
                      {game.lastSeenAt
                        ? new Date(game.lastSeenAt).toLocaleString()
                        : "-"}
                    </td>
                    <td>
                      <div className="flex flex-wrap gap-2">
                        {game.delivery === "api" ? (
                          <button
                            type="button"
                            onClick={() => void openPayload(game)}
                            className="hover:text-[var(--lw-accent)]"
                          >
                            payload
                          </button>
                        ) : (
                          <button
                            type="button"
                            onClick={() => openUrl(game)}
                            className="hover:text-[var(--lw-accent)]"
                          >
                            edit url
                          </button>
                        )}
                        <button
                          type="button"
                          onClick={() =>
                            void patchGame(game.id, { enabled: !game.enabled })
                          }
                          className={
                            game.enabled
                              ? "text-[#e05555] hover:text-[#ff7777]"
                              : "text-[#57d977] hover:text-[#7de895]"
                          }
                        >
                          {game.enabled ? "disable" : "enable"}
                        </button>
                        {game.locked ? (
                          <span className="lw-dim" title="protected entry">
                            locked
                          </span>
                        ) : (
                          <button
                            type="button"
                            onClick={() => void deleteGame(game.id)}
                            className="lw-dim hover:text-[#e05555]"
                          >
                            delete
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
                {visibleGames.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="lw-dim py-4 text-center">
                      no {kind}s registered yet.
                    </td>
                  </tr>
                ) : null}
              </tbody>
            </table>
          </div>
        )}
      </Panel>

      {editing ? (
        <Panel>
          <div className="p-4">
            <div className="flex items-center justify-between gap-3">
              <h2 className="lw-title">
                {editingMode === "url"
                  ? `script url - ${editing.name}`
                  : `payload source - ${editing.name}`}
              </h2>
              <button
                type="button"
                onClick={() => setEditing(null)}
                className="lw-muted hover:text-[var(--lw-text)]"
              >
                close
              </button>
            </div>

            {editingMode === "url" ? (
              <>
                <p className="lw-muted mt-1 text-[12px]">
                  served directly by the loader. must be https and hosted on an
                  allowed domain (github raw, gist, leet.voltsec.xyz).
                </p>
                <input
                  value={urlDraft}
                  onChange={(event) => setUrlDraft(event.target.value)}
                  placeholder="https://raw.githubusercontent.com/..."
                  className="lw-input mt-3"
                />
                <div className="mt-3 flex gap-2">
                  <button
                    type="button"
                    onClick={() => void saveUrl(false)}
                    disabled={!urlDraft.trim()}
                    className="lw-btn lw-btn-accent"
                  >
                    save url
                  </button>
                  {editing.scriptUrl ? (
                    <button
                      type="button"
                      onClick={() => void saveUrl(true)}
                      className="lw-btn lw-btn-danger"
                    >
                      remove url
                    </button>
                  ) : null}
                </div>
              </>
            ) : (
              <>
                <p className="lw-muted mt-1 text-[12px]">
                  served as plain lua source by{" "}
                  <code className="lw-mono">
                    /api/payload/{editing.moduleKey}
                  </code>{" "}
                  to authenticated sessions only. your in-progress edit is saved
                  to this browser so it survives a refresh; the previous saved
                  version is kept as a safety snapshot.
                </p>

                <textarea
                  value={payloadDraft}
                  onChange={(event) => onPayloadChange(event.target.value)}
                  rows={14}
                  spellCheck={false}
                  placeholder="-- paste obfuscated or plain lua source here..."
                  className="lw-input lw-mono mt-3"
                />

                <div className="mt-3 flex flex-wrap gap-2">
                  <button
                    type="button"
                    onClick={() => void savePayloadSource(false)}
                    disabled={!payloadDraft.trim()}
                    className="lw-btn lw-btn-accent"
                  >
                    save payload
                  </button>
                  {editing.hasPayloadSource ? (
                    <button
                      type="button"
                      onClick={() => void savePayloadSource(true)}
                      className="lw-btn lw-btn-danger"
                    >
                      remove payload
                    </button>
                  ) : null}
                  {payloadSnapshot.length > 0 ? (
                    <button
                      type="button"
                      onClick={restoreSnapshot}
                      className="lw-btn lw-btn-ghost"
                      title="restore the last saved version"
                    >
                      restore previous
                    </button>
                  ) : null}
                </div>

                {payloadSnapshot.length > 0 ? (
                  <details className="mt-4">
                    <summary className="lw-muted cursor-pointer text-[12px]">
                      previous saved version ({payloadSnapshot.length} chars)
                    </summary>
                    <pre className="lw-input lw-mono mt-2 max-h-48 overflow-auto text-[11px]">
                      {payloadSnapshot}
                    </pre>
                  </details>
                ) : null}
              </>
            )}
          </div>
        </Panel>
      ) : null}
    </div>
  );
}
