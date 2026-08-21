"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

export function LoginForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError(null);

    const response = await fetch("/api/admin/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });

    const data = await response.json();

    if (!response.ok) {
      setError(data.error ?? "Login failed");
      setLoading(false);
      return;
    }

    router.push("/dashboard");
    router.refresh();
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="w-full max-w-md space-y-4 rounded-xl border border-zinc-800 bg-zinc-950 p-8 shadow-xl"
    >
      <div>
        <h1 className="text-2xl font-semibold text-white">Admin sign in</h1>
        <p className="mt-2 text-sm text-zinc-400">
          Manage licenses for leet.voltsec.xyz
        </p>
      </div>

      {error ? (
        <div className="rounded-md border border-red-900 bg-red-950/40 px-3 py-2 text-sm text-red-200">
          {error}
        </div>
      ) : null}

      <label className="block space-y-2">
        <span className="text-sm text-zinc-300">Email</span>
        <input
          type="email"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          className="w-full rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-white outline-none ring-violet-500 focus:ring-2"
          required
        />
      </label>

      <label className="block space-y-2">
        <span className="text-sm text-zinc-300">Password</span>
        <input
          type="password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          className="w-full rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-white outline-none ring-violet-500 focus:ring-2"
          required
        />
      </label>

      <button
        type="submit"
        disabled={loading}
        className="w-full rounded-md bg-violet-600 px-4 py-2 font-medium text-white transition hover:bg-violet-500 disabled:opacity-60"
      >
        {loading ? "Signing in..." : "Sign in"}
      </button>
    </form>
  );
}
