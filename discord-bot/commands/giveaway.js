import {
  ChatInputCommandInteraction,
  EmbedBuilder,
  MessageFlags,
  SlashCommandBuilder,
} from "discord.js";

import { config } from "../lib/config.js";
import {
  buildEmbed,
  checkRequirements,
  endGiveaway,
  entryButton,
  getGiveaway,
  randomGiveawayId,
  redrawAndDeliver,
  saveGiveaway,
} from "../lib/giveaway.js";
import { getAll, listActive, removeGiveaway } from "../lib/store.js";

function cap(value) {
  return value.charAt(0).toUpperCase() + value.slice(1);
}

function stripId(value) {
  return value.trim();
}

function requireManager(interaction) {
  const roles = interaction.member?.roles;

  if (!roles || !roles.cache.has(config.giveawayRoleId)) {
    interaction
      .reply({
        content: "you do not have permission to use giveaway management commands.",
        flags: [MessageFlags.Ephemeral],
      })
      .catch(() => {});
    return false;
  }

  return true;
}

function requireGiveaway(interaction, id) {
  const g = getGiveaway(id);

  if (!g) {
    interaction
      .reply({ content: "giveaway not found.", flags: [MessageFlags.Ephemeral] })
      .catch(() => {});
    return null;
  }

  return g;
}

export const data = new SlashCommandBuilder()
  .setName("giveaway")
  .setDescription("Run and manage giveaways")
  .addSubcommandGroup((group) =>
    group
      .setName("create")
      .setDescription("Create a giveaway")
      .addSubcommand((cmd) =>
        cmd
          .setName("license")
          .setDescription("Create a license giveaway (title is automatic)")
          .addStringOption((o) =>
            o.setName("tier").setDescription("License tier").setRequired(true)
              .addChoices(
                { name: "standard", value: "standard" },
                { name: "premium", value: "premium" },
                { name: "lifetime", value: "lifetime" },
                { name: "developer", value: "developer" },
              ),
          )
          .addIntegerOption((o) =>
            o.setName("winners").setDescription("Winner count").setRequired(true)
              .setMinValue(1),
          )
          .addIntegerOption((o) =>
            o.setName("duration").setDescription("Hours until end").setRequired(true)
              .setMinValue(1),
          )
          .addStringOption((o) =>
            o.setName("description").setDescription("Description").setRequired(true),
          )
          .addIntegerOption((o) =>
            o.setName("expiryweeks").setDescription("License duration in weeks")
              .setRequired(false).setMinValue(1),
          ),
      )
      .addSubcommand((cmd) =>
        cmd
          .setName("basic")
          .setDescription("Create a basic giveaway")
          .addStringOption((o) =>
            o.setName("title").setDescription("Title").setRequired(true),
          )
          .addStringOption((o) =>
            o.setName("description").setDescription("Description").setRequired(true),
          )
          .addIntegerOption((o) =>
            o.setName("duration").setDescription("Hours until end").setRequired(true)
              .setMinValue(1),
          )
          .addIntegerOption((o) =>
            o.setName("winners").setDescription("Winner count").setRequired(true)
              .setMinValue(1),
          ),
      ),
  )
  .addSubcommand((cmd) =>
    cmd.setName("end").setDescription("End a giveaway now and draw winners")
      .addStringOption((o) =>
        o.setName("id").setDescription("Giveaway id").setRequired(true),
      ),
  )
  .addSubcommand((cmd) =>
    cmd.setName("cancel").setDescription("Cancel a giveaway without winners")
      .addStringOption((o) =>
        o.setName("id").setDescription("Giveaway id").setRequired(true),
      ),
  )
  .addSubcommand((cmd) =>
    cmd.setName("reroll").setDescription("Redraw winners for an ended giveaway")
      .addStringOption((o) =>
        o.setName("id").setDescription("Giveaway id").setRequired(true),
      )
      .addIntegerOption((o) =>
        o.setName("winners").setDescription("Winner count").setRequired(false)
          .setMinValue(1),
      ),
  )
  .addSubcommand((cmd) =>
    cmd.setName("pause").setDescription("Pause a giveaway")
      .addStringOption((o) =>
        o.setName("id").setDescription("Giveaway id").setRequired(true),
      ),
  )
  .addSubcommand((cmd) =>
    cmd.setName("resume").setDescription("Resume a paused giveaway")
      .addStringOption((o) =>
        o.setName("id").setDescription("Giveaway id").setRequired(true),
      ),
  )
  .addSubcommand((cmd) =>
    cmd.setName("extend").setDescription("Add hours to a giveaway")
      .addStringOption((o) =>
        o.setName("id").setDescription("Giveaway id").setRequired(true),
      )
      .addIntegerOption((o) =>
        o.setName("hours").setDescription("Hours to add").setRequired(true)
          .setMinValue(1),
      ),
  )
  .addSubcommand((cmd) =>
    cmd.setName("shorten").setDescription("Remove hours from a giveaway")
      .addStringOption((o) =>
        o.setName("id").setDescription("Giveaway id").setRequired(true),
      )
      .addIntegerOption((o) =>
        o.setName("hours").setDescription("Hours to remove").setRequired(true)
          .setMinValue(1),
      ),
  )
  .addSubcommand((cmd) =>
    cmd.setName("list").setDescription("List all giveaways")
      .addStringOption((o) =>
        o.setName("status").setDescription("Filter status").setRequired(false)
          .addChoices(
            { name: "active", value: "active" },
            { name: "ended", value: "ended" },
            { name: "cancelled", value: "cancelled" },
            { name: "paused", value: "paused" },
          ),
      ),
  )
  .addSubcommand((cmd) =>
    cmd.setName("history").setDescription("List recently ended giveaways"),
  )
  .addSubcommand((cmd) =>
    cmd.setName("lookup").setDescription("Look up a giveaway by id")
      .addStringOption((o) =>
        o.setName("id").setDescription("Giveaway id").setRequired(true),
      ),
  )
  .addSubcommand((cmd) =>
    cmd.setName("winners").setDescription("List winners of a giveaway")
      .addStringOption((o) =>
        o.setName("id").setDescription("Giveaway id").setRequired(true),
      ),
  )
  .addSubcommand((cmd) =>
    cmd.setName("title").setDescription("Change the title")
      .addStringOption((o) =>
        o.setName("id").setDescription("Giveaway id").setRequired(true),
      )
      .addStringOption((o) =>
        o.setName("title").setDescription("New title").setRequired(true),
      ),
  )
  .addSubcommand((cmd) =>
    cmd.setName("description").setDescription("Change the description")
      .addStringOption((o) =>
        o.setName("id").setDescription("Giveaway id").setRequired(true),
      )
      .addStringOption((o) =>
        o.setName("description").setDescription("New description")
          .setRequired(true),
      ),
  );

