# How to Make a Roblox Game That Does Well (Research Playbook, Sept 2026)

This is a working reference for designing, launching, and running Roblox games. It pulls
together platform data, case studies of the biggest recent hits, Roblox's own statements
about discovery, and creator best practices. Sources are listed at the bottom.

> **How much to trust the numbers:** Roblox's official pages and the GameAnalytics report
> could not be opened directly from the research environment, so figures come from search
> summaries of those pages, news coverage, and SEC filings. Numbers marked *(vendor claim)*
> come from marketing or agency blogs. Treat them as rough direction, not benchmarks.

---

## 1. The platform right now

| Fact | Number | Why it matters |
|---|---|---|
| Daily active users (Q2 2026) | **~123M**, up 10% YoY | The audience is huge, but most of it goes to a few top games |
| Sessions on mobile | **~80%** (PC ~17%, console ~3%) | **Design for phones first**: touch controls, big buttons, a UI that reads on a small screen |
| 18+ users | DAU up **32%**, hours up **27%** YoY | Older players are the fastest-growing group, and Roblox is courting them with 18+ high-fidelity games and a higher DevEx rate |
| Japan / India DAU | **+67% / +64%** YoY | International growth is real, so translation is worth doing |
| Spend per hour, young US/CA players | **Declining** | Kid-heavy games earn less per hour than before; broad or older audiences help revenue |
| Record concurrent players | Steal a Brainrot **~25M** (2025) | A hit on Roblox can be bigger than any other game on any platform |
| DevEx rate | ~$0.0038 per Robux (higher for qualifying 18+ content) | After Roblox's 30% cut, 1,000 Robux spent works out to roughly $2.66 for you |

---

## 2. What's winning, and why

### The recent mega-hits

