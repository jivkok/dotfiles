# Known Application Windows — Monitors Placement

Reference document for intentional app window placement decisions across a multi-monitor desk setup.
Config is implemented in `osx/.slate`.

---

## Monitor Setup

| Alias | Display | Size | Resolution | Position | Role |
|---|---|---|---|---|---|
| `mon-landscape` | External 4K landscape | 40in | 3840×2160 | Center | Primary / production |
| `mon-portrait` | External 4K portrait | 32in | 2160×3840 | Right of landscape | Secondary context |
| `mon-portrait-lowres` | External portrait (low-res variant) | 32in | 1080×1920 | Right of landscape | Same role as portrait, lower resolution |
| `mon-laptop` | MacBook Pro M2 Max built-in | — | 1728×1117 | Left of landscape | Passive / monitoring |

---

## Layout Auto-Detection

Slate automatically activates a layout based on the set of screen resolutions detected at startup or when displays change. No manual intervention needed — connecting or disconnecting a monitor triggers the matching layout.

| Layout | Trigger resolutions | Active default |
|---|---|---|
| `1monitor` | Laptop only (1728×1117) | Yes |
| `2monitors` | Laptop + 4K landscape | Yes |
| `2monitors-external` | 4K landscape + 1080p portrait (no laptop) | Yes |
| `3monitors-3p` | Laptop + 4K landscape + 4K portrait | Yes |
| `3monitors-3p-lowres` | Laptop + 4K landscape + 1080p portrait | Yes |
| `3monitors-2p` | Laptop + 4K landscape + 4K portrait | **Disabled** |
| `3monitors-2p-lowres` | Laptop + 4K landscape + 1080p portrait | **Disabled** |

`3monitors-2p` and `3monitors-2p-lowres` share the same resolution trigger as their `3p` counterparts and are currently commented out. They can be activated manually via `hyper+f11` / `hyper+f12`.

---

## Monitor Zones

### Landscape (primary)

Partitioned vertically into three panels. These are preferences, not hard rules.

| Zone | Position | Slate alias | Purpose |
|---|---|---|---|
| Left third | Left | `leftthird` | Terminal |
| Center third | Center | `middlethird` | Production (IDE, editors) |
| Right third | Right | `rightthird` | Reference (browser, docs) |

### Portrait (secondary)

Partitioned horizontally into two panels.

| Zone | Position | Slate alias | Purpose |
|---|---|---|---|
| Top half | Top | `tophalf` | Apps where active content grows from the bottom (terminal output, chat messages). Placing at top keeps the active edge near eye level when glancing right. |
| Bottom half | Bottom | `bottomhalf` | Secondary domain context (home management, work email) |

### Laptop (passive)

Used as a single full-screen zone. No active work happens here when connected to external monitors.

| Zone | Position | Slate alias | Purpose |
|---|---|---|---|
| Full | — | `full` | Passive / glance apps (monitoring, system utilities) |

---

## Placement Criteria

| Criterion | Description |
|---|---|
| **Usage frequency** | How often the app is actively switched to during a session |
| **Authoring vs. reference** | Does the app produce persistent content (code, scripts) or is it primarily for lookup/reading? |
| **Context pairing** | Which apps are used simultaneously and benefit from visual proximity |
| **Active focus area** | Where new/relevant content appears in the app window — affects portrait top vs. bottom placement |
| **Engagement depth** | Does the app require active input (active) or just display state (passive/glance)? |
| **Domain context** | Which life/work domain the app primarily serves: work-production, home, system/utility |
| **Screen real estate needs** | Does the app benefit from height, width, or is it flexible? |

---

## Application Inventory & Placement

Apps grouped by category. Placement shown for the 3-monitor setup (`3monitors-3p`), which is the primary reference configuration.

### Terminals

| App | Frequency | Authoring / Reference | Pairs with | Active focus area | Depth | Domain | Real estate | Placement | Notes |
|---|---|---|---|---|---|---|---|---|---|
| iTerm2 | High | Authoring | IDE, browser | Bottom (output grows down) | Active | Work-production | Needs height | Landscape — left third | Primary terminal |
| Ghostty | Medium | Authoring | IDE, browser | Bottom (output grows down) | Active | Work-production | Needs height | Portrait — top half (3-monitor); Laptop (2-monitor) | Secondary terminal |
| Terminal | Low | Authoring | — | Bottom | Passive | Work-production | Needs height | Laptop (3-monitor); Portrait — bottom half (2monitors-external) | Backup terminal. Used only when primary/secondary unavailable. |