// The requirement subcommand is appended directly (no TS cast needed).
data.addSubcommand((c) =>
  c
    .setName("requirement")
    .setDescription("Add or wipe requirements")
    .addStringOption((o) =>
      o.setName("id").setDescription("Giveaway id").setRequired(true),
    )
    .addStringOption((o) =>
      o.setName("type").setDescription("Requirement type").setRequired(true)
        .addChoices(
          { name: "role", value: "role" },
          { name: "accountage", value: "accountage" },
          { name: "serverage", value: "serverage" },
          { name: "tier", value: "tier" },
          { name: "wipe", value: "wipe" },
        ),
    )
    .addStringOption((o) =>
      o.setName("value").setDescription("Value (role id / days / tier)")
        .setRequired(false),
    ),
);

export async function execute(interaction) {
  if (!interaction.isChatInputCommand()) {
    return;
  }

  const group = interaction.options.getSubcommandGroup(false);
  const sub = interaction.options.getSubcommand();

  if (!requireManager(interaction)) return;

  if (group === "create") {
    if (sub === "license") {
      await createLicenseGiveaway(interaction);
    } else if (sub === "basic") {
      await createBasicGiveaway(interaction);
    }
    return;
  }

  switch (sub) {
    case "end":
      await endGiveawayCmd(interaction);
      break;
    case "cancel":
      await cancelGiveaway(interaction);
      break;
    case "reroll":
      await rerollGiveaway(interaction);
      break;
    case "pause":
      await pauseGiveaway(interaction, true);
      break;
    case "resume":
      await pauseGiveaway(interaction, false);
      break;
    case "extend":
      await shiftGiveaway(interaction, true);
      break;
    case "shorten":
      await shiftGiveaway(interaction, false);
      break;
    case "list":
      await listGiveaways(interaction);
      break;
    case "history":
      await historyGiveaways(interaction);
      break;
    case "lookup":
      await lookupGiveaway(interaction);
      break;
    case "winners":
      await winnersGiveaway(interaction);
      break;
    case "title":
      await setTitle(interaction);
      break;
    case "description":
      await setDescription(interaction);
      break;
    case "requirement":
      await setRequirement(interaction);
      break;
  }
}

