import Link from "next/link";

import { BottomBar } from "@/components/site/bottombar";
import { Panel } from "@/components/site/panel";

export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6 p-6">
      <Panel rainbow className="w-full max-w-xs">
        <div className="ctrd p-5 text-center">
          <span className="lw-title text-[15px]">leetware</span>
          <p className="lw-muted mt-1">simply the best.</p>
          <div className="mt-4 flex flex-col items-center gap-2">
            <Link href="/account/login" className="lw-btn w-[165px]">
              account
            </Link>
            <Link href="/dashboard/login" className="lw-btn w-[165px]">
              admin
            </Link>
            <a
              href="https://discord.gg/x7Jrs2yMMP"
              target="_blank"
              rel="noreferrer"
              className="lw-btn w-[165px]"
            >
              discord
            </a>
          </div>
        </div>
      </Panel>

      <p className="lw-dim text-[12px]">
        need a key? join the discord.
      </p>

      <BottomBar variant="user" />
    </main>
  );
}
