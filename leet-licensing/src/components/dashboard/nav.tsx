"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

const links = [
  { href: "/dashboard", label: "Overview" },
  { href: "/dashboard/licenses", label: "Licenses" },
  { href: "/dashboard/games", label: "Games" },
];

export function DashboardNav() {
  const pathname = usePathname();
  const router = useRouter();

  return (
    <header className="border-b border-zinc-800 bg-zinc-950/80 backdrop-blur">
      <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
        <div className="flex items-center gap-8">
          <Link href="/dashboard" className="text-lg font-semibold text-white">
            leetware licensing
          </Link>
          <nav className="flex items-center gap-4">
            {links.map((link) => {
              const active =
                pathname === link.href ||
                (link.href !== "/dashboard" && pathname.startsWith(link.href));

              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`text-sm transition-colors ${
                    active
                      ? "text-white"
                      : "text-zinc-400 hover:text-zinc-200"
                  }`}
                >
                  {link.label}
                </Link>
              );
            })}
          </nav>
        </div>
        <button
          type="button"
          onClick={async () => {
            await fetch("/api/admin/auth/logout", { method: "POST" });
            router.push("/dashboard/login");
            router.refresh();
          }}
          className="rounded-md border border-zinc-700 px-3 py-1.5 text-sm text-zinc-300 hover:bg-zinc-900"
        >
          Sign out
        </button>
      </div>
    </header>
  );
}
