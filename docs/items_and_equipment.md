# Items and equipment

`lib/inventory/item_catalog.dart` indexes every game item by its stable ID.
Definitions live in `item.dart`; add each new definition to the catalog.
The demo bag starts with one Meat and two Moonless necklaces.

Tapping any bag row opens its name, icon, description, and CLOSE button.
Equipment also offers EQUIP, followed by a party creature picker. Closing or
dismissing this dialog does not change the bag. The dialog uses the exploration
window's navigator so changing windows also dismisses it.

Each creature has one equipment slot. `Creature.equipFrom` transfers one copy
from the bag, returns replaced gear, and rejects missing items, non-equipment,
and repeated equips of the same item. `unequipTo` returns gear to the bag.
The Moonless necklace grants flat +5 CON and +5 SPE. These bonuses are computed
separately from base stats and allocated points, appear in party details, and
are included in battle stats. Changing maximum HP preserves damage taken;
knocked-out creatures remain at zero HP.

Stat totals have a tappable `(?)` link. Breakdowns list base, allocation,
equipment, and individual combat sources in rows, with the total under a divider.
Combat effects must use `BattleCreature.changeStat` with their move or ability
name. It accumulates actual applied changes per source (after caps and floors),
removes sources whose net contribution becomes zero, and exposes an immutable
snapshot through `statChanges` for the inspection window.

The prototype keeps inventory and party state in memory; equipment follows
the same lifetime as the existing party.
