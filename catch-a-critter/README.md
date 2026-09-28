# Catch a Critter

A Roblox game built on the research in [`../roblox/PLAYBOOK.md`](../roblox/PLAYBOOK.md).

**The pitch (it's the title):** cute critters wander a shared meadow. **Catch** one, carry it
home, and it earns cash every second, **even while you're offline**. Rarer critters run faster
and are harder to catch. Anyone carrying a critter home can be **bonked** by other players,
which makes them drop it for anyone to grab.

Everything (map, critters, UI) is generated in code, so there are no assets to upload.

---

## Why this design should do well

Each feature maps to something the research showed top games do:

| Playbook finding | How Catch a Critter does it |
|---|---|
| Proven loop + fresh theme; the title is the pitch | Idle base + collect-a-rarity (Grow a Garden / Steal a Brainrot DNA) with a cute "catch" theme. 3-word title |
| Fun in the first 10 seconds | Spawn at your base facing the meadow; a glowing beam leads to the nearest easy critter; one press catches it |
| Numbers go up fast | First critter earns $1–3/s right away; first slot upgrade costs $250 |
| A rarity ladder you can read at a glance | Common → Uncommon → Rare → Epic → Legendary → Mythic → **Secret**, color-coded, plus Golden / Rainbow / Galaxy mutations |
| A reason to come back tomorrow | **Offline earnings** (4h, 12h with VIP), **7-day streak** (day 7 = free Legendary), Index collection |
| Scheduled live moments | **Critter Storm** every 15 min on a *global* clock (3x luck, double spawns), weekend 2x cash, admin events |
| Players create value for each other | Chasing and **bonking** carriers, server-wide luck boosts, friend income boost |
| Easy to clip for TikTok | Server-wide "A SECRET Glitchy appeared!" alerts → everyone sprints → someone gets bonked at the last second |
| Monetization = speed-ups, not paywalls | Passes (2x cash, faster carrying, +4 slots, VIP) and boosts. **No paid random pulls.** Odds are shown in the Index |
| Friends improve retention | +10% income per friend in the server (up to +30%) |
| 2026 safety rules | No media feeds, no dependence on chat, no loot boxes. Should qualify for a Minimal/Mild maturity rating |
| Recommendations reward retention | Onboarding funnel + economy events are logged to the Creator Dashboard so you can fix drop-off |

---

## Quick start

### Option A: just open it
1. Open **`CatchACritter.rbxlx`** in Roblox Studio.
2. Press **Play**. The map builds itself when the server starts.

### Option B: live-sync the code with Rojo (recommended for development)
1. Install [Rojo](https://rojo.space/docs/v7/getting-started/installation/) (VS Code extension or CLI) and the Rojo Studio plugin.
2. In this folder: `rojo serve`
3. In Studio, open a new **Baseplate**, click **Connect** in the Rojo plugin, then Play.
   (The script removes the default Baseplate when the game starts.)

To rebuild the place file after changing code: `rojo build default.project.json -o CatchACritter.rbxlx`

### Studio settings (do these once, then publish)
- **File → Publish to Roblox**
- **Game Settings → Security → Enable Studio Access to API Services** (so saving works in Studio)
- **Game Settings → Places → Max Players = 8** (there are 8 bases)
- Fill out the **Experience Questionnaire** (maturity) honestly

### Testing commands (in Studio, anyone can use them; live, only you and `Config.AdminUserIds`)
Type these in chat:
- `/spawn Secret Galaxy`: spawn a specific rarity (or critter id like `/spawn glitchy`)
- `/storm 3`: start a Critter Storm now for 3 minutes
- `/luck 10`: server luck for 10 minutes
- `/cash 1000000`: give yourself cash (Studio only)

These also work as **live "admin abuse" events**. Announce a time on Discord/TikTok, join
your game, and spawn Secrets for everyone. It worked extremely well for Steal a Brainrot.

---

## Setting up monetization
1. In the [Creator Dashboard](https://create.roblox.com/dashboard/creations), open your experience → **Monetization**.
2. Create these **Passes** and **Developer Products**, then paste their IDs into `src/shared/Config.luau`:

| Type | Key | Suggested price |
|---|---|---|
| Pass | DoubleCash | 399 R$ |
| Pass | SpeedyCarry | 149 R$ |
| Pass | ExtraSlots | 249 R$ |
| Pass | VIP | 499 R$ |
| Product | ServerLuck | 99 R$ (everyone in the server benefits and the buyer is announced, so it's social) |
| Product | CashSmall | 49 R$ |
| Product | CashBig | 199 R$ |

Items with `Id = 0` show as "Soon" in the shop, so the game works before you set these up.
Purchases are recorded in player data, so a product is never granted twice.

---

## Launch checklist
1. **Soft launch first.** Play-test with friends and fix anything confusing in the first 5 minutes.
2. **Icon:** a big cute critter face, bright saturated background, one focal point. Make 2–3 versions and A/B test (one change at a time, 3–5 days each).
3. **Thumbnails (1920×1080):** a crowd chasing a glowing Secret critter; someone mid-bonk. No important text at the bottom edge. Only show things that are really in the game (misleading art now *hurts* ranking).
4. **Small Roblox Ads budget** to get data. Watch **first-play bounce rate, D1 retention, and play-through rate** in Creator Analytics → aim for D1 ≥ 12%.
5. Check the **Onboarding funnel** (Analytics → Funnels): Joined → Caught first critter → Placed first critter → Bought first slot. Fix the step with the biggest drop.
6. **Launch push:** post 3+ short clips a day (Secret spawns, bonk steals, storm chaos). Ask genre-fit Roblox creators to post in the same 1–2 day window. Release the `LAUNCH` code.
7. **Reaching under-16 players** (Roblox Kids/Select) needs ID verification, 2-step verification, the Roblox subscription or refundable publishing fee, and ~500 engaged players over 60 days. Start early.

## Live-ops plan (weekly update every Saturday, same time)
| Week | Update |
|---|---|
| 1 | Launch + `LAUNCH` code. First live admin event on Saturday |
| 2 | 2 new critters (one Mythic) + new code at 5K likes |
| 3 | "Night Meadow": night-only critters during storms |
| 4 | Trading between players (the #1 long-term retention feature in Adopt Me / Grow a Garden) |
| 5 | New mutation (e.g. "Frozen") + limited-time event currency and shop |
| 6 | Critter "evolutions": merge 3 of the same critter into a stronger one |
| 7 | Global leaderboards (OrderedDataStore) for income and Secrets caught |
| 8 | Second meadow biome unlocked by Rebirth 3 |

Keep the schedule predictable. Players plan around a fixed update time.

---

## Code map
```
src/shared/            (ReplicatedStorage.Shared)
  Config.luau          all tuning numbers, codes, pass/product IDs
  Critters.luau        critters, rarities, mutations, rolls, odds
  Format.luau          $1.23K / 1:05 formatting
  Remotes.luau         RemoteEvents / RemoteFunction
src/server/            (ServerScriptService.Server)
  init.server.luau     startup, player join, offline earnings, friend boost, income tick
  Services/
    MapBuilder         builds the meadow, 8 bases, trees, lighting
    DataService        DataStore load/save with session locking + autosave
    Economy            income math, cash changes, player attributes
    Spawner            spawns & moves meadow critters
    CritterFactory     builds critter models from parts
    CarryService       catching, carrying, delivering, Bonk Bat
    PlotService        bases, pedestals, selling
    EventService       Critter Storm, weekend bonus, server luck
    RewardsService     slots, rebirth, daily streak, codes (validated server-side)
    MonetizationService passes, dev products, receipts
    AdminService       chat commands for live events / testing
    Analytics          onboarding funnel, economy + custom events
    Notifier           toasts, banners, popups
src/client/            (StarterPlayerScripts.Client)
  init.client.luau     wires up the UI
  UI/                  Theme, Hud, Panels (Shop/Rebirth/Daily/Codes/Index),
                       Toasts, Onboarding (guide beam + hints), Effects
```

### Balancing
Tune in `Config.luau` and `Critters.luau`. Current pacing: ~$27/s per catch on average
(heavy-tailed; most catches are Commons), first slot $250, first rebirth $100K.

### Known gaps / next steps
- No sounds or music yet. Add a catch "pop", a bonk "boing", and an announcement chime (use Roblox's free audio library).
- Critters are built from basic parts. Commissioning real models for the icon and top rarities will lift click-through.
- Not play-tested with real players yet. Expect to tune catch times, speeds, and prices after the soft launch.
