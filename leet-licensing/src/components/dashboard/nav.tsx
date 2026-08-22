"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

import { BottomBar } from "@/components/site/bottombar";
import { Rainbow } from "@/components/site/panel";

const links = [
  { href: "/dashboard", label: "overview" },
  { href: "/dashboard/licenses", label: "licenses" },
  { href: "/dashboard/games", label: "games" },
  { href: "/dashboard/users", label: "users" },
];

export function DashboardNav() {
  const pathname = usePathname();
  const router = useRouter();

  return (
    <>
      <header className="lw-panel lw-surface border-x-0 border-t-0">
        <Rainbow />
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-y-1 px-4 py-2">
          <div className="flex flex-wrap items-center gap-6">
            <Link href="/dashboard" className="lw-title text-[14px]">
              leetware admin
            </Link>
            <nav className="flex flex-wrap items-center gap-4">
              {links.map((link) => {
                const active =
                  pathname === link.href ||
                  (link.href !== "/dashboard" && pathname.startsWith(link.href));

                return (
                  <Link
                    key={link.href}
                    href={link.href}
                    className={
                      active
                        ? "font-bold text-[#cce335]"
                        : "lw-muted hover:text-[#cccccc]"
                    }
                  >
                    {link.label}
                  </Link>
                );
              })}
            </nav>
          </div>
          <div className="flex items-center gap-5 pl-5">
            <button
              type="button"
              onClick={async () => {
                await fetch("/api/admin/auth/logout", { method: "POST" });
                router.push("/dashboard/login");
                router.refresh();
              }}
              className="lw-btn lw-btn-sm"
            >
              sign out
            </button>
          </div>
        </div>
      </header>
      <BottomBar variant="admin" />
    </>
  );
}
