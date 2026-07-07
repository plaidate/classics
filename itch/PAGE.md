# Classics

**Ten Code the Classics games, rebuilt for the Playdate on one shared core.**

Both volumes of Raspberry Pi Press's *Code the Classics* — ten arcade
designs — reimagined for the Playdate's 400×240 1-bit screen. Every game
is an original Lua implementation written from scratch, sharing a single
core library, and driving the books' own artwork and audio converted for
the crank-handled little yellow console. Pong, Frogger, Centipede,
Arkanoid, Defender, a top-down football, a night racer, a gem-grab
platformer, a bubble-trap platformer, and a street brawler — one download
per game.

Some games make the crank their headline control: it's the bat in **Boing**
and **Kinetix**, the steering wheel in **Leading Edge**, an altitude trim
in **Avenger**, and a fine-aim nudge in **Myriapod**. Others are pure
d-pad-and-buttons arcade action. Each keeps its own high score or record on
the device, and all ten play on both hardware and the Simulator.

## The games

- **Boing** — Pong-style table tennis; crank bat, 1P vs the AI or 2P on one Playdate. (Vol 1)
- **Cavern** — trap robots in orbs, pop them into fruit; single-screen platformer. (Vol 1)
- **Bunner** — endless Frogger-style road and river crosser with an impatient eagle. (Vol 1)
- **Myriapod** — Centipede-style shooter; split the chain, mind the spider. (Vol 1)
- **Sunday Soccer** — top-down 7-a-side football with open goals and a persistent record. (Vol 1)
- **Kinetix** — Arkanoid-style brick breaker; crank bat, nine power-up capsules. (Vol 2)
- **Avenger** — Defender-style rescue shooter over a wrapping landscape. (Vol 2)
- **Eggzy** — grab every gem against a brutal clock, then bolt for the door. (Vol 2)
- **Leading Edge** — pseudo-3D night racer; crank steers over five laps. (Vol 2)
- **Beat Streets** — side-scrolling brawler; punch, kick, and jump-kick down the street. (Vol 2)

## Controls (summary)

D-pad and A/B across the board; several games add the crank (bat, wheel, or
fine trim). Each game shows its own controls on its title/help screen — see
the [manual](https://github.com/plaidate/classics/blob/main/MANUAL.md) for
the full per-game breakdown.

## Installing (no dev tools needed)

Each game ships as its own `.pdx`. Download the one you want from the
Releases page (or from `dist/` in the source), then:

- **On a Playdate**: zip the `.pdx` if your browser needs a single file,
  sideload it at <https://play.date/account/sideload/>, and download it to
  the device from Settings → Games.
- **In the Playdate Simulator** (ships with the free
  [Playdate SDK](https://play.date/dev/)): open the `.pdx` directly, or drag
  it onto the Simulator window.

High scores and records save per game on the device.

## Credits & licensing

A derivative work of *Code the Classics* (Raspberry Pi Press), reimplemented
for the Playdate and licensed under the same BSD 3-clause terms. The
original books, artwork, and audio are copyright 2019 Eben Upton. Volume 2
content: games by **Andrew Gillett** with **Eben Upton** and
**Sean M. Tracey**, graphics by **Dan Malone**, audio by
**Allister Brimble**. With thanks to Raspberry Pi Press for publishing the
*Code the Classics* series.
