# FrameSort — stock 3.3.5a

**FrameSort** (by **Verz**, packaged for 3.3.5 by **Tsoukie**) backported to
**stock World of Warcraft 3.3.5a / Wrath of the Lich King** (build 12340,
Lua 5.1, interface `30300`).

The upstream 3.3.5 version relied on the separate **`!!!ClassicAPI`** addon for
modern retail API. **This backport removes that dependency** — it is fully
self-contained and runs on a plain 3.3.5a client. It still requires the
[CompactRaidFrame backport](https://github.com/JedborgWoW/CompactRaidFrames-3.3.5a)
(that's the raid frame addon it sorts).

## Features

- Reorder the layout, placing the **player at the top, middle or bottom** of
  the party/raid frames.
- Sort remaining units by **group, role, or alphabetical** (with per-content
  rules for world, dungeon, raid and arena).
- Option to **hide the player unit** frame entirely.
- **Keybindings** to target units based on their *visual position* rather than
  their party number (`Target frame 1..5`, bottom frame, cycle next/previous).
- **Macro variables** — add a `#framesort` (or `#fs`) header to a macro and
  selectors like `@Frame1`, `@Healer`, `@Tank`, `@DPS`, `@BottomFrame` are
  rewritten live as the sorted order changes.
- Adjustable **spacing** between frames and between raid groups.
- **Secure in-combat sorting** or the lighter *Traditional* sorting mode.

## Commands

`/framesort`, `/fsort` or `/fs` opens the options (Interface → AddOns →
FrameSort). Note: some private clients claim `/fs` for their own frame-stack
debug tool — use `/framesort` or `/fsort` there.

## Installation

Copy the **`FrameSort`** folder (the addon, *not* the repo root) into your client:

```
<WoW 3.3.5a>\Interface\AddOns\FrameSort\
```

Also install the required **`CompactRaidFrame`** backport. Restart the client
(or `/reload`).

## What changed vs. upstream (the ClassicAPI decoupling)

- New **`Compat.lua`** (loaded first) provides the modern globals ClassicAPI
  used to supply, all guarded/additive: the MoP+ group API (`IsInRaid`,
  `GetNumGroupMembers`, …), a deep `CopyTable`, a full `C_Timer`
  (After/NewTimer/NewTicker) OnUpdate scheduler, `Mixin`/`CreateFromMixins`,
  `Clamp`, `SOUNDKIT` (mapped to the old 3.3.5a sound names), and
  `SetSize`/`GetSize` + `AdjustPointsOffset` widget-metatable additions.
- **LibStub** is now bundled (needed by the bundled LibUIDropDownMenu).
- **Roster changes re-sort again**: `GROUP_ROSTER_UPDATE` is a MoP+ event that
  never fires on 3.3.5a — the native `PARTY_MEMBERS_CHANGED` /
  `RAID_ROSTER_UPDATE` are now also registered.
- **Role sorting and `@Healer`/`@Tank`/`@DPS` macros work on 3.3.5a**: the
  native `UnitGroupRolesAssigned` returns three booleans here (LFG roles only),
  so a wrapper converts them to the modern role string and otherwise infers the
  role (pure-dps class, else talent inspection via the LibGroupTalents bundled
  with CompactRaidFrame).
- **LibUIDropDownMenu** patched for stock 3.3.5a: `EventRegistry` guarded, and
  menu backdrops applied via the native `SetBackdrop` (the retail backdrop
  templates don't exist here).

## Reporting issues

Report issues with **this backport** [here](https://github.com/JedborgWoW/FrameSort/issues).

## Credits

- [**Verz**](https://www.curseforge.com/members/verz/projects) — the original
  [FrameSort](https://www.curseforge.com/wow/addons/framesort).
- [**Tsoukie**](https://gitlab.com/Tsoukie/framesort-3.3.5) — the 3.3.5
  (ClassicAPI) adaptation this backport is based on.
- **Backport by Jedborg** — stock 3.3.5a decoupling (no ClassicAPI).
