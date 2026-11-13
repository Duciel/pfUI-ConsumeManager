# pfUI-ConsumeManager

A [pfUI](https://github.com/brues-code/pfUI) third-party module that keeps your raid consumables on one bar
(WoW 1.12 / OctoWoW / Turtle WoW), modelled on pfUI-TotemBar and pfUI-PaladinBar.

The list comes from the Oathsworn *Raid Consumables & Items Guide* (general raid list plus the BWL, AQ40,
Naxxramas and Kara40 extras).

## Exclusive and stackable consumables
**Exclusive** groups: only one buff of the group can be on you, so the bar has one button per group.
Hover it to open the list of **every** consumable of the group with how many you carry (items in your bags
first, red 0 for the others):
**left-click** uses it, **right-click** makes it the group's **default** (green outline in the list). The bar
button shows the default; left-click it to use the default. Right-clicking the bar button pins the list open.

The group button **glows** while its default's buff is not on you (or is about to run out). Without a default
it is greyed out and shows how many of the group you carry; a group with no default and nothing in your bags
has no button. *Show <group> button* in the config hides a group (Off Hand and Tea are off by default), and
the default can also be picked in the config dropdowns or with `/cm set`.

| Group | Items |
| --- | --- |
| Flask | Titans, Distilled Wisdom, Supreme Power, Chromatic Resistance |
| Food | Le Fishe Au Chocolat, Dirge's Chimaerok Chops, Empowering Herbal Salad, Nightfin Soup, Sour Mountain Berries, Squid Eel Skewer, Grilled Squid, Power Mushroom, Hardened Mushroom, Smoked Desert Dumplings, Mightfish Steak, Danonzo's Tel'Abim Delight / Surprise, Runn Tum Tuber Surprise |
| Alcohol | Rumsey Rum Black Label, Medivh's Merlot, Medivh's Merlot Blue |
| Zanza | Spirit, Swiftness, Sheen of Zanza |
| Strength | Elixir of Giants, Juju Power |
| Attack Power | Winterfall Firewater, Juju Might |
| Main Hand / Off Hand | Brilliant Wizard / Mana Oil, Elemental / Consecrated / Dense Sharpening Stone, Blessed Wizard Oil, Frost Oil, Shadow Oil, Dense Weightstone |
| Tea | Nordanaar Herbal Tea, Tea With Sugar |

**Stackable** consumables each get a checkbox and their own button: elixirs (Mongoose, Greater Arcane,
Superior Defense, Mageblood, Dreamshard, Dreamtonic, Greater Firepower, Greater Nature Power, Shadow Power,
Frost Power, Fortitude, Major Troll's Blood, Demonslaying), Blasted Lands buffs (Scorpok, R.O.I.D.S.,
Cerebral Cortex, Lung Juice, Gizzard Gum), concoctions, protection potions and potions / utility
(Stoneshield, Free Action, LIP, Quickness, Restorative, healing / mana potions, runes, Anti-Venom,
Jungle Remedy, Holy Water, bandages, Frozen Rune...).

## The buttons
- green border + timer: the buff is up
- orange border: the buff has less than *Refresh when less than X minutes left* (default 2)
- grey icon: the buff is missing; red icon: none in your bags
- bottom right: how many you carry; cooldown wheel for potions

*Hide buttons while their buff is up* turns the bar into a "what am I missing" bar. Potions and protection
potions are never hidden that way (they are used on demand).

## Use next missing
Key binding *pfUI Consume Manager → Use next missing consumable* or `/cm next` uses the first persistent
buff (flask, food, alcohol, zanza, elixirs, Blasted Lands, weapon oil / stone) you are missing or that is
about to run out. One item per key press. Weapon oils / stones are applied to the right weapon and the
"replace enchant" confirmation is accepted for you.

## Buff detection
With [nampower](https://github.com/brues-code/nampower) the buff is found through the item's spell id, so it
works for any client language and for Turtle WoW custom items. Without it, the buff name is used. When
neither works, the buff is **learned** the first time you use the item from the bar (the new buff that shows
up right after). `/cm forget <item>` forgets a learned buff.

Turtle WoW custom items have no item id in the addon: they are found by name (exact, or the start of the
name, so *Medivh's Merlot Blue* also finds *Medivh's Merlot Blue Label*), and their id is remembered.

## Commands
`/consumemanager` (aliases `/cm`, `/consumes`)

| Command | Effect |
| --- | --- |
| `/cm next` | use the first missing persistent buff |
| `/cm use <item>` | e.g. `/cm use mongoose` |
| `/cm set <group> <item\|none>` | e.g. `/cm set flask titans`, `/cm set mainhand wizard`, `/cm set food none` |
| `/cm missing` / `list` | list missing buffs / the whole selection |
| `/cm forget [item]` | forget learned buffs |
| `/cm scan` | rescan your bags |

For macros: `pfConsumeManager.UseNext()` returns `true, itemName` when it used something.

Config: `/pfui` → Thirdparty → Consume Manager (bar shown always / in a group / in a raid / in an instance,
layout, buttons per row...). Move the bar with pfUI's unlock mode.

## Install
Copy the `pfUI-ConsumeManager` folder into `Interface\AddOns`. Requires [pfUI](https://github.com/brues-code/pfUI).
[nampower](https://github.com/brues-code/nampower) is optional but recommended.
