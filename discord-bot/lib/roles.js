import { config } from "./config.js";

export const TIER_ROLES = config.roleIds;

export function desiredRoleId(tier) {
  if (!tier) {
    return null;
  }

  return TIER_ROLES[tier.toLowerCase()] ?? null;
}

export async function applyTierRole(member, tier) {
  const desired = desiredRoleId(tier);
  const current = member.roles.cache;
  const allIds = Object.values(TIER_ROLES);
  let changed = false;

  for (const id of allIds) {
    if (id !== desired && current.has(id)) {
      await member.roles.remove(id, "leetware: tier role update");
      changed = true;
    }
  }

  if (desired && !current.has(desired)) {
    await member.roles.add(desired, "leetware: tier role sync");
    changed = true;
  }

  return changed ? "updated" : "unchanged";
}
