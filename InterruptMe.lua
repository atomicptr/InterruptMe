require "Window"

local InterruptMe = {}

function InterruptMe:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.form = nil

    return o
end

function InterruptMe:Init()
    Apollo.RegisterAddon(self, false, "", {})
end

function InterruptMe:OnLoad()
	self.form = XmlDoc.CreateFromFile("InterruptMe.xml")
end

local InterruptMeInst = InterruptMe:new()
InterruptMeInst:Init()
