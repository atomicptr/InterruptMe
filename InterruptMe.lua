require "Window"

local InterruptMe = {}

local REFRESH_TIME = 0.2

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
            Print("Everything is fine :D")
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
        local castPercentage = self.target:GetCastTotalPercent()

        local interruptArmor = self.target:GetInterruptArmorValue()
        local interruptArmorMax = self.target:GetInterruptArmorMax()

        local isCasting = castPercentage > 0 and castPercentage < 100

        local isCastingText = "Nope"

        if isCasting then
            isCastingText = "Yes :)"
        end

        Print("Is Casting: "..isCastingText..", IA: "..interruptArmor..", Max: "..interruptArmorMax)

        if isCasting or interruptArmor < interruptArmorMax then
            self.window:SetText(interruptArmor)

            self.window:SetUnit(self.target)

            self:ShowPlate()
        else
            self:HidePlate()
        end
    end
end

function InterruptMe:ShowPlate()
    self.window:Show(true, true)
end

function InterruptMe:HidePlate()
    self.window:Show(false, true)
end

local InterruptMeInst = InterruptMe:new()
InterruptMeInst:Init()
