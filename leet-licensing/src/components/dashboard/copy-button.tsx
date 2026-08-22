"use client";

import { useState } from "react";

type CopyButtonProps = {
  value: string;
  label?: string;
};

export function CopyButton({ value, label = "Copy" }: CopyButtonProps) {
  const [copied, setCopied] = useState(false);

  async function copy() {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      // Clipboard unavailable (permissions/insecure context); do nothing.
    }
  }

  return (
    <button
      type="button"
      onClick={() => void copy()}
      className="lw-btn lw-btn-sm"
    >
      {copied ? "copied!" : label}
    </button>
  );
}
