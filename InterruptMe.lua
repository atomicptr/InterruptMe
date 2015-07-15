require "Window"
require "Unit"

local InterruptMe = {}

local REFRESH_TIME = 0.1
local MAX_DISTANCE = 50

local SPRITE_INTERRUPT_ARMOR_NORMAL = "HUD_TargetFrame:spr_TargetFrame_InterruptArmor_Value"
local SPRITE_INTERRUPT_ARMOR_BROKEN = "HUD_TargetFrame:spr_TargetFrame_InterruptArmor_MoO"

function InterruptMe:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.player = nil
    self.form = nil
    self.plates = {}
    self.units = {}

    return o
end

function InterruptMe:Init()
    Apollo.RegisterAddon(self, false, "", {})
end

function InterruptMe:OnLoad()
	self.form = XmlDoc.CreateFromFile("InterruptMe.xml")
    self.form:RegisterCallback("OnDocLoaded", self)
end

function InterruptMe:OnDocLoaded()
    if self.form ~= nil and self.form:IsLoaded() then
        -- everything is fine :)
        Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
        Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
        Apollo.RegisterEventHandler("UnitEnteredCombat", "OnUnitEnteredCombat", self)
        Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)

        Apollo.CreateTimer("InterruptMe_Refresh", REFRESH_TIME, true)
        Apollo.RegisterTimerHandler("InterruptMe_Refresh", "OnTimerRefreshed", self)
    end
end

function InterruptMe:OnUnitCreated(unit)
    local isInCombat = unit:IsInCombat()

    -- need to check this because unit might already be in combat
    if isInCombat then
        self:OnUnitEnteredCombat(unit, isInCombat)
    end
end

function InterruptMe:OnUnitDestroyed(unit)
    local id = unit:GetId()

    self.units[id] = nil

    if self.plates[id] ~= nil then
        self:RemovePlate(id)
    end
end

function InterruptMe:OnUnitEnteredCombat(unit, isInCombat)
    local id = unit:GetId()

    local isHostile = self:IsUnitHostile(unit)
    local hasAlreadyPlate = self.plates[id] ~= nil

    if not hasAlreadyPlate and isHostile and isInCombat then
        self.units[id] = unit

        self:AddPlate(id)
    end
end

function InterruptMe:OnChangeWorld()
    self.player = nil

    self:ClearPlates()
end

function InterruptMe:OnTimerRefreshed()
    if self.player == nil then
        self.player = GameLib.GetPlayerUnit()
    end

    -- update existing plates
    for id in pairs(self.plates) do
        self:UpdatePlate(id)
    end
end

function InterruptMe:Count(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

function InterruptMe:AddPlate(id)
    local unit = self.units[id]
    self.plates[id] = Apollo.LoadForm(self.form, "InterruptPanel", "InWorldHudStratum", self)

    self.plates[id]:SetUnit(unit)
    self:UpdatePlate(id)
end

function InterruptMe:RemovePlate(id)
    if self.plates[id] ~= nil then
        self.plates[id]:Destroy()
        self.plates[id] = nil
    end
end

function InterruptMe:UpdatePlate(id)
    local unit = self.units[id]

    if not self:IsUnitHostile(unit) then
        self:RemovePlate(id)
        return
    end

    local interruptArmor = unit:GetInterruptArmorValue()
    local interruptArmorMax = unit:GetInterruptArmorMax()

    local isCasting = unit:IsCasting()

    local isStunned = unit:IsInCCState(Unit.CodeEnumCCState.Stun)

    if isStunned then
        self:ShowBrokenInterruptShield(id)
        self:ShowPlate(id)
    elseif isCasting or interruptArmor < interruptArmorMax then
        self:ShowNormalInterruptShield(id)

        self.plates[id]:SetText(interruptArmor)

        self:ShowPlate(id)
    else
        self:HidePlate(id)
    end
end

function InterruptMe:ClearPlates()
    for id in pairs(self.plates) do
        self:RemovePlate(id)
    end
end

function InterruptMe:ShowPlate(id)
    self.plates[id]:Show(true, true)

    if not self:ShouldBeVisible(id) then
        self:HidePlate(id)
    end
end

function InterruptMe:HidePlate(id)
    self.plates[id]:Show(false, true)
end

function InterruptMe:ShowBrokenInterruptShield(id)
    self.plates[id]:SetText("")
    self.plates[id]:SetSprite(SPRITE_INTERRUPT_ARMOR_BROKEN)
end

function InterruptMe:ShowNormalInterruptShield(id)
    self.plates[id]:SetSprite(SPRITE_INTERRUPT_ARMOR_NORMAL)
end

function InterruptMe:ShouldBeVisible(id)
    local isOnScreen = self.plates[id]:IsOnScreen()
    local isOccluded = self.plates[id]:IsOccluded()
    local isNearPlayer = self:IsNearPlayer(id)

    return isOnScreen and not isOccluded and isNearPlayer
end

function InterruptMe:IsNearPlayer(id)
    if self.player == nil then
        return false
    end

    local player = self.player:GetPosition()
    local unit = self.units[id]:GetPosition()

    local distance = math.sqrt(math.pow(player.x - unit.x, 2) + math.pow(player.y - unit.y, 2) + math.pow(player.z - unit.z, 2))

    return distance <= MAX_DISTANCE
end

function InterruptMe:IsUnitHostile(unit)
    if unit ~= nil and self.player ~= nil then
        local disposition = unit:GetDispositionTo(self.player)

        return disposition == Unit.CodeEnumDisposition.Hostile
    end

    return false
end

local InterruptMeInst = InterruptMe:new()
InterruptMeInst:Init()
