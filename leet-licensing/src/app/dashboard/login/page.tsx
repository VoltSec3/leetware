import { redirect } from "next/navigation";

import { getAuthenticatedAdmin } from "@/lib/admin-auth";
import { LoginForm } from "@/components/dashboard/login-form";
import { BottomBar } from "@/components/site/bottombar";

export default async function DashboardLoginPage() {
  const admin = await getAuthenticatedAdmin();

  if (admin) {
    redirect("/dashboard");
  }

  return (
    <div className="flex min-h-screen items-center justify-center px-6 pb-12">
      <LoginForm />
      <BottomBar variant="admin" />
    </div>
  );
}
