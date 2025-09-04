Minetest Game mod: map
======================
See license.txt for license information.

Authors of source code
----------------------
paramat (MIT)

Authors of media (textures)
---------------------------
TumeniNodes (CC BY-SA 3.0):
  map_mapping_kit.png (map)

paramat (CC BY-SA 3.0):
  map_mapping_kit.png (compass and pen)

Crafting
--------
map:mapping_kit

default:glass G
default:paper P
group:stick S
default:steel_ingot I
group:wood W
dye:black D

GPS
IPI
WPD

Usage
-----
In survival mode, use of the minimap requires the mapping kit item in your
inventory. It can take up to 5 seconds for adding to or removal from inventory
to have an effect, however to instantly allow the use of the minimap 'use'
(leftclick) the item.
Minimap radar mode is always disallowed in survival mode.

Minimap and minimap radar mode are automatically allowed in creative mode and
for any player with the 'creative' privilege.

The 'map.update_hud_flags()' function is global so can be redefined by a mod for
alternative behaviour.
