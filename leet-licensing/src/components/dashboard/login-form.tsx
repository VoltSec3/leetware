"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

import { Panel } from "@/components/site/panel";

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
    <Panel className="w-full max-w-sm">
      <form onSubmit={handleSubmit} className="p-5">
        <div className="mb-4 text-center">
          <span className="lw-title">admin sign in</span>
          <p className="lw-muted mt-1">leetware licensing</p>
        </div>

        {error ? (
          <p className="lw-error mb-3 text-[12px]" role="alert">
            {error}
          </p>
        ) : null}

        <label className="block space-y-1">
          <span className="lw-label">email</span>
          <input
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            className="lw-input"
            required
          />
        </label>

        <label className="mt-3 block space-y-1">
          <span className="lw-label">password</span>
          <input
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            className="lw-input"
            required
          />
        </label>

        <button
          type="submit"
          disabled={loading}
          className="lw-btn mt-4 w-full"
        >
          {loading ? "signing in..." : "sign in"}
        </button>
      </form>
    </Panel>
  );
}
