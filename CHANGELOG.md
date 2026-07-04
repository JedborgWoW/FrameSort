# Changelog

All notable changes to this **stock 3.3.5a backport** of FrameSort.

## [1.2] — 2026-07-04

### Fixed
- **Widget-metatable shims now install with `rawset`.** On this client the
  Frame-type method table carries a `__newindex` guard that silently swallows a
  plain `index.SetSize = fn` for a NEW key. `Compat.lua`'s `extend()` added
  `SetSize`/`GetSize`/`SetWordWrap`/`SetMotionScriptsWhileDisabled`/
  `AdjustPointsOffset` by plain assignment, so on a stock client those were
  dropped and the methods stayed nil (a latent crash). They now use `rawset`,
  which bypasses the guard; the `not index.X` checks stay chain-aware.

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
- **Login error `Couldn't find inherited node "DialogBorderDarkTemplate"`**
  (which also killed every dropdown: `Create_UIDropDownMenu` nil): the
  coexisting CompactRaidFrame backport defines `BackdropTemplateMixin` as an
  empty shim table, and LibUIDropDownMenu used the mixin's *presence* to
  decide the retail backdrop XML *templates* exist. Template call sites are
  now additionally gated on the client build (`GetBuildInfo() == "3.3.5"`),
  and the native-`SetBackdrop` fallback uses the same gate.
- **Login error `attempt to call field 'GetAddOnEnableState'`**: another
  backport defines a *partial* `C_AddOns` namespace without that function;
  the facade now probes the member, not just the namespace.
- Guarded no-ops for `FontString:SetWordWrap` and
  `Button:SetMotionScriptsWhileDisabled` (used by LibUIDropDownMenu when
  building dropdowns; uncertain on stock 3.3.5a, cosmetic-only).
- **Login error `Couldn't find inherited node "BackdropTemplate"`** (config
  panel backgrounds): the facade's own `CreateFrame` wrapper stripped
  `"BackdropTemplate"` only when `BackdropTemplateMixin` was nil — the same
  foreign-shim trap as above. Now also stripped on the 3.3.5a client build
  (the panels call the native `SetBackdrop` directly afterwards).
- Hardened the `EventRegistry` probe in the runner the same way (member
  check, not just the namespace).

### Added (later same day)
- `/fsort` slash alias — some private clients (e.g. Triumvirate) claim `/fs`
  for their own frame-stack debug tool, so `/fs` may open that instead.

### Meta
- `.toc`: author credit `Verz, Tsoukie (backport: Jedborg)`, notes mention
  the stock 3.3.5a target; `Compat.lua` + LibStub load before everything else.
- README rewritten for this backport (credits, install, decoupling notes).
