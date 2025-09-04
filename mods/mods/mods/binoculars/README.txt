Minetest Game mod: binoculars
=============================
See license.txt for license information.

Authors of source code
----------------------
paramat (MIT)

Authors of media (textures)
---------------------------
paramat (CC BY-SA 3.0):
  binoculars_binoculars.png

Crafting
--------
binoculars:binoculars

default:obsidian_glass O
default:bronze_ingot B

O_O
BBB
O_O

Usage
-----
In survival mode, use of zoom requires the binoculars item in your inventory,
they will allow a 10 degree field of view.
It can take up to 5 seconds for adding to or removal from inventory to have an
effect, however to instantly allow the use of this zoom 'use' (leftclick) the
item.

Zoom with a field of view of 15 degrees is automatically allowed in creative
mode and for any player with the 'creative' privilege.

The 'binoculars.update_player_property()' function is global so can be
redefined by a mod for alternative behaviour.
