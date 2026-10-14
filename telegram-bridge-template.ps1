<#
  Minimal Telegram bridge for a personal AI assistant.
  Covers send, poll (one-shot check), and listen (long-poll loop that
  writes each inbound message to a dated batch file an assistant can read).
  Whitelisted to ONE chat id so only the owner can talk to the bot.

  Setup (one time):
    1. Message @BotFather on Telegram, /newbot, get a bot token.
    2. Put the token in a file OUTSIDE this folder, e.g.
       C:\secrets\telegram-bot.token (one line, no quotes, no newline).
    3. Message your own bot once, then run:
         .\telegram-bridge-template.ps1 getupdates -TokenPath C:\secrets\telegram-bot.token
       Find your chat id in the output, then:
         .\telegram-bridge-template.ps1 savechatid -ChatId <id> -TokenPath C:\secrets\telegram-bot.token

  Usage:
    .\telegram-bridge-template.ps1 send -Text "hello" -TokenPath <path>
    .\telegram-bridge-template.ps1 listen -InboxDir .\Inbox -TokenPath <path>
#>
param(
    [Parameter(Position = 0)]
    [ValidateSet('send', 'getupdates', 'savechatid', 'listen')]
    [string]$Command = 'listen',

    [string]$TokenPath,
    [string]$ChatIdPath = "$PSScriptRoot\telegram-chat.id",
    [string]$ChatId,
    [string]$Text,
    [string]$InboxDir = "$PSScriptRoot\Inbox",
    [int]$PollSeconds = 25
)

if (-not $TokenPath -or -not (Test-Path $TokenPath)) {
    Write-Error "telegram-bridge: pass -TokenPath pointing at your bot token file."
    exit 1
}
$token = (Get-Content $TokenPath -Raw).Trim()
$base = "https://api.telegram.org/bot$token"

function Invoke-Bot([string]$method, [hashtable]$body = $null) {
    $uri = "$base/$method"
    if ($body) {
        Invoke-RestMethod -Uri $uri -Method Post -Body ($body | ConvertTo-Json) -ContentType 'application/json'
    } else {
        Invoke-RestMethod -Uri $uri -Method Get
    }
}

function Get-SavedChatId {
    if (Test-Path $ChatIdPath) { return (Get-Content $ChatIdPath -Raw).Trim() }
    return $null
}

switch ($Command) {
    'savechatid' {
        if (-not $ChatId) { Write-Error "telegram-bridge: pass -ChatId <id>."; exit 1 }
        Set-Content -Path $ChatIdPath -Value $ChatId.Trim() -NoNewline -Encoding ascii
        Write-Output "Saved chat id to $ChatIdPath"
    }

    'getupdates' {
        $r = Invoke-Bot 'getUpdates'
        if (-not $r.ok) { Write-Error "telegram-bridge: getUpdates failed."; exit 2 }
        $r.result | ForEach-Object {
            if ($_.message) {
                Write-Output "chat id: $($_.message.chat.id)  from: $($_.message.from.username)  text: $($_.message.text)"
            }
        }
    }

    'send' {
        if (-not $Text) { Write-Error "telegram-bridge: pass -Text `"...`"."; exit 1 }
        $target = if ($ChatId) { $ChatId } else { Get-SavedChatId }
        if (-not $target) { Write-Error "telegram-bridge: no chat id saved. Run 'savechatid' first."; exit 1 }
        $r = Invoke-Bot 'sendMessage' @{ chat_id = $target; text = $Text }
        if (-not $r.ok) { Write-Error "telegram-bridge: sendMessage failed."; exit 2 }
        Write-Output "Sent."
    }

    'listen' {
        $allowedChatId = Get-SavedChatId
        if (-not $allowedChatId) { Write-Error "telegram-bridge: no chat id saved. Run 'savechatid' first."; exit 1 }
        if (-not (Test-Path $InboxDir)) { New-Item -ItemType Directory -Path $InboxDir | Out-Null }
        Write-Output "Listening for messages from chat id $allowedChatId only. Ctrl+C to stop."
        $offset = 0
        while ($true) {
            $method = if ($offset -gt 0) { "getUpdates?offset=$offset&timeout=$PollSeconds" } else { "getUpdates?timeout=$PollSeconds" }
            $r = Invoke-Bot $method
            if (-not $r.ok) { Start-Sleep -Seconds 5; continue }
            foreach ($u in $r.result) {
                $offset = $u.update_id + 1
                $msg = $u.message
                if (-not $msg) { continue }
                # ponytail: single-owner whitelist, string compare is enough at this scale
                if ("$($msg.chat.id)" -ne "$allowedChatId") { continue }
                $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                $file = Join-Path $InboxDir "batch-$stamp.md"
                "--- $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | update $($msg.message_id) ---`n$($msg.text)`n" |
                    Out-File -FilePath $file -Encoding utf8
                Write-Output "Wrote $file"
            }
        }
    }
}
