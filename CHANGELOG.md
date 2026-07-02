# Changelog

All notable changes to this **stock 3.3.5a backport** of FrameSort.

## [1.2] — 2026-07-02

Decoupled Tsoukie's ClassicAPI-dependent FrameSort 1.2 so it runs
self-contained on a stock 3.3.5a client (CompactRaidFrame backport is still
required — it's the addon being sorted).

### Added
- **`Compat.lua`** (loaded first): guarded/additive shims for everything
  ClassicAPI used to provide — MoP+ group API (`IsInRaid`,
  `GetNumGroupMembers`, `GetNumSubgroupMembers`, `IsInGroup`), deep
  `CopyTable`, full `C_Timer` (After/NewTimer/NewTicker via one OnUpdate
  scheduler), `Mixin`/`CreateFromMixins`, `Clamp`, `SOUNDKIT` (old 3.3.5a
  string sound names, filled per key), and `SetSize`/`GetSize` +
  `AdjustPointsOffset` added to the widget metatables.
- Bundled **LibStub** (LibUIDropDownMenu needs it; nothing provided it
  without ClassicAPI).

### Fixed
- **Sorting never re-ran on roster changes** on stock: `GROUP_ROSTER_UPDATE`
  is MoP+ and never fires on 3.3.5a. The runner now also registers the native
  `PARTY_MEMBERS_CHANGED` and `RAID_ROSTER_UPDATE` events.
- **Role sorting and the `@Healer`/`@Tank`/`@DPS` macro selectors were dead**:
  3.3.5a's native `UnitGroupRolesAssigned` returns three booleans (LFG roles
  only), so the role-string comparisons silently never matched. The WoW facade
  now wraps it: LFG role if assigned, else pure-dps class → DAMAGER, else
  talent inference via LibGroupTalents (bundled with CompactRaidFrame),
  else NONE.
- **Dropdown menus errored on show/hide** (`EventRegistry` is retail-only) —
  guarded in the bundled LibUIDropDownMenu.
- **Dropdown menus had no background**: the retail backdrop templates don't
  exist on 3.3.5a and nothing applied `backdropInfo`. The lib now applies the
  backdrops via the native `SetBackdrop`.
- **Macro rewriting could error**: 3.3.5a `EditMacro` doesn't return the new
  macro id, which the macro cache indexes with — the facade now falls back to
  the passed id.
- `LargeDropDownMenuButtonMixin` load error (`CreateFromMixins` absent) —
  covered by the Compat shim.

### Meta
- `.toc`: author credit `Verz, Tsoukie (backport: Jedborg)`, notes mention
  the stock 3.3.5a target; `Compat.lua` + LibStub load before everything else.
- README rewritten for this backport (credits, install, decoupling notes).
