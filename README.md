# Starter kit for [friend]'s business assistant

What this is: the same pattern Zack's own assistant runs on (CLAUDE.md +
a folder of notes it reads before acting), stripped down to a blank
starter for a different business. Runs on Claude Code, on his own
Anthropic subscription — nobody here hosts or pays for anything on his
end.

## Setup (his side, ~15 minutes)
1. Install Claude Code, sign in with his own subscription.
2. Make a folder for the business. Put `claude-md-template.md` in it,
   rename it to `CLAUDE.md`.
3. Fill in the brackets — his name, the assistant's name, the business
   name.
4. Make the five empty folders it points at: `Inventory/`, `Schedule/`,
   `Clients/`, `Knowledge/`, `Logs/`. One starter file in each is enough
   to begin — it fills in as he uses it.
5. Write `Index.md` — one line per folder saying what's in it (copy the
   "Folders" section of the template to start).
6. Open Claude Code in that folder and start talking to it like a new
   employee: tell it about a customer, a job, what's in stock.

## Texting it (the phone bridge)
`telegram-bridge-template.ps1` is a basic send/receive bridge — his own
bot, his own chat only, no middleman.

1. Message **@BotFather** on Telegram, `/newbot`, get a bot token. His
   own free Telegram account action — nobody else can do this step for
   him.
2. Save the token in a file outside this folder, e.g.
   `C:\secrets\telegram-bot.token` (one line, nothing else).
3. Message his new bot once, then run:
   `.\telegram-bridge-template.ps1 getupdates -TokenPath C:\secrets\telegram-bot.token`
   to find his chat id, then:
   `.\telegram-bridge-template.ps1 savechatid -ChatId <id> -TokenPath C:\secrets\telegram-bot.token`
4. Run `.\telegram-bridge-template.ps1 listen -TokenPath C:\secrets\telegram-bot.token`
   to start it. Every text from him lands as a file in `Inbox\` for the
   assistant to read; `send -Text "..."` texts him back.
5. Only messages from the chat id he saved are written anywhere else —
   anyone else texting the bot is silently ignored.

**What this is NOT:** no auto-acknowledge, no permission gate, no
scheduled "claim a batch and reply" harness — those are what makes
Zack's own setup safe to leave running unattended for hours, and they
took real iteration to get right (see `Jobs/handle-messages.md` in
Zack's vault for the shape of it). This bridge is the wiring; running
it unattended and trusting it with real decisions is the next step, not
this one.

## What's still NOT included
- No integration with any inventory/scheduling software he already
  uses — this is notes-in-files, not a connected system.
- No pre-written tiers for HIS specific risks — the Tier 3 list in the
  template is generic (money, outside contact, irreversible actions);
  he should add anything specific to his business.
