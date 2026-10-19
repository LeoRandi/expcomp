# Story planning

Provisional world and opening story supplied by the author on 2026-10-19.
This reference combines the original town lore with the expanded story draft.
The [full author draft](story_draft.md) is preserved separately, without edits.
Story beats below are plans; the implemented town is described at the end.

## Town name

The hometown is **Cresca**. Use this spelling throughout the lore, dialogue,
UI text, documentation, and tests.

## The world before the tunnels

Humanoids once inhabited the surface: valleys, plains, mountains, and deserts.
Stories passed through many generations describe life without a ceiling,
with abundant light and warmer air.

One day, enormous columns of dark, unbreakable material fell from the stars and
pierced the ground, the sacred god Ga. These columns became known as **Needles**.
People disagree about their origin: some say a god was cast down as punishment;
others believe the world's inhabitants were being punished. Neither explanation
is established as fact.

The Needles contained unfamiliar beasts, demons, spirits, and other humanoids.
Their creatures poured out, destroying settlements and devouring everything in
their path. Kingdoms, countries, and entire continents fell within a week.

Survivors used cracks made by the Needles to escape underground. Vast caves,
caverns, and tunnels became humanity's refuge. Surface entrances were blocked,
barricaded, or sealed with explosives, beginning the dark ages below ground.

## The Safe Web

Humanity learned to live underground. Some towns established contact and a
relatively safe network of trade, known as the **Safe Web**. People survived and
sometimes almost thrived, but the invasion never fully stopped. Creatures can
find their way into the caves or escape from damaged Needles deep underground.

The hometown lies near the western edge of the Safe Web. Merchant caravans visit
about twice a year. It produces herbs and bread and has a rare clean well whose
water seems inexhaustible. It is the only safe place for quite some miles.

The roads connect toward **Lubia** in the north, **Fern** in the east, and
**Furion** in the south. Some contact with the south and east has survived.

## What townsfolk know at the beginning

- Humanity lives underground; tales of the former surface have been passed down.
- Dangerous animals, beasts, and monsters from old tales have lately been filling
  the tunnels.
- The north route to Lubia is unavailable after rumblings caused collapses.
- The town is trying to discover another safe northern route.
- News and trade still reach the town from the south and east.
- The old Lubia destination sign has been crossed out and marked KEEP OUT.

The town's proximity to a Needle and the immediate source of these new creatures
are initially unknown to its inhabitants. NPC dialogue must not reveal those
facts as common knowledge before the player's discoveries.

## Hidden situation north of town

The hometown is closer to a Needle than any other underground town, although its
inhabitants do not yet know this. About halfway along the northern caverns toward
Lubia, a small crevice in the tunnel's eastern wall leads toward a Needle's point.

Rumblings have broken part of that Needle's side. Small monsters are escaping
through the breach. The same disturbances have collapsed passages and cut the
connection between the hometown and Lubia. A party is forming to find a new way
through. The routes to Fern and Furion are also becoming infested by creatures
coming from the Needle.

## Junto and the protagonist

Junto is the protagonist's father and the village's only resident without a
stable job. He takes whatever work he can find. His old, unattended farm lies
west of town; the protagonist has never tried to tend it.

Junto takes responsibility for finding another path to Lubia, but never returns.
His son or daughter, the player, follows him north, hoping to find him and perhaps
restore the connection to Lubia.

The player takes their father's backpack. Unknown to them, it contains a small,
ball-like metal creature: a robot companion.

## Opening story sequence

1. Junto leaves to find a route to Lubia and goes missing. The player takes his
   backpack and sets off north to look for him.
2. Collapsed tunnels repeatedly block the way. Eventually the only way forward
   is the small crevice in the eastern tunnel wall.
3. A bat-like monster attacks inside the crevice, introducing the first creature
   battle. The robot emerges from the backpack to save the player and bonds
   with them.
4. After the fight, the robot introduces itself and agrees to accompany the
   player while they search for Junto.
5. Further exploration reveals the Needle entrance and a clue suggesting Junto
   had to hide inside it. The player retreats to the hometown.
6. At the inn, the player tells the guard and innkeeper what happened. They argue
   about whether to send someone else north to find the route to Lubia.
7. The player prepares and returns north independently, beginning repeated trips
   between the hometown and the Needle while searching for their father.
8. The player can also visit Fern and Furion, whose approaches are now dangerous.
   After growing strong enough, they enter the Needle itself.
9. The first Needle dungeon has one floor, traps, unfamiliar monsters, loot, and
   a pseudo-dragon boss. Defeating it makes the floor appear to heal and light up;
   monsters become much less frequent.

The draft does not yet establish Junto's eventual fate or exactly what the clue
at the Needle entrance is. Defeating the first boss must not automatically be
written as rescuing Junto without further story planning.

## Early game loop and progression

- Travel between the hometown and the Needle, preparing, exploring, fighting,
  and returning as needed. Escaped creatures make the connecting tunnels unsafe.
- Bond with creatures. Some defeated creatures drop meat or gems; some creatures
  ask to be adopted in exchange for meat, gems, or other as-yet unspecified items.
- Visit neighbouring towns while building enough strength to enter the Needle.
- The initial creature level cap is **5**. Defeating the first pseudo-dragon
  raises it to **10**, for current and future companions.
- Each qualifying boss or strong-creature victory raises the cap by another
  **5 levels**. Experience allows creatures to grow up to the new cap; it does
  not automatically grant those levels.

Which strong creatures qualify, and how repeated victories affect the cap, have
not yet been specified.

## Current town implementation

The playable prototype starts the protagonist outside their home. It has not yet
implemented Junto's departure, the backpack discovery, the scripted bat encounter,
the Needle dungeon, or the story-driven level-cap progression above.

The residents' everyday roles and relationships are local additions: Mara bakes,
Ivo lights the streets, Tamsin watches the northern approach, Nessa tends herbs,
Pell runs deliveries, and Elin keeps the Resting Lantern inn. Tamsin warns
travellers at the north road's entrance. The inn is the planned location for the
conversation with the guard and innkeeper after discovering the Needle.

Junto's farm is enclosed by old fences and a shut gate. Its entrance sign names
JUNTO'S FARM and conveys the protagonist's observation about the neglected fences.
The outer-road signs point toward Lubia, Fern, and Furion.

A veiled stranger beside the protagonist's home offers transport to the testing
grounds. A Waykeeper there returns the player home. These remain development
travel links; their identities, powers, and place in the story are undecided.
The sparring NPC remains in the testing grounds.

## Details still open

- The true origin of the Needles and the competing explanations about punishment.
- The robot's name, origin, and relationship to Junto before the backpack reveal.
- The clue suggesting Junto entered the Needle, his fate, and the later main plot.
- Why defeating a boss heals and illuminates a Needle floor.
- The exact rules for qualifying level-cap increases and additional adoption items.
