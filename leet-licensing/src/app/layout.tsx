import type { Metadata } from "next";

import "./globals.css";
import { SettingsProvider } from "@/components/site/settings";

export const metadata: Metadata = {
  title: "leetware licensing",
  description: "License management for leet.voltsec.xyz",
};

const noFlashScript = `
(function () {
  try {
    var t = localStorage.getItem("lw-theme") || "default";
    var l = localStorage.getItem("lw-layout") || "sidebar";
    if (t && t !== "default") document.documentElement.setAttribute("data-theme", t);
    document.documentElement.setAttribute("data-layout", l === "original" ? "original" : "sidebar");
  } catch (e) {}
})();
`;

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className="h-full antialiased">
      <head>
        <script dangerouslySetInnerHTML={{ __html: noFlashScript }} />
      </head>
      <body className="min-h-full flex flex-col">
        <SettingsProvider>{children}</SettingsProvider>
      </body>
    </html>
  );
}