async function makeGiveaway(interaction, opts) {
  const channel = interaction.client.channels?.cache?.get(interaction.channelId);

  if (!channel) {
    await interaction.reply({
      content: "this command must be used in a channel.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  const g = {
    id: randomGiveawayId(),
    type: opts.type,
    tier: opts.tier || "standard",
    count: opts.count,
    expiryWeeks: opts.expiryWeeks || 4,
    title: opts.title,
    description: opts.description,
    endsAt: Date.now() + opts.duration * 3600 * 1000,
    channelId: channel.id,
    messageId: null,
    status: "active",
    paused: false,
    pausedAt: null,
    entries: [],
    winners: [],
    requirements: [],
  };

  const embed = new EmbedBuilder()
    .setTitle(opts.title)
    .setColor(opts.type === "license" ? 0x57f287 : 0x5865f2)
    .setDescription(
      opts.type === "license"
        ? `${opts.description}\n\n**${opts.count}x ${cap(opts.tier)} License(s) giveaway!**\nReact with the button to enter!`
        : `${opts.description}\n\nReact with the button to enter!`,
    )
    .setTimestamp();

  const button = entryButton(g.id);

  let message;
  try {
    message = await channel.send({ embeds: [embed], components: [button] });
  } catch (error) {
    await interaction.reply({
      content:
        "I could not post the giveaway in this channel. Make sure I have the **Send Messages** and **Embed Links** permissions here, then try again.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  g.messageId = message.id;
  saveGiveaway(g);

  await interaction.reply({
    content: `Giveaway created: \`${g.id}\``,
    flags: [MessageFlags.Ephemeral],
  });
}

async function createLicenseGiveaway(interaction) {
  const tier = interaction.options.getString("tier") || "standard";
  const winners = interaction.options.getInteger("winners");
  const duration = interaction.options.getInteger("duration");
  const description = interaction.options.getString("description");
  const expiryWeeks = interaction.options.getInteger("expiryweeks") || 4;
  const title = `${winners}x ${cap(tier)} License Giveaway`;

  await makeGiveaway(interaction, {
    type: "license",
    tier,
    count: winners,
    expiryWeeks,
    title,
    description,
    duration,
  });
}

async function createBasicGiveaway(interaction) {
  const title = interaction.options.getString("title");
  const description = interaction.options.getString("description");
  const duration = interaction.options.getInteger("duration");
  const winners = interaction.options.getInteger("winners");

  await makeGiveaway(interaction, {
    type: "basic",
    count: winners,
    title,
    description,
    duration,
  });
}

async function endGiveawayCmd(interaction) {
  const id = stripId(interaction.options.getString("id"));
  const g = requireGiveaway(interaction, id);
  if (!g) return;

  if (g.status !== "active") {
    await interaction.reply({
      content: "this giveaway is not active.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  const winners = await endGiveaway(interaction.client, g);

  await interaction.reply({
    content: `Ended giveaway \`${g.id}\` with winners: ${winners
      .map((w) => `<@${w}>`)
      .join(", ") || "none"}`,
    flags: [MessageFlags.Ephemeral],
  });
}

async function cancelGiveaway(interaction) {
  const id = stripId(interaction.options.getString("id"));
  const g = requireGiveaway(interaction, id);
  if (!g) return;

  if (g.status !== "active") {
    await interaction.reply({
      content: "this giveaway is not active.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  g.status = "cancelled";
  saveGiveaway(g);

  const channel = interaction.client.channels.cache.get(g.channelId);
  if (channel && g.messageId) {
    try {
      const msg = await channel.messages.fetch(g.messageId);
      await msg.edit({ embeds: [buildEmbed(g)], components: [] });
    } catch {
      // ignore
    }
  }

  await interaction.reply({
    content: `Cancelled giveaway \`${g.id}\`.`,
    flags: [MessageFlags.Ephemeral],
  });
}

async function rerollGiveaway(interaction) {
  const id = stripId(interaction.options.getString("id"));
  const g = requireGiveaway(interaction, id);
  if (!g) return;

  if (g.status !== "ended") {
    await interaction.reply({
      content: "you can only reroll an ended giveaway.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  const count = interaction.options.getInteger("winners") || g.count || 1;

  if (g.entries.length === 0) {
    await interaction.reply({
      content: "no entries to redraw from.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  const winners = await redrawAndDeliver(interaction.client, g, count);

  await interaction.reply({
    content: `Redrew winners for \`${g.id}\`: ${winners
      .map((w) => `<@${w}>`)
      .join(", ") || "none"}`,
    flags: [MessageFlags.Ephemeral],
  });
}

async function pauseGiveaway(interaction, pause) {
  const id = stripId(interaction.options.getString("id"));
  const g = requireGiveaway(interaction, id);
  if (!g) return;

  if (g.status !== "active") {
    await interaction.reply({
      content: "this giveaway is not active.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  if (pause) {
    if (g.paused) {
      await interaction.reply({
        content: "giveaway is already paused.",
        flags: [MessageFlags.Ephemeral],
      });
      return;
    }
    g.paused = true;
    g.pausedAt = Date.now();
  } else {
    if (!g.paused) {
      await interaction.reply({
        content: "giveaway is not paused.",
        flags: [MessageFlags.Ephemeral],
      });
      return;
    }
    const delta = Date.now() - g.pausedAt;
    g.endsAt += delta;
    g.paused = false;
    g.pausedAt = null;
  }

  saveGiveaway(g);

  const channel = interaction.client.channels.cache.get(g.channelId);
  if (channel && g.messageId) {
    try {
      const msg = await channel.messages.fetch(g.messageId);
      await msg.edit({ embeds: [buildEmbed(g)], components: [entryButton(g.id)] });
    } catch {
      // ignore
    }
  }

  await interaction.reply({
    content: pause
      ? `Paused giveaway \`${g.id}\`.`
      : `Resumed giveaway \`${g.id}\`.`,
    flags: [MessageFlags.Ephemeral],
  });
}

async function shiftGiveaway(interaction, extend) {
  const id = stripId(interaction.options.getString("id"));
  const g = requireGiveaway(interaction, id);
  if (!g) return;

  if (g.status !== "active") {
    await interaction.reply({
      content: "this giveaway is not active.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  const hours = interaction.options.getInteger("hours");
  const delta = hours * 3600 * 1000;

  if (extend) {
    g.endsAt += delta;
  } else {
    g.endsAt -= delta;
    if (g.endsAt < Date.now()) {
      await interaction.reply({
        content: "shortening would end the giveaway in the past.",
        flags: [MessageFlags.Ephemeral],
      });
      return;
    }
  }

  saveGiveaway(g);

  const channel = interaction.client.channels.cache.get(g.channelId);
  if (channel && g.messageId) {
    try {
      const msg = await channel.messages.fetch(g.messageId);
      await msg.edit({ embeds: [buildEmbed(g)], components: [entryButton(g.id)] });
    } catch {
      // ignore
    }
  }

  await interaction.reply({
    content: extend
      ? `Extended giveaway \`${g.id}\` by ${hours}h.`
      : `Shortened giveaway \`${g.id}\` by ${hours}h.`,
    flags: [MessageFlags.Ephemeral],
  });
}

async function listGiveaways(interaction) {
  const status = interaction.options.getString("status");
  let all = getAll();

  if (status) {
    all = all.filter((g) => g.status === status);
  }

  if (all.length === 0) {
    await interaction.reply({
      content: "no giveaways found.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  const lines = all
    .map(
      (g) =>
        `\`${g.id}\` - ${g.type} - ${g.status}${g.paused ? " (paused)" : ""} - ends <t:${Math.floor(g.endsAt / 1000)}:R>`,
    )
    .join("\n");

  await interaction.reply({
    content: `**Giveaways (${all.length})**\n${lines}`,
    flags: [MessageFlags.Ephemeral],
  });
}

async function historyGiveaways(interaction) {
  const ended = getAll().filter((g) => g.status === "ended");

  if (ended.length === 0) {
    await interaction.reply({
      content: "no ended giveaways.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  const lines = ended
    .map(
      (g) =>
        `\`${g.id}\` - ${g.title} - winners: ${
          g.winners.map((w) => `<@${w}>`).join(", ") || "none"
        }`,
    )
    .join("\n");

  await interaction.reply({
    content: `**Ended giveaways (${ended.length})**\n${lines}`,
    flags: [MessageFlags.Ephemeral],
  });
}

async function lookupGiveaway(interaction) {
  const id = stripId(interaction.options.getString("id"));
  const g = requireGiveaway(interaction, id);
  if (!g) return;

  await interaction.reply({
    content:
      `**${g.title}** (\`${g.id}\`)\n` +
      `Type: ${g.type}${g.type === "license" ? ` (${g.tier}, ${g.expiryWeeks}w)` : ""}\n` +
      `Status: ${g.status}${g.paused ? " (paused)" : ""}\n` +
      `Entries: ${g.entries.length}\n` +
      `Ends: <t:${Math.floor(g.endsAt / 1000)}:R>\n` +
      `Winners: ${g.winners.map((w) => `<@${w}>`).join(", ") || "none"}\n` +
      `Requirements: ${g.requirements.map((r) => `${r.type}:${r.value || ""}`).join(", ") || "none"}`,
    flags: [MessageFlags.Ephemeral],
  });
}

async function winnersGiveaway(interaction) {
  const id = stripId(interaction.options.getString("id"));
  const g = requireGiveaway(interaction, id);
  if (!g) return;

  if (g.winners.length === 0) {
    await interaction.reply({
      content: "this giveaway has no winners yet.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  await interaction.reply({
    content: `Winners of \`${g.id}\`: ${g.winners
      .map((w) => `<@${w}>`)
      .join(", ")}`,
    flags: [MessageFlags.Ephemeral],
  });
}

async function setTitle(interaction) {
  const id = stripId(interaction.options.getString("id"));
  const g = requireGiveaway(interaction, id);
  if (!g) return;

  g.title = interaction.options.getString("title");
  saveGiveaway(g);

  const channel = interaction.client.channels.cache.get(g.channelId);
  if (channel && g.messageId) {
    try {
      const msg = await channel.messages.fetch(g.messageId);
      await msg.edit({ embeds: [buildEmbed(g)], components: [entryButton(g.id)] });
    } catch {
      // ignore
    }
  }

  await interaction.reply({
    content: `Updated title for \`${g.id}\`.`,
    flags: [MessageFlags.Ephemeral],
  });
}

async function setDescription(interaction) {
  const id = stripId(interaction.options.getString("id"));
  const g = requireGiveaway(interaction, id);
  if (!g) return;

  g.description = interaction.options.getString("description");
  saveGiveaway(g);

  const channel = interaction.client.channels.cache.get(g.channelId);
  if (channel && g.messageId) {
    try {
      const msg = await channel.messages.fetch(g.messageId);
      await msg.edit({ embeds: [buildEmbed(g)], components: [entryButton(g.id)] });
    } catch {
      // ignore
    }
  }

  await interaction.reply({
    content: `Updated description for \`${g.id}\`.`,
    flags: [MessageFlags.Ephemeral],
  });
}

async function setRequirement(interaction) {
  const id = stripId(interaction.options.getString("id"));
  const g = requireGiveaway(interaction, id);
  if (!g) return;

  const type = interaction.options.getString("type");
  const value = interaction.options.getString("value");

  if (type === "wipe") {
    g.requirements = [];
  } else {
    if (!value) {
      await interaction.reply({
        content: "you must provide a value for this requirement type.",
        flags: [MessageFlags.Ephemeral],
      });
      return;
    }
    g.requirements = g.requirements || [];
    g.requirements.push({ type, value });
  }

  saveGiveaway(g);

  await interaction.reply({
    content: `Updated requirements for \`${g.id}\`.`,
    flags: [MessageFlags.Ephemeral],
  });
}
