import Link from "next/link";
import { getAuthenticatedAdmin } from "@/lib/admin-auth";

import { BottomBar } from "@/components/site/bottombar";
import { Rainbow } from "@/components/site/panel";
import { SignOutButton } from "@/components/dashboard/signout-button";
import { NavLinks } from "@/components/dashboard/nav-links";

export async function DashboardNav() {
  const admin = await getAuthenticatedAdmin();
  const role = admin?.role ?? "ADMIN";

  const links =
    role === "SUPPORT"
      ? [
          { href: "/dashboard", label: "overview" },
          { href: "/dashboard/users", label: "users" },
          { href: "/dashboard/support", label: "support" },
        ]
      : [
          { href: "/dashboard", label: "overview" },
          { href: "/dashboard/licenses", label: "licenses" },
          { href: "/dashboard/games", label: "games" },
          { href: "/dashboard/users", label: "users" },
          { href: "/dashboard/support", label: "support" },
        ];

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
              <NavLinks links={links} />
            </nav>
          </div>
          <div className="flex items-center gap-5 pl-5">
            <SignOutButton />
          </div>
        </div>
      </header>
      <BottomBar variant="admin" />
    </>
  );
}
