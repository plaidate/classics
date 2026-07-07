# Classics — the manual

Ten *Code the Classics* games on one Playdate cartridge's worth of shared
code. Each ships as its own `.pdx`; pick a game below for its story,
controls, and rules. Every game runs at 30 fps on a 400×240 1-bit screen,
keeps its own high score or record on the device, and has a **restart**
item in the system menu.

**Volume 1:** [Boing](#boing) · [Cavern](#cavern) · [Bunner](#bunner) ·
[Myriapod](#myriapod) · [Sunday Soccer](#sunday-soccer)
**Volume 2:** [Kinetix](#kinetix) · [Avenger](#avenger) ·
[Eggzy](#eggzy) · [Leading Edge](#leading-edge) ·
[Beat Streets](#beat-streets)

---

## Boing

*Table tennis: the crank is your bat. First to 10.* (Vol 1)

A faithful shrink of Boing, the Pong-style opener from *Code the Classics
Vol 1*. You are a bat. The other bat is either The Machine or the person
next to you fighting over the same Playdate. First to ten takes the table.

**Controls**
- Title: **Up/Down** toggle 1 Player / 2 Players; **A** confirms and serves.
- 1 Player: **Up/Down** or the **crank** move your (left) bat. Crank is optional.
- 2 Players, one Playdate: Player 1 on the **d-pad** (left bat), Player 2 on the **crank** (right bat).
- Game over: **A** returns to the title (after a 1-second lockout).

**How to play**
The ball serves after a short pause toward whoever last conceded. It moves
faster with **every hit** (starts at speed 5, +1 per bat contact, no cap)
and deflects by *where* it strikes the bat — catch it with the edge to send
it off near 45°. Hit sounds layer and sharpen as the rally speeds up.

**Scoring** — 1 point per ball that gets past a bat; **first to 10 wins**.
No lives, no rounds.

**The AI (1P)** — the right bat moves at most 3 px/frame (same as your
d-pad). It drifts to center while the ball heads away and only tracks once
the ball is incoming and within 260 px, aiming at the ball plus a random
±12 px wobble that is re-rolled on every hit.

**Tips**
1. Hit with the **tip** of the bat for the steepest angle.
2. Build speed *and* angle: once a steep diagonal is faster than 3 px/frame, the AI physically can't reach it — flat rallies never beat it.
3. Force the AI to travel; its ±12 px wobble compounds with its speed limit when it's on the move.
4. Late wall-bounces near the AI's side leave it minimal time to correct (it only tracks inside 260 px).
5. In 1P use the crank for fine defensive nudges; hold the d-pad only for long dashes (it overrides the crank while pressed).

---

## Cavern

*Trap the robots in orbs, pop them, and grab the fruit.* (Vol 1)

A Bubble-Bobble-style single-screen platformer. You're a miner in a
wrap-around cavern full of patrolling robots. Puff out floating orbs to seal
each robot inside, pop the bubble to burst it into fruit, and clear every
robot to drop into the next of four rotating layouts.

**Controls**
- **Left/Right** — run.
- **A** — jump (when landed); also start / confirm on menus.
- **B** — blow an orb; **hold B** to keep inflating the newest orb bigger and send it farther.
- No crank. Game over: **A** returns to the title after ~1 second.

**How to play**
Levels wrap vertically — fall off the bottom and you reappear at the top;
platforms are jump-through. Robots drop in through gaps in the top row.
A free-floating orb that touches a robot **traps** it (it floats up sealed
inside); pop a trapped orb and it bursts into **fruit** you must grab before
it expires. Clear all robots, fruit, and trapped orbs to advance. You can
have at most 5 orbs live at once (0.35 s cooldown between puffs).

**Scoring, lives & progression**
- Start with **2 spare lives** and **3 hearts**.
- Score fruit are worth **100 / 200 / 300** (types 1–3).
- **Heart fruit** heals 1 heart (max 3); **star fruit** grants an extra life.
- Only **aggressive (type-2) robots** ever drop hearts or stars — pop them for the good stuff.
- Levels cycle through 4 layouts forever; each level fields `9 + level` robots, more of them the aggressive kind, and their fire rate climbs.

**Enemies & hazards**
- **Standard robot** — patrols, jumps, biased two-in-three toward you, fires horizontal bolts (keener when level with you).
- **Aggressive robot** — all of the above plus it **snipes your orbs** and **breathes flame** at close range when roughly level; drops the best fruit.
- **Bolts** burst orbs and hurt you; **flames** hurt you at close range.

**Tips**
1. Farm aggressive robots — they're the only source of hearts and extra lives.
2. Don't stand at a robot's exact height: fire rate goes ×10 when you're level with it, and flame only triggers then. Attack from above or below.
3. Hold B to reach distant robots — a charged orb crosses more of the screen and has a bigger trap radius.
4. Don't spam orbs into walls; a blocked orb immediately floats, wasting one of your five.
5. Use the vertical wrap as a no-damage escape from a bolt/flame corner.
6. A lone floating trapped orb stalls the level clear — pop it.

---

## Bunner

*An endless road-crosser: hop upstream, dodge cars and trains, ride the logs.* (Vol 1)

A rabbit hops forever upstream through grass, traffic, train tracks, and
rivers while the screen scrolls out from under it. There's no finish line —
only a furthest-row score, and an eagle with strong opinions about
dawdlers. (Inspired by Vol 1's Infinite Bunner.)

**Controls**
- **D-pad** — hop exactly one cell per press (up to 3 hops buffer while mid-hop).
- **Crank** — every 60° of forward crank triggers one up-hop; cranking backward does nothing.
- **A** — start / restart (game over needs ~1 second first). No B.

**How to play**
One life per run. The camera scrolls up at 14 px/s, ramping to 3× as you
near the top of the screen — so pushing forward eases the pressure.
Collisions only count with your feet on the ground; **mid-hop you're
untouchable**. Score is the furthest row climbed; it persists as a high
score.

**Hazards**
- **Cars** (road) — one direction per row, 30–90 px/s (faster as you score). Approaching cars honk a warning. Touch one = squash.
- **Trains** (rail) — the middle of three rail rows. A bell rings and a "!" flashes on the arrival side for exactly 1 second, then a train crosses fast. Be off the middle row when it passes.
- **Water** — open water drowns you; **logs** carry you sideways. Adjacent water rows always flow opposite directions.
- **Hedges** (grass) — two-row bushes that block columns, always leaving a gap.
- **Eagle** — drop too far below the bottom edge and the eagle takes you. Not dodgeable.

There are no pickups.

**Tips**
1. Chain buffered hops through traffic — mid-hop invulnerability is real.
2. The train bell gives you a full second, and the "!" shows which side it's coming from; one hop off the rail is enough.
3. Early road crossings are easiest — roads speed up as your score climbs.
4. Logs carry you toward the wall while your position pins at the edge; hop off before the log slides out from under you.
5. Between opposite-flowing water rows, aim for a log slightly upstream of you, not directly ahead.
6. Crank to march forward safely (reverse never counts); use the d-pad for lateral dodges.

---

## Myriapod

*A Centipede-style shooter: split the myriapod, mind the spider.* (Vol 1)

A segmented myriapod snakes down through a field of rocks toward your ship,
penned into the bottom rows. Shoot it apart — but every segment you kill
hardens into a fresh rock, so the field keeps clogging up while a bee, a
fly, and a spider harass you from the flanks.

**Controls**
- **D-pad** — free 8-way flight, confined to the lower zone.
- **Hold A or B** — autofire (~8 shots/second).
- **Crank** — optional fine horizontal nudge (±4 px/frame).
- **A or B** — start / restart (game over after ~1 second).

**How to play**
Shoot the myriapod apart. Killing a middle segment **splits** the chain —
whoever was following becomes a new head leading its own chain. Each killed
segment hardens into a rock where it died. Rocks take 3 hits to break;
segments and the spider chew straight through them. Clear all segments to
top up the rock field and spawn the next wave.

**Scoring, lives & progression**
- Segment **10**, bee **20**, fly **30**, spider **40**.
- Start with **3 lives**; an extra life every **10,000 points**.
- Segments have 1–2 HP depending on the wave; every 4th wave is faster (but always 1-HP). The myriapod speeds up and lengthens each wave.

**Enemies**
- **Myriapod segments** — the main threat; contact kills you.
- **Bee** — crosses mid-screen chipping HP off rocks it passes.
- **Fly** — dives down, sometimes seeding a fresh rock as it goes.
- **Spider** — prowls your zone eating rocks; contact kills you. Always enters from the side away from you.

Only one of each flyer exists at a time.

**Tips**
1. Split the chain from the **tail** end to keep your zone less cluttered with new rocks.
2. Use the crank for a ±4 px strafe to line up on a fast segment without over-committing.
3. Fast waves are 1.4× speed but 1-HP — prioritize dodging; steady autofire shreds them.
4. Kill the **spider** early: highest value, and it eats your rock cover.
5. Shoot the **fly** before it seeds — each can plant multiple fresh rocks.
6. Remember 2-HP segments (waves 2 and 3 of each cycle) need two hits.

---

## Sunday Soccer

*Top-down 7-a-side football: run, pass, shoot, defend.* (Vol 1)

Park football distilled: two teams of seven on a vertically-scrolling pitch,
small open goals at both ends, and nobody minding either of them. You steer
whoever's nearest the ball; the CPU marks, positions, and hounds your
carrier. Your lifetime W/D/L record is kept between sessions.

**Controls**
- Menu: **Up/Down** toggle EASY/HARD, **A** kicks off.
- **D-pad** — run in 8 directions; stopping keeps your facing so you can aim a standing kick.
- **Hold A** — charge kick power (full bar in ~0.4 s); **release A** to kick. A teammate in a tight cone ahead makes it a **pass** (control follows the pass); otherwise it's a shot/clearance.
- **B** — switch to the player nearest the ball (favors a defender when the CPU has it). No crank.

**How to play**
You're the blue team, attacking the **top** goal. Two halves of 90 seconds;
halftime swaps kickoff. Simply running within reach of the ball takes it —
that *is* the tackle — but a dispossessed player is locked out for 2 seconds.
Goals are 64 px wide, open, and recessed; the ball bounces off edges and goal
backs. Best score wins; draws are recorded. The persistent **W/D/L record**
on the menu is your progression; EASY/HARD is a toggle, not an in-match ramp.

**The AI**
- Players only join play when the ball is near their home patch; otherwise they trot home.
- 1 (EASY) or 2 (HARD) nearest opponents chase your carrier, aiming *ahead* of your facing to cut you off.
- The CPU carrier steers along a cost field that avoids its own goal and pushes upfield; it shoots from within ~170 px of your goal when the lane is clear.
- The CPU can't pass until a patience timer expires (**2.4 s EASY / 1.2 s HARD**) and only through open lanes.

**Tips**
1. Without the ball you outrun everyone — on HARD, pass early rather than dribble through pressure.
2. The instant an opponent takes the ball, **B**-switch and run through them before their patience timer lets them pass.
3. Kick power maxes after 0.4 s — charge while running, release inside 170 px facing the goal.
4. Chain quick passes up the wing; the CPU only blocks lanes it's already standing in.
5. After being tackled you're frozen for 2 seconds — **B**-switch, don't chase with the same player.
6. Square up before shooting: wide-angle shots rebound off the goal frame.

---

## Kinetix

*Brick breaker: the crank is the bat, A serves the ball.* (Vol 2)

The Arkanoid formula rebuilt for the Playdate. A 320-wide arena with an open
bottom — anything past the bat is gone. Clear the bricks, sweep up the
capsules they shed, and ride your bat out through the exit portal to escape
each level.

**Controls**
- **Crank** — moves the bat (a full turn spans the field). **Left/Right** are an 8 px/frame fallback.
- **A (press)** — serve / release a held ball; start; dismiss game over (after 1 second).
- **A (hold)** — fire when the bat has the Gun form.

**How to play**
Serve with A, keep the ball alive, break every brick. Where the ball hits the
bat sets its outgoing angle — clip the very end and it deflects nearly
horizontal *and* gains +4 speed. The ball creeps faster over time, and
**twice as fast if it hasn't touched the bat in 5 seconds**. Destroy the last
breakable brick (or catch a Portal capsule) to open the exit portal in the
right wall, then slide the bat out through it to advance.

**Bricks**
- **Normal** — one hit, 10 points, 20% chance to drop a capsule.
- **Armored** — first hit dents it, second breaks it.
- **Metal** — unbreakable; if the ball is trapped with no contact for 30 s, all metal softens to armored.

**Scoring & progression** — **10 points per brick**; **3 starting lives**;
**6 layouts** looping forever. High score persists.

**Power-up capsules** (20% drop, one bat form at a time)
- **Extend** — wider bat. **Shrink** — *smaller* bat (a trap).
- **Gun** — twin lasers; hold A to fire.
- **Magnet** — the ball sticks; press A to re-serve with fresh aim.
- **Multiball** — every ball splits into three.
- **Fast** — all balls +3 speed (a trap). **Slow** — all balls −3 speed.
- **Extra Life** — +1 life (rarest).
- **Portal** — opens the exit immediately (only appears once ≤20 breakable bricks remain, then it's the likeliest drop).

**Tips**
1. Grab **Slow** when the ball is fast — it undoes minutes of speed creep.
2. Return the ball to the bat often: 5 s without contact doubles the speed-up clock.
3. Never catch with the bat's tip — an end-clip adds +4 speed and the flattest, hardest trajectory.
4. Take a **Portal** capsule to skip stragglers (at the cost of 10 pts each).
5. Ball walled in behind metal? Just wait 30 s — the metal softens and frees it.
6. Losing a ball resets the bat to Normal — spend a Gun before you spend a life.

---

## Avenger

*Defender-style shooter: thrust, flip, rescue the humans, clear the waves.* (Vol 2)

Landers descend on your ten ground colonists and try to haul them into the
sky. Let one reach the top and it comes back as a fast, furious mutant that
hunts you across the whole wrapping world. Pods, baiters, and swarmers pile
on as the waves escalate.

**Controls**
- **Up/Down** — altitude (also tilts your laser aim).
- **Left/Right** — face that way and thrust (momentum-based).
- **A** — fire. **B** — instant flip of facing.
- **Crank** — fine altitude trim. Menus: **A or B** to start.

**How to play**
A lander drops onto a colonist, grabs them, and hauls them straight up.
Shoot the lander to release the human, then fly within range to **catch**
them mid-air and carry them down to solid ground (touching ground drops them
safely). A human that falls too fast **dies on impact** — catch early. If a
carrier reaches the sky with its captive, the human dies and a **mutant**
spawns in its place. A wave clears once the sky is empty.

**Scoring, lives & progression**
- **Every enemy killed = 150 points** (all types).
- Start with **5 lives** and **5 shields**; each hit costs a shield, and losing the last one costs a life.
- Each wave restores one shield per two surviving humans. Save **all ten** humans for an extra-life token; **3 tokens = 1 life**.
- Waves add landers and pods; every 5th is baiters + mutants, every 10th swaps in swarmers.

**Enemies**
- **Lander** — the abductor; slow, only chases you up close.
- **Mutant** — fast and aggressive; spawned from a lost human. Chases you anywhere.
- **Baiter** — the camper-punisher; fires a slow rotating spiral of bullets.
- **Pod** — drifts harmlessly, then **bursts into 3 swarmers** when shot.
- **Swarmer** — tiny and erratic, very high acceleration.

**Tips**
1. Shoot carriers early (they haul slowly), then dive to catch the falling human high.
2. Never let a human reach the sky — mutants are far nastier than landers.
3. Aim with the up/down tilt to line shots up with a target's altitude.
4. Keep moving — camping summons a baiter every ~30 seconds.
5. Rescue all ten for the token payoff; partial saves still restore shields.
6. Snipe distant carriers from just outside their firing band (landers only fire at 50–150 px).

---

## Eggzy

*Climb the ladders, grab every gem before the clock runs out, and escape through the door.* (Vol 2)

A single-screen ladders-and-gems platformer across forest and castle biomes.
The clock is brutally short, so you sweep gems in fluid lines, stomp the
wildlife for bonus seconds, and dive through the door the instant the last
gem pops.

**Controls**
- **Left/Right** — run. **Up/Down** — climb ladders (when landed).
- **A** — jump; hold for height, release early for a short hop (jump input is buffered, with coyote time). No B, no crank.
- Menus: **A** advances Title → Controls → Play; returns to title on game over.

**How to play**
The clock starts at **30 seconds**. Platforms are one-way (land on tops).
Collect **all gems** to swing the exit door open, then reach it to clear the
level. The clock hitting 0 costs a life; falling out the bottom respawns you
at the start. Levels cycle forever through 6 layouts.

**Scoring, lives & progression**
- **Gem: 100 × combo** — the combo climbs for each gem grabbed within a 3-second window, so smooth gem lines score far more than one at a time.
- **Stomp kill: 200.** **Level clear: 500 + 10 per second left.**
- **Time bonuses:** each gem refunds time (+2 s on the first loop, less later); each enemy killed adds +3 s.
- **3 starting lives.** High score persists.

**Enemies**
- **Walker** — patrols a platform, reverses at edges. Castle robots take 2 stomps (the first just bounces you).
- **Flyer** — sweeps horizontally; from the 3rd loop (level 13+) it also moves diagonally.
- **Stomp** the top of an enemy to kill it (bounces you up, +200, +3 s). Any other contact kills you.

**Tips**
1. Chain gems within the 3-second combo window — plan routes, don't wander.
2. The clock is the real boss: gems and stomps both feed time back.
3. Castle walkers take two stomps — line up the second hit or avoid them.
4. Abuse coyote time and jump buffering for precise short hops.
5. Early flyers are predictable horizontal sweepers; the dangerous diagonal ones don't appear until level 13+ — bank score before then.
6. Drop onto walkers from above; the stomp zone is generous while you're falling.

---

## Leading Edge

*Pseudo-3D night racing: crank to steer, A to accelerate, B to brake.* (Vol 2)

Twenty cars on a floodlit night circuit. You start well back and have to
carve to the front of a nineteen-rival pack. The corners are a beautiful
lie — the road never actually turns, it shoves your car sideways and scrolls
the skyline, and your steering only fights that shove.

**Controls**
- **Crank** — primary steering. **Left/Right** — full-lock fallback (stacks with crank).
- **A** — accelerate. **B** — brake.
- Title / results: **A or B** to start / continue.

**How to play**
A 4-second countdown, then the pack releases. Your **position** is your place
in the field each frame (1 = leader); passing a car fires an overtake jingle.
Cross the start/finish gantry to count a lap. Drift onto the grass and drag
bleeds your speed; clip a lamp post or billboard and you explode and reset to
center.

**Scoring & progression**
- **5 laps**, with a **240-second-per-lap limit** (exceed it and the race ends "TIME UP!").
- The results screen shows finishing position, fastest lap, and race time; **fastest lap and total race time persist as records**.
- It's a single grid-to-flag race — finish as high as you can (P1 ideal).

**Hazards & rivals**
- **Corner grip loss** above 50 speed if you steer *into* the corner's push — you skid wide and lose steering.
- **Lamps and billboards** at the roadside explode you on contact.
- **Car collisions:** side-swipes shove both apart; rear-ending caps your speed; being rear-ended gives *you* free speed.
- **Rivals** run 40–65 target speed, change lanes toward gaps, and obey per-corner speed caps.

**Tips**
1. Exit corners hard — acceleration is highest at low speed, so full throttle out of a bend claws speed back fastest.
2. Don't steer *into* a fast bend; counter-steer the push or ease off with B.
3. Brake for the big right-hander — even the rivals slow there.
4. Stay on tarmac; grass drag bleeds speed roughly twice as fast.
5. A shunt from behind is a free speed boost — in a tight pack it can be net-positive.
6. The road is straight: chase the racing line (keep centered), not the horizon.

---

## Beat Streets

*A side-scrolling brawler: punch, kick, and fight your way down the street.* (Vol 2)

The high street and the warehouse blocks have fallen to thugs, and the city's
only cleanup crew is your fists. Walk right, follow the flashing GO arrow into
locked-in brawls, and chain punches into an uppercut until every wave is flat.

**Controls**
- **D-pad** — 8-way walking (left/right along the street, up/down through depth).
- **A** — punch; tap in rhythm to chain punch → punch → uppercut.
- **B** — kick; **B while holding left/right** — flying jump kick (uninterruptible).
- Menus: **A or B** to start / restart / continue. No crank.

**How to play**
Walk right until the GO arrow appears; the screen locks and a wave spawns.
Beat every enemy to advance. Getting hit interrupts your attack (except a
jump kick). Knocked-down fighters are briefly invincible, then get up. You
have **30 HP** and **3 lives**; losing a life refills your health. Break
barrels for points and a guaranteed health drop; walk over pickups for +10 HP.
Beat **wave 5 of stage 2** to win.

**Scoring & progression**
- Thug **20**, heavy **40**, stage-1 boss **75**, stage-2 boss **100**, barrel **5**.
- **2 stages × 5 waves**, each stage ending in a heavy boss. High score persists.

**Enemies**
- **Thug** — 6 HP, two quick 1-damage punches.
- **Heavy** — 12 HP (more as a boss), slower but a 2-damage punch and kick with longer reach.
- **Crowd behavior:** only 2 enemies press you at once; the rest flank, hang back, or pause. They only swing when aligned with your depth.

**Tips**
1. Depth-dodge everything — enemies only swing when level with your y, so a single up/down tap blanks their attack.
2. Knockdowns are crowd control: an uppercut or jump kick removes an enemy from the fight for a moment — don't waste swings on downed bodies.
3. The **jump kick** is your panic button: 3 damage, a knockdown, and it can't be interrupted.
4. Don't trade with heavies at their range — step in diagonally rather than straight at them.
5. Bank the barrels — each guarantees a health drop.
6. On boss waves, drop the first escort thug before the stragglers walk in; only two will press you anyway.

---

*Part of [Classics](README.md). See [DEVGUIDE.md](DEVGUIDE.md) for the
shared core and build system. A derivative work of* Code the Classics
*(Raspberry Pi Press) under BSD 3-clause terms — see
[LICENSE](LICENSE).*
