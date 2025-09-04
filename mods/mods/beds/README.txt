Minetest Game mod: beds
=======================
See license.txt for license information.

Authors of source code
----------------------
Originally by BlockMen (MIT)
Various Minetest Game developers and contributors (MIT)

Authors of media (textures)
---------------------------
BlockMen (CC BY-SA 3.0)
 All textures unless otherwise noted

TumeniNodes (CC BY-SA 3.0)
 beds_bed_under.png

This mod adds a bed which allows players to skip the night.
To sleep, right click on the bed. If playing in singleplayer mode the night gets skipped
immediately. If playing multiplayer you get shown how many other players are in bed too,
if all players are sleeping the night gets skipped. The night skip can be forced if more
than half of the players are lying in bed and use this option.

Another feature is a controlled respawning. If you have slept in bed (not just lying in
it) your respawn point is set to the beds location and you will respawn there after
death.
You can disable the respawn at beds by setting "enable_bed_respawn = false" in
minetest.conf.
You can disable the night skip feature by setting "enable_bed_night_skip = false" in
minetest.conf or by using the /set command in-game.