| Game | Core loop | Why it blew up |
|---|---|---|
| **Grow a Garden** (peak ~22M CCU) | Plant seeds → crops grow in real time (**even while you're offline**) → sell, buy rarer seeds, get mutations | First version made in **3 days** by a 16-year-old. "Grows Offline" was on the icon, and it gave players a reason to come back and check. Relaxing and not competitive. Trading made players create value for each other. **Weekly Saturday updates** plus events, with whole teams dedicated to events |
| **Steal a Brainrot** (peak ~25M CCU, the all-time record) | Buy meme creatures off a conveyor belt → they earn cash per second in your base → **steal other players' creatures** or defend your own (base lock timer, alarm) | Combined a tycoon/idle base with steal-and-defend PvP. Rarity tiers are shown by color. The dev hosts scheduled "**Admin Abuse**" live events (Tuesday + Saturday) where exclusives spawn. Kids losing their creatures made great TikTok clips. It rode the brainrot meme wave |
| **99 Nights in the Forest** (peak ~14M CCU) | Co-op survival-horror: gather resources in the day, survive the night, go as many nights as you can | Built in a **3-month sprint**. Different from the tycoon/sim games that dominated at the time. Friends play it while talking ("friendslop"), and it peaks on weekends. The monetization doesn't break the tension |
| **+1 Speed Keyboard Escape** (billions of visits, 98% rating) | Walk on a giant ASMR keyboard, gain speed every step, escape obstacles | A dead-simple incremental loop the player "gets" in 2 seconds. The ASMR hook works well on video. A bbno$ concert event hit **6.35M CCU** |
| **Steal An Egg** (released Aug 20, 2026; ~1.3M CCU within weeks) | Steal eggs → hatch them → creatures earn money | A fast follow of the "Steal a ___" format. **Warning:** its doomscrolling/treadmill feed mechanic set off a Roblox policy crackdown (see section 8) |

### Games that last for years

| Game | What keeps it alive |
|---|---|
| **Brookhaven RP** | Open-ended roleplay town with no objectives, and still 45–60 minute sessions. The players create the fun |
| **Adopt Me!** | Pet collecting and raising plus trading, drawn from Neopets/Tamagotchi/Dragon City |
| **Blox Fruits** | Deep progression (separate "seas"), layered combat, a rare-fruit economy, and steady meaningful updates |
| **RIVALS** | Polished competitive FPS. Shows that skill-based games can work on Roblox if the execution is good |
| **Dress to Impress** | Creative fashion competition with player judging. One of the fastest games to 1B visits |

### Patterns across these games

1. **Proven free-to-play mechanics, re-skinned.** Hits take existing loops (idle growing, tycoon, pet collecting, gacha rarity, incrementals) and wrap them in a new fantasy or meme. Almost nothing is truly new. The *combination* is.
2. **Players create value for each other.** Trading, stealing, judging, roleplay. Other players *are* the content, and that is what brings people back.
3. **The idea fits in a 3-word title.** "Grow a Garden." "Steal a Brainrot." "+1 Speed Keyboard Escape." The title *is* the pitch.
4. **Numbers go up, fast.** Visible progress within seconds: cash per second, speed +1, a rarer color.
5. **Collectibles with a clear rarity ladder** (Common → Rare → Epic → Legendary → Mythic → Secret), shown by color so a kid can read it instantly.
6. **Scheduled live moments.** Weekly updates at a set time, admin-abuse events, concerts. They create appointments and "I have to be there" urgency.
7. **Easy to clip.** A theft, a rare pull, a scream in a horror game. Each makes a 10-second TikTok, and TikTok is free advertising.
8. **Small teams shipping fast.** The breakouts came from tiny teams iterating quickly, not big studios. Speed beat polish.
9. **Timing a trend.** Being early on a meme or format matters a lot. Fast-follow clones capture huge traffic because the algorithm rewards engagement *velocity* (how fast engagement is growing).

---

## 3. How Roblox discovery works (2026)

Roblox recommends games based on **what players do after they click**, not on raw player count.
In June 2026 it announced a big update ("Optimizing Discovery"):

- **The most important Home recommendation signals:**
  1. **Play-through rate:** the share of people who see your tile and actually play (a meaningful session)
  2. **First-play bounce rate:** people who join and leave almost right away. *This hurts you.*
  3. **Play days per user:** how many *different days* people come back
  4. **Playtime per user**
- The old "qualified play-through rate" was split into separate signals for **play-through, session quality, and spend**.
- Signals are measured over **day 1, days 2–7, and days 8–28**. Roblox is moving from a 7-day view to **28-day retention**.
- Roblox now **publishes the relative weights of its signals** and shows your game's values in **Creator Analytics**. Check these instead of guessing.
- Industry reading: games climbing the charts are the ones where players **come back within 24–48 hours** for another short session, not the ones with the longest single sessions.
- The update is meant to **stop rewarding clickbait**. A misleading thumbnail raises clicks but raises bounce rate even more, so it now costs you.

**In practice:** the algorithm gives your game a small test audience. If those players
stay, come back tomorrow, and come back next week, it shows the game to more people. The job is
**strong first 5 minutes → reason to return tomorrow → reason to return next week**.

### Thumbnails and icons
- Thumbnails are **16:9, 1920×1080**. Keep key content away from the bottom edge (the player count covers it).
- The icon is the most important image. **Bright, saturated backgrounds**, a **character or face**, one clear focal point. Test with text and without text.
- **A/B test one variable at a time** for 3–5 days each, and pick the winner by the visits-to-impressions ratio. Roblox's thumbnail personalization raised qualified play-through by **+8.5%** on average in tests.
- Top games in a genre reach about **3.6%** impression → play *(vendor claim)*.
- **Show what the game really is.** Misleading art now raises bounce rate, which is a ranking penalty.

---

## 4. Benchmarks: what "good" looks like

From GameAnalytics' 2026 report (500+ Roblox games with 1M+ MAU):

| Metric | Median | Target to aim for |
|---|---|---|
| D1 retention | **10.3%** | 12%+ (industry guidance), top games go well beyond |
| D7 retention | **1.6%** | ~3%+ |
| D30 retention | **0.5%** | Anything above 1% is strong |
| ARPPU (avg revenue per paying user) | **$0.70** | Top 10%: $2.33 · Top 5%: $4.80 · Top 1%: **$55.31** |

The median big game loses about 90% of new players after the first day. Small retention gains
compound through the algorithm. Going from 10% to 15% D1 can decide whether Roblox promotes the game.

---

## 5. Design rules

### First-time user experience (the first 5 minutes)
- Players decide almost immediately whether to stay, based on one question: **"Is this fun right now?"**
- **Obby:** jumping within 10 seconds. **Tycoon:** first machine placed within 30 seconds. **Simulator:** clicking and seeing numbers go up within the first minute.
- **No walls of text.** Show, don't tell. Use arrows, glowing paths, and **timed hints** that only appear for players who get stuck.
- **Low early thresholds.** The first few levels, upgrades, and rarities should come fast.
- Instrument the onboarding with **funnel events** (`AnalyticsService`) so you can see exactly where players drop off.

### Core loop checklist
- [ ] Can someone understand the goal from the **icon + title** alone?
- [ ] Does a number go up within 10 seconds?
- [ ] Is there a **collectible with a visible rarity ladder**?
- [ ] Is there **something to come back for** tomorrow? (offline growth, daily reward, timers, restocks, streaks)
- [ ] Do **other players make the game better**? (trading, stealing, co-op, showing off, judging)
- [ ] Is there a **long-term goal**? (rebirth/prestige, collection completion, leaderboard, "survive 99 nights")
- [ ] Does it make **clip-worthy moments**?
- [ ] Does it **run well on a cheap phone** with touch controls?

### The "come back tomorrow" toolkit
- **Offline progress** (Grow a Garden's big innovation on Roblox)
- **Daily login rewards and streaks**
- **Timed shop restocks** / rotating stock
- **Rebirth/prestige** that resets progress for a permanent multiplier
- **Friends-join bonuses.** Playing with friends raises retention, and the algorithm tracks social play.
- **Scheduled events** at fixed weekly times (use Roblox's official **Experience Events** feature for countdowns and notifications)

---

## 6. Live ops: updates are the product

- **Weekly updates at a fixed time** (e.g. Saturday) are standard for top games. Roblox's own guidance: small content updates every **2–4 weeks**, bigger feature updates every **2–3 months**. Top games go faster.
- **A predictable schedule beats big, irregular drops.** Players plan around things they can count on.
- **Limited-time events** with event currency and exclusive items, balanced so most players need weeks to finish them.
- **Codes:** release new ones with each update or milestone (e.g. "10K likes = new code"). They drive likes, favorites, and returns.
- **Live dev moments:** admin-abuse events, a dev joining servers, concerts. They create "be there" urgency and clip-worthy chaos.
- **Keep a live-ops calendar** and plan events at least 4–6 weeks ahead.
- **Read feedback constantly.** Grow a Garden's team credits listening to players and building their feedback into updates.

---

## 7. Monetization

**Rule #1: build a strong free path first.** Players leave in the first minute if the free loop is
thin. Paid items should feel like **speed-ups or self-expression, not a paywall**.

| Tool | Use for | Examples |
|---|---|---|
| **Game Passes** (one-time, permanent) | Permanent upgrades, VIP, QoL | 2x cash, auto-collect, extra plot slot, VIP area |
| **Developer Products** (consumable, can buy repeatedly) | Boosts, currency, skips, gacha pulls | Currency packs, 30-min luck boost, instant grow, restock skip |
| **Subscriptions** | Recurring perks | Daily bonus currency, exclusive monthly pet |
| **Rewarded video ads** | Players who don't pay | Watch an ad for a free boost |
| **Creator Rewards / engagement payouts** | Baseline passive income | Automatic, based on engagement |

- **Tiered pricing:** offer 3–5 passes at different price points (e.g. **49 / 149 / 499 / 999 Robux**). Vendors claim this raises conversion 40–60% vs. a single pass *(vendor claim)*.
- **Put offers where the player feels the pain:** a speed boost next to the slow part, a luck boost at the egg hatch, a lock extension when someone is stealing from you.
- **Rarity + chance** (eggs, spins, mutations) earns the most money in the genre. See the safety note below before designing paid randomness.
- **Don't ruin the fantasy.** 99 Nights is praised because its monetization doesn't break the tension.
- Keep in mind that spend per hour is falling for young US/Canada players. Broader or older audiences, and international markets, help revenue.

---

## 8. Safety, policy, and audience (2026). Don't skip this.

Roblox changed a lot this year, and some of it decides whether your game can reach kids at all.

- **Age-based accounts (live globally June 2026):** **Roblox Kids** (ages 5–8) and **Roblox Select** (ages 9–15). By default these accounts **don't see** games with sensitive issues, **social hangouts**, or free-form drawing.
- **To reach under-16 players**, creators need to:
  - Complete **ID verification**
  - Turn on **2-step verification**
  - Have an active Roblox subscription **or** pay a one-time refundable publishing fee
  - Reach roughly **500 "highly engaged" real players over 60 days**, after which Roblox reviews the game based on how 16+ players use it and gives it a **Minimal / Mild / Moderate** maturity label
- **Content ratings** are moving to the **IARC** system (ESRB in the US, etc.). Fill out the maturity questionnaire honestly.
- **The doomscrolling ban (Aug 2026):** games that combine **a media feed + autoplay/auto-scroll + a reward for watching** are banned from Kids and Select accounts. Steal An Egg was forced to remove its feed mechanic. **Don't design around rewarding passive watching.**
- **Chat** now requires age checks for all users. Don't build core gameplay that depends on text chat between strangers.
- **Paid random items and trading** get regulatory attention in several countries. Show odds clearly and follow Roblox's paid random item policies. Scams on off-platform trading sites are common, so keep trading in-game and safe.
- **Opportunity:** 18+ players are the fastest-growing group, and Roblox raised the DevEx rate by 42% for qualifying 18+ high-fidelity games.

---

## 9. Marketing and launch

- **Short-form video is the #1 way new players find games.** TikTok, YouTube Shorts, Reels. Build clip-worthy moments into the design, then post them yourself, often.
- **Genre-fit creators beat big creators.** A 50K-follower creator in your genre usually beats a 500K general gaming creator *(vendor claim, but matches common experience)*.
- **Coordinate the launch:** get several creators posting in the same short window. The resulting spike in engagement makes the algorithm test your game with more players.
- **YouTubers who cover Roblox news** can make or break a game, as the Steal An Egg criticism showed.
- **Roblox Ads** (sponsored games, search ads) are useful for **testing** thumbnails and early retention before you scale up.
- **Build a community hub** (Discord, Roblox group) for codes, update announcements, and feedback.
- **Soft launch:** get the D1 and bounce numbers healthy with a small audience *before* pushing traffic. Sending traffic to a game with poor retention wastes it, and the algorithm remembers.

---

## 10. Step-by-step: from idea to hit

1. **Scout trends weekly.** Check the Roblox Charts (Top Trending, Up-and-Coming) and see what's rising on TikTok. Ask what fantasy or meme is heating up and what proven loop fits it.
2. **Pick a proven loop + a fresh wrapper.** Say it as "___ a ___" in 3–4 words. Check it against the core loop checklist in section 5.
3. **Build a playable version in days, not months** (Grow a Garden v1 took 3 days; 99 Nights took 3 months to launch). Get to the fun first. Polish later.
4. **Instrument everything:** onboarding funnel events, economy events, and custom events for key actions.
5. **Soft launch** with small ad spend. Watch **bounce rate, D1, and play-through rate** in Creator Analytics. Iterate on the first 5 minutes until D1 is ≥12%.
6. **A/B test the icon and thumbnail** one variable at a time.
7. **Launch loudly:** a coordinated creator push, a code for launch-day likes, a live event in the first week.
8. **Commit to a weekly update schedule** with a fixed day and time. Add events, codes, and new collectibles.
9. **Monetize once retention holds:** tiered passes, contextual products, and a subscription for your most engaged players.
10. **Watch the 28-day curve**, not the CCU spike. The algorithm rewards players who keep coming back.

---

## 11. Sources

**Platform and discovery**
- [Roblox: Optimizing Discovery (June 2026)](https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox)
- [Roblox Creator Hub: Discovery](https://create.roblox.com/docs/discovery)
- [Endsights: Roblox is rewriting its algorithm to kill clickbait](https://endsights.com/roblox-optimizing-discovery-how-great-games-reach-millions-of-players-on-roblox)
- [ZehnStudio26: Recommended For You rewards 28-day retention](https://zehn-studio26.com/news/recommended-for-you-retention-update/)
- [RoWatcher: What the algorithm actually rewards](https://rowatcher.com/news/what-the-roblox-algorithm-actually-rewards-in-2026-not-ccu)
- [Roblox Q2 2026 shareholder letter (SEC)](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm)
- [Investing.com: Q2 2026 earnings call](https://www.investing.com/news/transcripts/earnings-call-transcript-roblox-q2-2026-beats-eps-but-shares-sink-on-bookings-93CH-4826338)
- [PocketGamer.biz: 80% of Roblox users on mobile](https://www.pocketgamer.biz/80-of-roblox-users-are-on-mobile-contributing-46-of-robux-revenue/)
- [Roblox: 18+ high-fidelity games & DevEx increase](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42)

**Benchmarks**
- [GameAnalytics 2026 Roblox Benchmark Report](https://www.gameanalytics.com/reports/2026-roblox-report)
- [GameDev Reports summary of GameAnalytics](https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox)

**Case studies**
- [Wikipedia: Grow a Garden](https://en.wikipedia.org/wiki/Grow_a_Garden) · [GamesBeat: Jandel interview](https://gamesbeat.com/janzen-madsen-interview/) · [GameDiscoverCo: Grow a Garden & discovery](https://newsletter.gamediscover.co/p/what-grow-a-gardens-89-million-ccu)
- [Wikipedia: Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot) · [PocketGamer.biz: 25M CCU](https://www.pocketgamer.biz/robloxs-steal-a-brainrot-becomes-first-game-to-surpass-25m-concurrent-players/) · [Steal a Brainrot Wiki: Stealing](https://stealabrainrot.fandom.com/wiki/Stealing)
- [PCGamesN: 99 Nights developer interview](https://www.pcgamesn.com/roblox/99-nights-in-the-forest-interview) · [Roblox DevForum: Creator Spotlight, 99 Nights](https://devforum.roblox.com/t/creator-spotlight-the-story-behind-99-nights-in-the-forest/4036940)
- [The Bloxline: Why +1 Speed Keyboard Escape works](https://www.thebloxline.com/articles/1-speed-keyboard-escape-has-become-one-of-roblox-s-biggest-games-here-s-why-it-works)
- [Player.One: Steal An Egg](https://www.player.one/robloxs-steal-egg-beating-some-platforms-biggest-games-164086)
- [Naavik: Blox Fruits, Brookhaven, Adopt Me](https://naavik.co/deep-dives/roblox-blox-fruits-brookhaven-adopt-me/) · [Naavik: Predicting the next big hits](https://naavik.co/digest/predicting-the-next-big-hits-on-roblox/) · [Naavik: State of UGC Games 2026](https://naavik.co/deep-dives/the-state-of-ugc-games-2026/)
- [Wikipedia: List of Roblox games](https://en.wikipedia.org/wiki/List_of_Roblox_games)

**Design, live ops, monetization, marketing**
- [Creator Hub: Onboarding](https://create.roblox.com/docs/production/game-design/onboarding) · [Onboarding techniques](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/game-design/onboarding-techniques.md) · [DevForum: Funnel events](https://devforum.roblox.com/t/improving-onboarding-through-funnel-events/3064458)
- [Creator Hub: Content updates](https://create.roblox.com/docs/production/game-design/content-updates)
- [Creator Hub: Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails)
- [Creator Hub: Monetization](https://create.roblox.com/docs/production/monetization)
- [ROLearn: Monetization trends 2026](https://rolearn.dev/trend-reports/roblox-monetization-trends-devex-creator-rewards/)
- [BLOXG: Influencer marketing](https://bloxg.com/roblox-influencer-marketing) *(vendor)*

**Safety and policy**
- [Roblox: Kids and Select accounts](https://about.roblox.com/newsroom/2026/04/introducing-roblox-kids-and-select-accounts) · [Now globally available](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available)
- [Creator Hub: Content maturity](https://create.roblox.com/docs/production/promotion/content-maturity) · [Account verification](https://create.roblox.com/docs/production/publishing/account-verification)
- [Kotaku: Roblox forces Steal An Egg to remove doomscrolling](https://kotaku.com/roblox-cracks-down-on-doomscrolling-games-like-steal-an-egg-that-forces-players-to-watch-reels-while-running-on-a-treadmill-2000727952) · [GamesRadar: doomscrolling crackdown](https://www.gamesradar.com/games/simulation/roblox-takes-down-controversial-doomscrolling-game-promises-to-remove-others-that-reward-watching-a-continuous-feed-of-content-as-theyre-not-appropriate-for-younger-users/)
