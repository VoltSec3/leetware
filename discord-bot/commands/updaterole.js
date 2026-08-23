import { SlashCommandBuilder } from "discord.js";

export const data = new SlashCommandBuilder()
  .setName("updaterole")
  .setDescription(
    "Sync your Discord role to your leetware license tier (standard / premium / lifetime / developer)",
  );

export async function execute(interaction) {
  await interaction.deferReply({ ephemeral: true });

  const { fetchRoleState } = await import("../lib/api.js");
  const { applyTierRole } = await import("../lib/roles.js");

  let state;

  try {
    state = await fetchRoleState(interaction.user.id);
  } catch {
    await interaction.editReply(
      "could not reach the licensing backend - try again later.",
    );
    return;
  }

  if (!state.found) {
    await interaction.editReply(
      "no site account is linked to your discord. register on the website first.",
    );
    return;
  }

  const removeRoles = async () => {
    try {
      return await applyTierRole(interaction.member, null);
    } catch {
      return "unchanged";
    }
  };

  if (state.banned) {
    await removeRoles();
    await interaction.editReply(
      `you are banned from the site for ${state.banReason ?? "no reason provided"}. your role was removed.`,
    );
    return;
  }

  if (state.suspended) {
    await removeRoles();
    await interaction.editReply(
      `your account is suspended. your role was removed.`,
    );
    return;
  }

  let change;

  try {
    change = await applyTierRole(interaction.member, state.tier);
  } catch {
    await interaction.editReply(
      "i could not update your roles - check my permissions and try again.",
    );
    return;
  }

  const note =
    change === "updated"
      ? "your role was updated."
      : "your role was already correct.";
  const tierLabel = state.tier ? `${state.tier} tier` : "no active license";

  await interaction.editReply(`status: ${tierLabel}. ${note}`);
}
