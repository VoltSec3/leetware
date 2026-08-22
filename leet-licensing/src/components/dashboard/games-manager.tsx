"use client";

import { useEffect, useState } from "react";

import { Panel } from "@/components/site/panel";

type GameRow = {
  id: string;
  gameId: string;
  name: string;
  moduleKey: string;
  delivery: string;
  scriptUrl: string | null;
  enabled: boolean;
  autoRegistered: boolean;
  hasPayloadSource: boolean;
  lastSeenAt: string | null;
  updatedAt: string;
};

function getCookie(name: string) {
  const match = document.cookie.match(new RegExp(`(?:^|; )${name}=([^;]*)`));
  return match ? decodeURIComponent(match[1]!) : null;
}

function csrfHeaders(): Record<string, string> {
  const csrfCookie = getCookie("leet_csrf");
  return csrfCookie ? { "x-csrf-token": csrfCookie } : {};
}

export function GamesManager() {
  const [games, setGames] = useState<GameRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editing, setEditing] = useState<GameRow | null>(null);
  const [payloadDraft, setPayloadDraft] = useState("");

  const [form, setForm] = useState({
    gameId: "",
    name: "",
    moduleKey: "",
    delivery: "direct",
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
        delivery: form.delivery,
        scriptUrl: form.scriptUrl || "",
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      setFormError(data.error ?? "Failed to register game");
      return;
    }

    setForm({ gameId: "", name: "", moduleKey: "", delivery: "direct", scriptUrl: "" });
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

  function openEditor(game: GameRow) {
    setEditing(game);
    setPayloadDraft("");
    setError(null);
  }

  async function savePayloadSource(clear = false) {
    if (!editing) {
      return;
    }

    const ok = await patchGame(editing.id, {
      payloadSource: clear ? "" : payloadDraft,
    });

    if (ok) {
      setEditing(null);
    }
  }

  return (
    <div className="space-y-5">
      <Panel>
        <div className="p-4">
          <h2 className="lw-title">register a game</h2>
          <p className="lw-muted mt-1 text-[12px]">
            registration is optional — games also self-register the first time a
            loader runs them. use this to control delivery mode or upload gated
            payloads.
          </p>

          <form onSubmit={registerGame} className="mt-3 grid gap-3 md:grid-cols-6">
            <label className="space-y-1">
              <span className="lw-label">gameid</span>
              <input
                required
                value={form.gameId}
                onChange={(event) => setForm({ ...form, gameId: event.target.value })}
                placeholder="155615604"
                className="lw-input"
              />
            </label>

            <label className="space-y-1 md:col-span-2">
              <span className="lw-label">name</span>
              <input
                required
                value={form.name}
                onChange={(event) => setForm({ ...form, name: event.target.value })}
                placeholder="Prison Life"
                className="lw-input"
              />
            </label>

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

            <label className="space-y-1 md:col-span-2">
              <span className="lw-label">script url (direct mode)</span>
              <input
                value={form.scriptUrl}
                onChange={(event) => setForm({ ...form, scriptUrl: event.target.value })}
                placeholder="https://raw.githubusercontent.com/..."
                className="lw-input"
              />
            </label>

            <div className="md:col-span-6">
              <button type="submit" className="lw-btn lw-btn-accent">
                save game
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
          <p className="lw-muted p-4 text-[12px]">loading games...</p>
        ) : (
          <div className="overflow-x-auto p-2">
            <table className="lw-table">
              <thead>
                <tr>
                  <th>name</th>
                  <th>gameid</th>
                  <th>module key</th>
                  <th>delivery</th>
                  <th>flags</th>
                  <th>last seen</th>
                  <th>actions</th>
                </tr>
              </thead>
              <tbody>
                {games.map((game) => (
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
                        : "—"}
                    </td>
                    <td>
                      <div className="flex flex-wrap gap-2">
                        <button
                          type="button"
                          onClick={() => openEditor(game)}
                          className="hover:text-[#cce335]"
                        >
                          payload
                        </button>
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
                        <button
                          type="button"
                          onClick={() => void deleteGame(game.id)}
                          className="lw-dim hover:text-[#e05555]"
                        >
                          delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {games.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="lw-dim py-4 text-center">
                      no games registered yet.
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
              <h2 className="lw-title">payload source — {editing.name}</h2>
              <button
                type="button"
                onClick={() => setEditing(null)}
                className="lw-muted hover:text-[#cccccc]"
              >
                close
              </button>
            </div>
            <p className="lw-muted mt-1 text-[12px]">
              served as plain lua source by{" "}
              <code className="lw-mono">/api/payload/{editing.moduleKey}</code>{" "}
              to authenticated sessions only.
            </p>

            <textarea
              value={payloadDraft}
              onChange={(event) => setPayloadDraft(event.target.value)}
              rows={14}
              spellCheck={false}
              placeholder="-- paste obfuscated or plain lua source here..."
              className="lw-input lw-mono mt-3"
            />

            <div className="mt-3 flex gap-2">
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
            </div>
          </div>
        </Panel>
      ) : null}
    </div>
  );
}
