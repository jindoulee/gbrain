import { startTelegram } from "./adapters/telegram";

const token = process.env.TELEGRAM_BOT_TOKEN;
if (!token) {
  console.error("Missing TELEGRAM_BOT_TOKEN. Create a bot with @BotFather, then:");
  console.error('  export TELEGRAM_BOT_TOKEN="123456:ABC..."');
  console.error("See telegram-agent/README.md");
  process.exit(1);
}

startTelegram(token);
