import { redirect } from "next/navigation";

import { getAuthenticatedAdmin } from "@/lib/admin-auth";
import { LoginForm } from "@/components/dashboard/login-form";

export default async function DashboardLoginPage() {
  const admin = await getAuthenticatedAdmin();

  if (admin) {
    redirect("/dashboard");
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-zinc-950 px-6">
      <LoginForm />
    </div>
  );
}
