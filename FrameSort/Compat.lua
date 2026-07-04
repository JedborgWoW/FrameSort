--========================================================================--
-- FrameSort — stock WotLK 3.3.5a compatibility layer (backport: Jedborg).
--
-- Upstream (Tsoukie's framesort-3.3.5) relied on !!!ClassicAPI to provide
-- these modern globals. This file replaces that dependency so the addon is
-- self-contained on a plain 3.3.5a client.
--
-- Must load FIRST (before Libs and before WoW\WoW.lua, which captures
-- globals like C_Timer/IsInRaid/CopyTable at file scope). Everything is
-- guarded/additive so it coexists with the CompactRaidFrame backport's own
-- WotLKCompat.lua — whichever loads first wins, both provide the same
-- contract. No existing Blizzard global is ever reassigned (taint).
--========================================================================--

--========================================================================--
-- Group API (IsInRaid/GetNumGroupMembers etc. are MoP+ names; build them
-- from the native 3.3.5a GetNumRaidMembers / GetNumPartyMembers).
--========================================================================--
if type(IsInGroup) ~= "function" then
    function IsInGroup()
        return (GetNumRaidMembers() > 0) or (GetNumPartyMembers() > 0)
    end
end

if type(IsInRaid) ~= "function" then
    function IsInRaid()
        return GetNumRaidMembers() > 0
    end
end

if type(GetNumSubgroupMembers) ~= "function" then
    function GetNumSubgroupMembers()
        return GetNumPartyMembers()
    end
end

if type(GetNumGroupMembers) ~= "function" then
    function GetNumGroupMembers()
        -- In a raid: number of raid members. In a party: party size + the player.
        local n = GetNumRaidMembers()
        if n > 0 then
            return n
        end
        n = GetNumPartyMembers()
        return (n > 0) and (n + 1) or 0
    end
end

--========================================================================--
-- CopyTable (Cata) — deep copy. Init.lua clones the nested defaults table
-- with it; a shallow copy would make the saved options share subtables with
-- the defaults and corrupt them.
--========================================================================--
if type(CopyTable) ~= "function" then
    function CopyTable(tbl)
        local copy = {}
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                copy[k] = CopyTable(v)
            else
                copy[k] = v
            end
        end
        return copy
    end
end

--========================================================================--
-- C_Timer (After / NewTimer / NewTicker) via a single OnUpdate scheduler.
-- Full surface so other addons feature-detecting C_Timer don't break.
--========================================================================--
if type(C_Timer) ~= "table" then
    local GetTime = GetTime
    local geterrorhandler = geterrorhandler
    C_Timer = {}

    local timers = {} -- set of active timer objects
    local TimerMT = {}
    TimerMT.__index = TimerMT
    function TimerMT:Cancel()
        self._cancelled = true
        timers[self] = nil
    end
    function TimerMT:IsCancelled()
        return self._cancelled == true
    end

    local driver = CreateFrame("Frame")
    driver:Hide()

    driver:SetScript("OnUpdate", function()
        if not next(timers) then
            driver:Hide() -- nothing pending: stop ticking
            return
        end
        local now = GetTime()
        local due
        for t in pairs(timers) do
            if not t._cancelled and now >= t._next then
                due = due or {}
                due[#due + 1] = t
            end
        end
        if due then
            for i = 1, #due do
                local t = due[i]
                if not t._cancelled then
                    if t._ticker then
                        if t._iterations then
                            t._iterations = t._iterations - 1
                            if t._iterations <= 0 then
                                timers[t] = nil
                                t._cancelled = true
                            end
                        end
                        t._next = now + t._interval
                    else
                        timers[t] = nil
                        t._cancelled = true
                    end
                    local cb = t._callback
                    if cb then
                        local ok, err = pcall(cb)
                        if not ok and geterrorhandler then geterrorhandler()(err) end
                    end
                end
            end
        end
    end)

    local function newTimer(duration, callback, iterations, ticker)
        duration = (type(duration) == "number" and duration > 0) and duration or 0.0
        local t = setmetatable({}, TimerMT)
        t._next = GetTime() + duration
        t._interval = duration
        t._callback = callback
        t._iterations = iterations
        t._ticker = ticker
        timers[t] = true
        driver:Show()
        return t
    end

    function C_Timer.After(duration, callback)
        newTimer(duration, callback, nil, false)
    end
    function C_Timer.NewTimer(duration, callback)
        return newTimer(duration, callback, nil, false)
    end
    function C_Timer.NewTicker(duration, callback, iterations)
        return newTimer(duration, callback, iterations, true)
    end
end

--========================================================================--
-- Mixin / CreateFromMixins — LibUIDropDownMenu builds its mixins at load
-- time, so these must exist before the Libs load.
--========================================================================--
if type(Mixin) ~= "function" then
    function Mixin(object, ...)
        for i = 1, select("#", ...) do
            local mixin = select(i, ...)
            if mixin then
                for k, v in pairs(mixin) do
                    object[k] = v
                end
            end
        end
        return object
    end
end

if type(CreateFromMixins) ~= "function" then
    function CreateFromMixins(...)
        return Mixin({}, ...)
    end
end

--========================================================================--
-- Clamp — used by LibUIDropDownMenu's MatchTextWidth.
--========================================================================--
if type(Clamp) ~= "function" then
    function Clamp(value, min, max)
        if value > max then
            return max
        elseif value < min then
            return min
        end
        return value
    end
end

--========================================================================--
-- SOUNDKIT — LibUIDropDownMenu plays click sounds through it. 3.3.5a's
-- PlaySound takes the OLD string sound names, so map to those. Filled
-- per-key so a foreign SOUNDKIT (e.g. CompactRaidFrame's) is left intact.
--========================================================================--
SOUNDKIT = SOUNDKIT or {}
if SOUNDKIT.U_CHAT_SCROLL_BUTTON == nil then
    SOUNDKIT.U_CHAT_SCROLL_BUTTON = "UChatScrollButton"
end
if SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON == nil then
    SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON = "igMainMenuOptionCheckBoxOn"
end
if SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF == nil then
    SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF = "igMainMenuOptionCheckBoxOff"
end

--========================================================================--
-- Widget metatable additions. Each widget type has its OWN metatable on
-- 3.3.5a, so extend every type the addon touches. Adding NEW methods to
-- widget metatables is the one safe metatable extension: secure code never
-- calls methods that didn't exist on 3.3.5a.
--
--   SetSize/GetSize (Cata)  — used throughout LibUIDropDownMenu and the
--                             config panels.
--   AdjustPointsOffset (BfA) — used by the insecure SoftArrange path when
--                              spacing raid groups (Modules\Sorting\
--                              SecureNoCombat.lua); the in-combat secure
--                              snippet has its own implementation.
--========================================================================--
do
    local function extend(obj, withAdjustPoints)
        if not obj then return end
        local mt = getmetatable(obj)
        local index = mt and mt.__index
        if type(index) ~= "table" then return end

        -- rawset, not index.X = fn: the frame-type __index table carries a
        -- __newindex guard that silently drops a plain assignment for a NEW key,
        -- leaving the method nil. The `not index.X` reads stay chain-aware so a
        -- native implementation always wins.
        if not index.SetSize then
            rawset(index, "SetSize", function(self, w, h)
                self:SetWidth(w)
                self:SetHeight(h)
            end)
        end
        if not index.GetSize then
            rawset(index, "GetSize", function(self)
                return self:GetWidth(), self:GetHeight()
            end)
        end

        -- safe no-ops if the client lacks them (cosmetic-only behaviour);
        -- guarded, so a native implementation always wins
        if not index.SetWordWrap and obj.GetObjectType and obj:GetObjectType() == "FontString" then
            rawset(index, "SetWordWrap", function() end)
        end
        if not index.SetMotionScriptsWhileDisabled and obj.GetObjectType and obj:GetObjectType() == "Button" then
            rawset(index, "SetMotionScriptsWhileDisabled", function() end)
        end

        if withAdjustPoints and not index.AdjustPointsOffset then
            rawset(index, "AdjustPointsOffset", function(self, xDelta, yDelta)
                local points = {}
                for i = 1, self:GetNumPoints() do
                    local point, relativeTo, relativePoint, x, y = self:GetPoint(i)
                    points[i] = { point, relativeTo, relativePoint, (x or 0) + (xDelta or 0), (y or 0) + (yDelta or 0) }
                end
                if #points == 0 then
                    return
                end
                self:ClearAllPoints()
                for i = 1, #points do
                    local p = points[i]
                    self:SetPoint(p[1], p[2], p[3], p[4], p[5])
                end
            end)
        end
    end

    local holder = CreateFrame("Frame")
    holder:Hide()
    extend(holder, true)                                     -- Frame
    extend(CreateFrame("Button", nil, holder), true)         -- Button
    extend(CreateFrame("CheckButton", nil, holder))          -- CheckButton
    extend(CreateFrame("EditBox", nil, holder))              -- EditBox (see below)
    extend(CreateFrame("Slider", nil, holder))               -- Slider
    extend(CreateFrame("ScrollFrame", nil, holder))          -- ScrollFrame
    extend(CreateFrame("StatusBar", nil, holder))            -- StatusBar
    extend(holder:CreateTexture())                           -- Texture
    extend(holder:CreateFontString())                        -- FontString

    -- a bare EditBox autofocuses and eats ALL keyboard input; release it
    for _, child in ipairs({ holder:GetChildren() }) do
        if child.ClearFocus then
            child:SetAutoFocus(false)
            child:ClearFocus()
        end
        child:Hide()
    end
end
