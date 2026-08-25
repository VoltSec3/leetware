import { getAuthenticatedAdmin } from "@/lib/admin-auth";

import { BottomBar } from "@/components/site/bottombar";
import { SignOutButton } from "@/components/dashboard/signout-button";
import { Sidebar } from "@/components/site/sidebar";

export async function DashboardNav() {
  const admin = await getAuthenticatedAdmin();
  const role = admin?.role ?? "ADMIN";

  const links =
    role === "SUPPORT"
      ? [
          { href: "/dashboard", label: "overview" },
          { href: "/dashboard/users", label: "users" },
          { href: "/dashboard/support", label: "support" },
          { href: "/dashboard/settings", label: "settings" },
        ]
      : [
          { href: "/dashboard", label: "overview" },
          { href: "/dashboard/licenses", label: "licenses" },
          { href: "/dashboard/games", label: "games" },
          { href: "/dashboard/users", label: "users" },
          { href: "/dashboard/support", label: "support" },
          { href: "/dashboard/settings", label: "settings" },
        ];

  return (
    <>
      <Sidebar links={links}>
        <div className="w-full">
          <div className="lw-dim truncate text-[12px]">{admin?.email ?? "admin"}</div>
          <div className="mt-1">
            <SignOutButton className="w-full" />
          </div>
        </div>
      </Sidebar>
      <BottomBar variant="admin" />
    </>
  );
}