### Development

| App | Frequency | Authoring / Reference | Pairs with | Active focus area | Depth | Domain | Real estate | Placement | Notes |
|---|---|---|---|---|---|---|---|---|---|
| VS Code (`Code`) | High | Authoring | iTerm2, browser | Varies | Active | Work-production | Needs height; third of 4K width is sufficient | Landscape — center third | |
| VSCodium | High | Authoring | iTerm2, browser | Varies | Active | Work-production | Needs height; third of 4K width is sufficient | Landscape — center third | Open-source VS Code variant |
| Xcode | Medium | Authoring | iTerm2, browser | Varies | Active | Work-production | Needs height; third of 4K width is sufficient | Landscape — center third | |
| Sourcetree | Low | Reference | — | Top (commit list, diff view) | Active | Work-production | Flexible | Laptop (3-monitor); Portrait — bottom half (2monitors-external) | Occasional git visualization. Terminal preferred for diffs. |

### Browsers

| App | Frequency | Authoring / Reference | Pairs with | Active focus area | Depth | Domain | Real estate | Placement | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Firefox | High | Reference | IDE, iTerm2 | Varies | Active | Personal | Flexible | Landscape — right third | Main daily driver, personal use |
| Firefox Developer Edition | High | Reference | — | Varies | Active | Home | Flexible | Portrait — bottom half | Main daily driver for home network, cameras, home automation |
| Microsoft Edge | High | Reference | IDE, iTerm2 | Varies | Active | Work | Flexible | Landscape — right third | Designated work browser. Hyper+E to focus. |
| Mullvad Browser | Medium | Reference | — | Varies | Active | Misc | Flexible | Laptop | General private / no-auth browsing. Laptop avoids overlap with primary browsers on landscape. |
| Safari | Low | Reference | — | Varies | Active | Misc | Flexible | Laptop | Dedicated for high-privacy / high-security apps |
| Google Chrome | Very low | Reference | — | Varies | Active | Misc | Flexible | Laptop | Not actively used |
| Chromium | Very low | Reference | — | Varies | Active | Misc | Flexible | Laptop | Not actively used |
| Brave Browser | Very low | Reference | — | Varies | Active | Misc | Flexible | Laptop | Not actively used |

### AI Assistants

| App | Frequency | Authoring / Reference | Pairs with | Active focus area | Depth | Domain | Real estate | Placement | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Claude | High | Reference | — | Varies | Active | Both | Flexible | Landscape — right third | Standalone. Used for both work and personal. |

### Media

| App | Frequency | Authoring / Reference | Pairs with | Active focus area | Depth | Domain | Real estate | Placement | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Kindle | Low | Reference | — | Varies | Active | — | Benefits from height | Portrait — bottom half | Reading benefits from portrait height. |

### Communication

| App | Frequency | Authoring / Reference | Pairs with | Active focus area | Depth | Domain | Real estate | Placement | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Microsoft Outlook | High | Mixed | — | Bottom (new messages) | Active | Both | Benefits from height | Portrait — bottom half (3-monitor); Landscape — right third (2monitors) | Standalone. Portrait suits tall inbox/thread layout. |
| Microsoft Teams | Medium | Mixed | — | Bottom (new messages, meeting controls) | Active | Work | Flexible | Portrait — top half (3-monitor); Laptop (2-monitor) | Work chat and meetings |
| Messages | Low | Mixed | — | Bottom (new messages) | Passive | Personal | Flexible | Laptop — full | Off primary sight line to reduce interruption |

### System & Utilities

| App | Frequency | Authoring / Reference | Pairs with | Active focus area | Depth | Domain | Real estate | Placement | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Finder | Low | Reference | — | — | Passive | System | Flexible | Laptop — full | Ambient. Primary file management done via terminal (Ranger). |
| Activity Monitor | Low | Reference | — | — | Passive | System | Flexible | Laptop — full | Glance-only; no active input needed |
| Console | Low | Reference | — | Bottom (new log entries) | Passive | System | Needs height | Laptop — full | Glance-only; log output grows downward |
| KeePassXC | Low | Reference | — | — | Active (on demand) | System | Flexible | Laptop — full | |
| KeePassium | Low | Reference | — | — | Active (on demand) | System | Flexible | Laptop — full | iOS-style macOS variant of KeePass |

---

## Placement Matrix

Quick-reference map of app positions across monitor configurations. The `-lowres` variants follow identical placement to their non-lowres counterparts (portrait resolution differs, zones do not).

