"use client";

import { useEffect, useState } from "react";

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
    <div className="space-y-6">
      <div className="rounded-xl border border-zinc-800 bg-zinc-950 p-6">
        <h2 className="text-lg font-medium text-white">Register a game</h2>
        <p className="mt-1 text-sm text-zinc-400">
          Registration is optional — games also self-register the first time a
          loader runs them. Use this to control delivery mode or upload gated
          payloads.
        </p>

        <form onSubmit={registerGame} className="mt-4 grid gap-4 md:grid-cols-6">
          <label className="space-y-2">
            <span className="text-sm text-zinc-300">GameId</span>
            <input
              required
              value={form.gameId}
              onChange={(event) => setForm({ ...form, gameId: event.target.value })}
              placeholder="155615604"
              className="w-full rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-white"
            />
          </label>

          <label className="space-y-2 md:col-span-2">
            <span className="text-sm text-zinc-300">Name</span>
            <input
              required
              value={form.name}
              onChange={(event) => setForm({ ...form, name: event.target.value })}
              placeholder="Prison Life"
              className="w-full rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-white"
            />
          </label>

          <label className="space-y-2">
            <span className="text-sm text-zinc-300">Delivery</span>
            <select
              value={form.delivery}
              onChange={(event) => setForm({ ...form, delivery: event.target.value })}
              className="w-full rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-white"
            >
              <option value="direct">direct</option>
              <option value="api">api</option>
            </select>
          </label>

          <label className="space-y-2 md:col-span-2">
            <span className="text-sm text-zinc-300">Script URL (direct mode)</span>
            <input
              value={form.scriptUrl}
              onChange={(event) => setForm({ ...form, scriptUrl: event.target.value })}
              placeholder="https://raw.githubusercontent.com/..."
              className="w-full rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-white"
            />
          </label>

          <div className="md:col-span-6">
            <button
              type="submit"
              className="rounded-md bg-violet-600 px-4 py-2 text-sm font-medium text-white hover:bg-violet-500"
            >
              Save game
            </button>
          </div>
        </form>

        {formError ? (
          <p className="mt-4 text-sm text-red-300">{formError}</p>
        ) : null}
      </div>

      {error ? <p className="text-sm text-red-300">{error}</p> : null}

      <div className="rounded-xl border border-zinc-800 bg-zinc-950">
        {loading ? (
          <p className="p-4 text-sm text-zinc-400">Loading games...</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead className="border-b border-zinc-800 text-zinc-400">
                <tr>
                  <th className="px-4 py-3 font-medium">Name</th>
                  <th className="px-4 py-3 font-medium">GameId</th>
                  <th className="px-4 py-3 font-medium">Module key</th>
                  <th className="px-4 py-3 font-medium">Delivery</th>
                  <th className="px-4 py-3 font-medium">Flags</th>
                  <th className="px-4 py-3 font-medium">Last seen</th>
                  <th className="px-4 py-3 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody>
                {games.map((game) => (
                  <tr key={game.id} className="border-b border-zinc-900/80">
                    <td className="px-4 py-3 text-zinc-200">{game.name}</td>
                    <td className="px-4 py-3 font-mono text-zinc-400">{game.gameId}</td>
                    <td className="px-4 py-3 font-mono text-zinc-400">{game.moduleKey}</td>
                    <td className="px-4 py-3 text-zinc-300">{game.delivery}</td>
                    <td className="px-4 py-3">
                      <div className="flex flex-wrap gap-1">
                        {!game.enabled ? (
                          <span className="rounded-full bg-red-950/60 px-2 py-0.5 text-xs text-red-300">
                            disabled
                          </span>
                        ) : null}
                        {game.autoRegistered ? (
                          <span className="rounded-full bg-sky-950/60 px-2 py-0.5 text-xs text-sky-300">
                            auto
                          </span>
                        ) : null}
                        {game.hasPayloadSource ? (
                          <span className="rounded-full bg-emerald-950/60 px-2 py-0.5 text-xs text-emerald-300">
                            payload
                          </span>
                        ) : null}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-zinc-400">
                      {game.lastSeenAt
                        ? new Date(game.lastSeenAt).toLocaleString()
                        : "—"}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-wrap gap-2">
                        <button
                          type="button"
                          onClick={() => openEditor(game)}
                          className="text-violet-400 hover:text-violet-300"
                        >
                          Payload
                        </button>
                        <button
                          type="button"
                          onClick={() =>
                            void patchGame(game.id, { enabled: !game.enabled })
                          }
                          className={
                            game.enabled
                              ? "text-red-400 hover:text-red-300"
                              : "text-emerald-400 hover:text-emerald-300"
                          }
                        >
                          {game.enabled ? "Disable" : "Enable"}
                        </button>
                        <button
                          type="button"
                          onClick={() => void deleteGame(game.id)}
                          className="text-zinc-500 hover:text-red-400"
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {games.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-4 py-6 text-center text-zinc-500">
                      No games registered yet. They will appear automatically when
                      loaders report their GameId.
                    </td>
                  </tr>
                ) : null}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {editing ? (
        <div className="rounded-xl border border-violet-900/50 bg-zinc-950 p-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-medium text-white">
                Payload source — {editing.name}
              </h2>
              <p className="mt-1 text-sm text-zinc-400">
                Served as plain Lua source by{" "}
                <code className="text-violet-300">/api/payload/{editing.moduleKey}</code>{" "}
                to authenticated sessions only. Leave delivery on{" "}
                <code>api</code> for this to be used.
              </p>
            </div>
            <button
              type="button"
              onClick={() => setEditing(null)}
              className="text-sm text-zinc-400 hover:text-zinc-200"
            >
              Close
            </button>
          </div>

          <textarea
            value={payloadDraft}
            onChange={(event) => setPayloadDraft(event.target.value)}
            rows={14}
            spellCheck={false}
            placeholder="-- Paste obfuscated or plain Lua source here..."
            className="mt-4 w-full rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 font-mono text-sm text-white"
          />

          <div className="mt-4 flex gap-2">
            <button
              type="button"
              onClick={() => void savePayloadSource(false)}
              disabled={!payloadDraft.trim()}
              className="rounded-md bg-violet-600 px-4 py-2 text-sm font-medium text-white hover:bg-violet-500 disabled:opacity-60"
            >
              Save payload
            </button>
            {editing.hasPayloadSource ? (
              <button
                type="button"
                onClick={() => void savePayloadSource(true)}
                className="rounded-md border border-red-900 px-4 py-2 text-sm text-red-300 hover:bg-red-950/30"
              >
                Remove payload
              </button>
            ) : null}
          </div>
        </div>
      ) : null}
    </div>
  );
}
