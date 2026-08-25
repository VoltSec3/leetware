import asyncio

from bot.bot import DiscordBot


async def main():
    bot = DiscordBot()
    await bot.start()


if __name__ == "__main__":
    asyncio.run(main())