Position key:
- **L** = landscape
- **P** = portrait
- **⅓L/⅓C/⅓R** = left/center/right third
- **½L/½R** = left/right half
- **½T/½B** = top/bottom half
- **Laptop** = laptop full screen

| Category | App | 1 monitor | 2 mon (L+Laptop) | 2 mon ext (L+P) | 3 mon 2p (L+P+Laptop) | 3 mon 3p (L+P+Laptop) |
|---|---|---|---|---|---|---|
| Terminals | **Ghostty** | Full | Laptop | P ½T | P ½T | P ½T |
| Terminals | **iTerm2** | Full | L btm-⅓L | L ⅓L | P ½T | L ⅓L |
| Terminals | **Terminal** | Full | Laptop | P ½B | Laptop | Laptop |
| Development | **VS Code** | Full | L ⅓C | L ⅓C | L ½R | L ⅓C |
| Development | **VSCodium** | Full | L ⅓C | L ⅓C | L ½R | L ⅓C |
| Development | **Xcode** | Full | L ⅓C | L ⅓C | L ½R | L ⅓C |
| Development | **Sourcetree** | Full | Laptop | P ½B | Laptop | Laptop |
| Browsers | **Brave Browser** | Full | Laptop | P ½B | Laptop | Laptop |
| Browsers | **Chromium** | Full | Laptop | P ½B | Laptop | Laptop |
| Browsers | **Firefox** | Full | L ⅓R | L ⅓R | L ½L | L ⅓R |
| Browsers | **Firefox Dev Ed** | Full | L ⅓R | P ½B | P ½B | P ½B |
| Browsers | **Google Chrome** | Full | Laptop | P ½B | Laptop | Laptop |
| Browsers | **Microsoft Edge** | Full | L ⅓R | L ⅓R | L ½L | L ⅓R |
| Browsers | **Mullvad Browser** | Full | Laptop | P ½B | Laptop | Laptop |
| Browsers | **Safari** | Full | Laptop | P ½B | Laptop | Laptop |
| AI Assistants | **Claude** | Full | L ⅓R | L ⅓R | L ½L | L ⅓R |
| Media | **Kindle** | ½R | L ⅓L | P ½B | P ½B | P ½B |
| Communication | **Microsoft Outlook** | Full | L ⅓R | P ½B | P ½B | P ½B |
| Communication | **Microsoft Teams** | Full | Laptop | P ½T | P ½T | P ½T |
| Communication | **Messages** | Full | Laptop | P ½B | Laptop | Laptop |
| System & Utilities | **Finder** | ½L | L top-⅓L | L top-⅓L | Laptop | Laptop |
| System & Utilities | **Activity Monitor** | Full | Laptop | P ½T | Laptop | Laptop |
| System & Utilities | **Console** | Full | Laptop | P ½T | Laptop | Laptop |
| System & Utilities | **KeePassium** | Full | Laptop | P ½B | Laptop | Laptop |
| System & Utilities | **KeePassXC** | Full | Laptop | P ½B | Laptop | Laptop |

---

## App Focus Shortcuts

All shortcuts use the **Hyper key** (`CapsLock`, remapped to `ctrl+shift+alt+cmd`) plus a single letter.

### Principles

Only high-frequency apps earn a shortcut — low-frequency apps don't warrant the mental overhead of a dedicated binding. Keys are chosen for mnemonic strength: first letter of the app name or its primary role. Keys already used for window placement (arrows, numbers, `h`/`j`/`k`/`l`, `return`, `[`/`]`, `esc`, `g`, function keys) are excluded to avoid conflicts.

### Bindings

| Key           | App                       | Mnemonic                                    |
|---------------|---------------------------|---------------------------------------------|
| `hyper+z`     | iTerm2                    | Last letter — convention from prior config  |
| `hyper+t`     | Ghostty                   | **T**erminal                                |
| `hyper+space` | VSCodium                  | Quick-access IDE — spacebar for prominence  |
| `hyper+x`     | VS Code                   | e**X**tension of the editor family          |
| `hyper+b`     | Firefox                   | **B**rowser (personal daily driver)         |
| `hyper+d`     | Firefox Developer Edition | **D**ev browser (home/homelab daily driver) |
| `hyper+w`     | Microsoft Edge            | **W**ork browser                            |
| `hyper+c`     | Claude                    | **C**laude                                  |
| `hyper+o`     | Microsoft Outlook         | **O**utlook                                 |
