# Classics

Both volumes of Code the Classics, ported to Playdate as original Lua
implementations sharing one core library — game logic written from scratch,
driving the books' converted artwork and audio.

Licensing: the Code the Classics content (including artwork and audio,
converted here for the Playdate's 1-bit display) is copyright 2019
Eben Upton and licensed under BSD terms — see LICENSE-ASSETS, which the
Makefile also stages into every built pdx so binary redistribution
carries the notice, as the license requires. Volume 2 content credits:
games by Andrew Gillett with Eben Upton and Sean M. Tracey, graphics by
Dan Malone, audio by Allister Brimble. The Lua implementations are a
derivative work of Code the Classics
(https://github.com/raspberrypipress), reimplemented for the Playdate,
and are licensed under the same BSD terms (3-clause: the
upstream notice's body includes the no-endorsement clause despite its
header's 2-clause label): LICENSE covers the
whole work and retains the upstream copyright notice per its terms;
LICENSE-ASSETS preserves the upstream notice file verbatim.

Build: `make <game>` or `make all` -> out/<Title>.pdx
Verify: `make <game>-smoke && tools/smoke.sh <game> [secs] [until-grep]`

Volume 1: boing cavern bunner myriapod soccer
Volume 2: kinetix avenger eggzy leadingedge beatstreets
