import { config } from "./config.js";

export async function fetchRoleState(discordUserId) {
  const response = await fetch(
    `${config.apiUrl}/api/internal/discord-role?discordId=${encodeURIComponent(discordUserId)}`,
    {
      headers: { "x-internal-key": config.apiKey },
    },
  );

  if (!response.ok) {
    throw new Error(`internal api returned ${response.status}`);
  }

  return response.json();
}
