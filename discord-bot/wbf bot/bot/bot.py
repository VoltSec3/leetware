import os

import discord
from discord.ext import commands

from bot.config import TOKEN


class DiscordBot(commands.Bot):
    def __init__(self):
        intents = discord.Intents.default()

        super().__init__(
            command_prefix="!",
            intents=intents
        )

    async def setup_hook(self):
        cogs_path = os.path.join(
            os.path.dirname(__file__),
            "cogs"
        )

        for filename in os.listdir(cogs_path):
            if not filename.endswith(".py"):
                continue

            if filename.startswith("_"):
                continue

            extension = f"bot.cogs.{filename[:-3]}"
            await self.load_extension(extension)

        await self.tree.sync()

    async def on_ready(self):
        print(f"Logged in as {self.user}")
        print(f"Connected to {len(self.guilds)} server(s)")

    async def start(self):
        await super().start(TOKEN)