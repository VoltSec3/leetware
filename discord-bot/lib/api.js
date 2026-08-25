import { config } from "./config.js";

const headers = { "x-internal-key": config.apiKey };

export async function fetchRoleState(discordUserId) {
  const response = await fetch(
    `${config.apiUrl}/api/internal/discord-role?discordId=${encodeURIComponent(discordUserId)}`,
    { headers },
  );

  if (!response.ok) {
    throw new Error(`internal api returned ${response.status}`);
  }

  return response.json();
}

export async function createGiveawayLicense({
  tier,
  expiryWeeks,
  alias,
  note,
}) {
  const response = await fetch(`${config.apiUrl}/api/internal/giveaway-license`, {
    method: "POST",
    headers: { "Content-Type": "application/json", ...headers },
    body: JSON.stringify({ tier, expiryWeeks, alias, note }),
  });

  if (!response.ok) {
    throw new Error(`giveaway license api returned ${response.status}`);
  }

  const data = await response.json();
  return data.key;
}

export async function fetchExpiredDiscords() {
  const response = await fetch(
    `${config.apiUrl}/api/internal/expired-licensed-discords`,
    { headers },
  );

  if (!response.ok) {
    throw new Error(`expired discords api returned ${response.status}`);
  }

  const data = await response.json();
  return Array.isArray(data.discordIds) ? data.discordIds : [];
}
