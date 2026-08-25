import {
  AttachmentBuilder,
  EmbedBuilder,
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
} from "discord.js";

import { config } from "./config.js";
import { getGiveaway, saveGiveaway, removeGiveaway, listActive } from "./store.js";
import { createGiveawayLicense } from "./api.js";

export const TIER_RANK = {
  none: 0,
  standard: 1,
  premium: 2,
  lifetime: 3,
  developer: 4,
};

function cap(value) {
  return value.charAt(0).toUpperCase() + value.slice(1);
}

export function randomGiveawayId() {
  const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let out = "";
  for (let i = 0; i < 12; i++) {
    out += chars[Math.floor(Math.random() * chars.length)];
  }
  return out;
}

export function buildEmbed(g) {
  const g2 = getGiveaway(g.id) ?? g;
  const typeText =
    g2.type === "license"
      ? `${g2.count}x ${cap(g2.tier)} License Giveaway!`
      : "Giveaway!";

  const embed = new EmbedBuilder()
    .setTitle(g2.title || "Giveaway")
    .setColor(g2.type === "license" ? 0x57f287 : 0x5865f2)
    .setDescription(
      `${g2.description || "React to enter!"}\n\n**Type:** ${typeText}\n**Entries:** ${g2.entries.length}\n**Ends:** <t:${Math.floor(g2.endsAt / 1000)}:R>` +
        (g2.paused ? "\n\n**Status:** Paused" : "") +
        (g2.status !== "active" ? `\n**Status:** ${cap(g2.status)}` : ""),
    )
    .setTimestamp();

  if (g2.messageId && g2.channelId) {
    embed.setFooter({ text: `id: ${g2.id}` });
  }

  return embed;
}

export function entryButton(id) {
  return new ActionRowBuilder().addComponents(
    new ButtonBuilder()
      .setCustomId(`giveaway_enter:${id}`)
      .setLabel("Enter Giveaway")
      .setStyle(ButtonStyle.Success),
  );
}

export function requirementsText(g) {
  if (!g.requirements || g.requirements.length === 0) {
    return "None";
  }
  return g.requirements
    .map((r) => {
      if (r.type === "role") return `Role <@&${r.value}>`;
      if (r.type === "accountage") return `Account age >= ${r.value} days`;
      if (r.type === "serverage") return `Server age >= ${r.value} days`;
      if (r.type === "tier") return `Tier >= ${cap(r.value)}`;
      return r.type;
    })
    .join(", ");
}

async function guildMemberFromId(guild, discordId) {
  try {
    return await guild.members.fetch(discordId);
  } catch {
    return null;
  }
}

export async function checkRequirements(g, member) {
  for (const r of g.requirements || []) {
    if (r.type === "role") {
      if (!member.roles || !member.roles.cache.has(r.value)) {
        return { ok: false, reason: "you are missing a required role." };
      }
    } else if (r.type === "accountage") {
      const created = member.user?.createdAt
        ? new Date(member.user.createdAt).getTime()
        : 0;
      const days = (Date.now() - created) / 86400000;
      if (days < Number(r.value)) {
        return {
          ok: false,
          reason: `your account must be at least ${r.value} days old.`,
        };
      }
    } else if (r.type === "serverage") {
      const joined = member.joinedAt ? new Date(member.joinedAt).getTime() : 0;
      const days = (Date.now() - joined) / 86400000;
      if (days < Number(r.value)) {
        return {
          ok: false,
          reason: `you must have been in the server for at least ${r.value} days.`,
        };
      }
    } else if (r.type === "tier") {
      let tier = "none";
      try {
        const { fetchRoleState } = await import("./api.js");
        const state = await fetchRoleState(member.id);
        tier = state.shouldHaveRole ? state.tier || "standard" : "none";
      } catch {
        // ignore; default none
      }
      if (TIER_RANK[tier] < TIER_RANK[r.value]) {
        return { ok: false, reason: `you need at least ${cap(r.value)} tier.` };
      }
    }
  }
  return { ok: true };
}

export function drawWinners(g, count) {
  const pool = [...g.entries];
  const winners = [];
  const n = Math.min(count, pool.length);
  for (let i = 0; i < n; i++) {
    const idx = Math.floor(Math.random() * pool.length);
    winners.push(pool.splice(idx, 1)[0]);
  }
  return winners;
}

export async function announceWinners(client, g, winners, { channelId } = {}) {
  const guild = config.guildId
    ? client.guilds.cache.get(config.guildId)
    : client.guilds.cache.first();

  if (!guild) {
    throw new Error("no guild available");
  }

  const channel = guild.channels.cache.get(channelId || g.channelId);
  if (!channel) {
    throw new Error("giveaway channel not found");
  }

  if (g.type === "license") {
    const sentKeys = [];
    for (const userId of winners) {
      const member = await guildMemberFromId(guild, userId);
      const displayName = member?.displayName || member?.user?.username || userId;
      const licenseKey = await createGiveawayLicense({
        tier: g.tier,
        expiryWeeks: g.expiryWeeks || 4,
        alias: `This license is for ${displayName}.`,
        note: `Automatically generated for giveaway ID ${g.id}.`,
      });

      let dmSent = false;
      try {
        const user = await client.users.fetch(userId);
        await user
          .send(
            `You won a ${g.tier} license in giveaway "${g.title}"!\n\nYour license key: \`${licenseKey}\``,
          )
          .catch(async () => {
            await user.send(`Your license key: \`${licenseKey}\``).catch(() => {});
          });
        dmSent = true;
      } catch {
        dmSent = false;
      }

      const mention = `<@${userId}>`;
      if (!dmSent) {
        await channel
          .send(
            `${mention} - Please DM a giveaway manager to claim your license. ${config.giveawayManagerMention || ""}`,
          )
          .catch(() => {});
      }
      sentKeys.push(licenseKey);
    }
    return sentKeys;
  }

  // basic giveaway: just ping winners
  const mentions = winners.map((id) => `<@${id}>`).join(" ");
  await channel.send(
    `${mentions} - You have won the giveaway "${g.title}"!`,
  );
  return [];
}

export async function endGiveaway(client, g) {
  const winners = drawWinners(g, g.count || 1);
  g.winners = winners;
  g.status = "ended";
  saveGiveaway(g);

  const guild = config.guildId
    ? client.guilds.cache.get(config.guildId)
    : client.guilds.cache.first();

  let channel = null;
  if (guild && g.channelId) {
    channel = guild.channels.cache.get(g.channelId);
  }

  await announceWinners(client, g, winners, { channelId: g.channelId });

  if (channel && g.messageId) {
    try {
      const msg = await channel.messages.fetch(g.messageId);
      await msg.edit({ embeds: [buildEmbed(g)], components: [] });
    } catch {
      // message gone; ignore
    }
  }
  return winners;
}

export async function redrawAndDeliver(client, g, count) {
  const winners = drawWinners(g, count || 1);
  g.winners = winners;
  g.status = "ended";
  saveGiveaway(g);

  await announceWinners(client, g, winners, { channelId: g.channelId });
  return winners;
}

export function computeNewEnd(g, deltaMs) {
  return g.endsAt + deltaMs;
}

export { getGiveaway, saveGiveaway, removeGiveaway, listActive };
