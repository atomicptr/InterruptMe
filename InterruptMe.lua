require "Window"
require "Unit"

local InterruptMe = {}

local REFRESH_TIME = 0.2

local SPRITE_INTERRUPT_ARMOR_NORMAL = "HUD_TargetFrame:spr_TargetFrame_InterruptArmor_Value"
local SPRITE_INTERRUPT_ARMOR_BROKEN = "HUD_TargetFrame:spr_TargetFrame_InterruptArmor_MoO"

function InterruptMe:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.form = nil
    self.window = nil
    self.target = nil

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
        self.window = Apollo.LoadForm(self.form, "InterruptPanel", "InWorldHudStratum", self)

        if self.window ~= nil then
            -- everything is fine :)
            Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)

            Apollo.CreateTimer("InterruptMe_Refresh", REFRESH_TIME, true)
            Apollo.RegisterTimerHandler("InterruptMe_Refresh", "OnTimerRefreshed", self)

            self:HidePlate()
        else
            Apollo.AddAddonErrorText(self, "Could not create a window for some odd reason, sorry :(.")
        end
    end
end

function InterruptMe:OnTargetUnitChanged(unit)
    self.target = GameLib.GetTargetUnit()
end

function InterruptMe:OnTimerRefreshed()
    if self.target == nil or self.target:IsFriend() then
        -- nothing to do, hide plate
        self:HidePlate()
    else
        local interruptArmor = self.target:GetInterruptArmorValue()
        local interruptArmorMax = self.target:GetInterruptArmorMax()

        local isCasting = self.target:IsCasting()

        local isStunned = self.target:IsInCCState(Unit.CodeEnumCCState.Stun)

        if isStunned then
            self:ShowBrokenInterruptShield()

            self:ShowPlate(self.target)
        elseif isCasting or interruptArmor < interruptArmorMax then
            self:ShowNormalInterruptShield()

            self.window:SetText(interruptArmor)

            self:ShowPlate(self.target)
        else
            self:HidePlate()
        end
    end
end

function InterruptMe:ShowPlate(onUnit)
    self.window:SetUnit(onUnit)
    self.window:Show(true, true)
end

function InterruptMe:HidePlate()
    self.window:Show(false, true)
end

function InterruptMe:ShowBrokenInterruptShield()
    self.window:SetText("")
    self.window:SetSprite(SPRITE_INTERRUPT_ARMOR_BROKEN)
end

function InterruptMe:ShowNormalInterruptShield()
    self.window:SetSprite(SPRITE_INTERRUPT_ARMOR_NORMAL)
end

local InterruptMeInst = InterruptMe:new()
InterruptMeInst:Init()
