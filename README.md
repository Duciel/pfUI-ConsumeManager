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

The group button shows its default. Without a default
it is greyed out and shows how many of the group you carry. A group whose *Show* box is ticked always has a
button, default or not (unless *Hide consumables you don't carry* is on and you carry none of it). The *Show* checkbox next to each group's dropdown in the config hides a group (Off Hand and Tea are off by default), and
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
| Blasted Lands | Ground Scorpok Assay, R.O.I.D.S., Cerebral Cortex Compound, Lung Juice Cocktail, Gizzard Gum |
| Tea | Nordanaar Herbal Tea, Tea With Sugar |

**Stackable** consumables each get a checkbox and their own button: elixirs (Mongoose, Greater Arcane,
Superior Defense, Mageblood, Dreamshard, Dreamtonic, Greater Firepower, Greater Nature Power, Shadow Power,
Frost Power, Fortitude, Major Troll's Blood, Demonslaying), concoctions and protection potions. Potions & Utility go on the potion bar (below).

## The buttons
- green border + timer: the buff is up
- orange border: the buff has less than *Refresh when less than X minutes left* (default 2)
- grey icon: the buff is missing; red icon: none in your bags
- **glow**: every buff-bar button (groups, elixirs, concoctions...) pulses while its buff is missing or
  about to run out, as long as you have some in your bags (out of stock stays red, no glow). Protection
  potions and the potion bar never glow.
- bottom right: how many you carry; for items with charges (oils, stones) the total charges left; cooldown
  wheel for potions
- using an item takes the one with the fewest charges left (oils, stones) or the smallest stack first

*Hide buttons while their buff is up* turns the bar into a "what am I missing" bar. Potions and protection
potions are never hidden that way (they are used on demand).

## Potion bar
*Potions & Utility* (healing / mana potions, runes, Stoneshield, Free Action, LIP, Quickness, Restorative,
Swiftness, Invisibility / Lesser Invisibility, Anti-Venom, Jungle Remedy, Holy Water, bandages, Frozen Rune...) are used reactively, so they have
their own bar, shown **all the time** by default, in and out of combat (or *In Combat Only*). Tick the ones you want under *Potion Bar* in the
config. **Regen Food** (Conjured Mana Orange, Juicy Kezan Fruitcake, Graccu's Mince Meat Fruitcake: one at a
time) is an exclusive group on the potion bar, with a default dropdown and a hover list like the food group.
The potion bar has its own layout options (size, columns / rows, direction).

The buff bar has **Hide In Combat** (on by default) at the top of the config, so in a fight you only see the
potion bar. Both bars stay visible in pfUI's unlock mode so you can move them.

## Use next missing
Key binding *pfUI Consume Manager → Use next missing consumable* or `/cm next` uses the first persistent
buff (flask, food, alcohol, zanza, Blasted Lands, elixirs, weapon oil / stone) you are missing or that is
about to run out. One item per key press. Weapon oils / stones are applied to the right weapon and the
"replace enchant" confirmation is accepted for you.

## Buff detection
With [nampower](https://github.com/brues-code/nampower) the buff is found through the item's spell id, so it
works for any client language and for Turtle WoW custom items. Without it, the buff name is used. When
neither works, the buff is **learned** the first time you use the item from the bar (the new buff that shows
up right after). `/cm forget <item>` forgets a learned buff.

Turtle WoW custom items have no item id in the addon: they are found by name (exact, or the start of the
name, so *Medivh's Merlot Blue* also finds *Medivh's Merlot Blue Label*), and their id is remembered.

## Macros
Each command uses **one** missing item per key press (the game won't take more), so press it until
nothing is missing. A buff counts as missing when it is not on you or has less than *Refresh when less than
X minutes left*. Food is skipped in combat (you can't eat).

| Macro | Uses |
| --- | --- |
| `/cm food` | your default food |
| `/cm weapon` | the main hand, then the off hand enchant |
| `/cm all` | everything else on the buff bar: flask, alcohol, Zanza, strength / attack power, Blasted Lands, elixirs, concoctions |
| `/cm food weapon all` | any combination, in the order you write it (`/cm weapon,food` works too) |
| `/cm next` | everything, in bar order (same as the key binding) |

## Lua API (for other addons and `/run`)
| Function | Returns |
| --- | --- |
| `pfConsumeManager.UseFood()` | `true, itemName` when it used something, `false` otherwise |
| `pfConsumeManager.UseWeapon()` | same |
| `pfConsumeManager.UseAll()` | same |
| `pfConsumeManager.UseNext(spec)` | same; `spec` = `nil` (everything), `"food,weapon"` or `{ "food", "all" }` |
| `pfConsumeManager.GetMissing(spec)` | list of `{ name, category, kind, count, left }` (`left` = `false` when not on you, else the seconds left) |
| `pfConsumeManager.IsReady(spec)` | `true` when nothing of `spec` is missing |
| `pfConsumeManager.Use(name)` | use an item by name, e.g. `"mongoose"` |
| `pfConsumeManager.Select(group, name)` | set a group's default, e.g. `("flask", "titans")`, `("food", "none")` |
| `pfConsumeManager.Refresh()` | rebuild the bars |

`kind` is `"food"`, `"weapon"` or `"all"`. Example:
`/run if not pfConsumeManager.UseNext("weapon,food") then CastSpellByName("Arcane Intellect") end`

## Commands
`/consumemanager` (aliases `/cm`, `/consumes`)

| Command | Effect |
| --- | --- |
| `/cm next` / `food` / `weapon` / `all` | use a missing buff (see Macros) |
| `/cm use <item>` | e.g. `/cm use mongoose` |
| `/cm set <group> <item\|none>` | e.g. `/cm set flask titans`, `/cm set mainhand wizard`, `/cm set food none` |
| `/cm missing` / `list` | list missing buffs / the whole selection |
| `/cm forget [item]` | forget learned buffs |
| `/cm scan` | rescan your bags |

Config: `/pfui` → Thirdparty → Consume Manager (bar shown always / in a group / in a raid / in an instance,
layout: buttons per row, or a fixed number of rows and the columns follow...). Move the bar with pfUI's unlock mode.

## Install
Copy the `pfUI-ConsumeManager` folder into `Interface\AddOns`. Requires [pfUI](https://github.com/brues-code/pfUI).
[nampower](https://github.com/brues-code/nampower) is optional but recommended.
