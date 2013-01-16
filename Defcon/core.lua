--[[


	DefenseTracker

	(c) 2008, Noccy - http://sophia.eani.net/projects/eani


--]]

DTracker = LibStub("AceAddon-3.0"):NewAddon("DefCon", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("DefCon", true)
local ZoneData = {};
local ObjectiveData = {};

DTracker.muted = false;

-- locals
local LastZone = "";
local options = {
	name = "DefCon",
	handler = DTracker,
	type = 'group',
	args = {
		mute = {
			name = "Mute",
			desc = "Mutes or unmutes the zone alert messages for this session",
			type = "toggle",
			set  = "SetMuteState",
			get  = "GetMuteState"
		},
		threshold = {
			name = "Threshold",
			desc = "Sets the alert weight threshold",
			type = "input",
			set  = "SetAlertThreshold",
			get  = "GetAlertThreshold"
		},
		debug = {
			name = "Debug",
			desc = "Show debug information",
			type = "execute",
			func = "ShowDebug"
		},
		worldpvp = {
			name = "WorldPVP",
			desc = "Show World PVP status",
			type = "execute",
			func = "ShowWorldPVPStatus"		
		},
		show = {
			name = "Show",
			desc = "Select what to display",
			handler = DTracker,
			type = 'group',
			args = {
				zoneattack = {
					name = "Zone",
					desc = "Zone attack events",
					type = "toggle",
					set  = "SetShowSetting",
					get  = "GetShowSetting"
				},
				worldpvp = {
					name = "PVP",
					desc = "WorldPVP events",
					type = "toggle",
					set  = "SetShowSetting",
					get  = "GetShowSetting"					
				},
			},
		},
	},
};

LibStub("AceConfig-3.0"):RegisterOptionsTable("DefCon", options, { "dc", "defcon" });

function DTracker:OnLinkClicked(link, text, button, ...)

	if (link:sub(1,7) == "defcon:") then
		self:Print("DefCon link found!");
		local zone = link:sub(8);
		DTracker:ShowZonePVPStatus(zone);
		return true;
	end

	-- call the old handler if not handled
	self:Print("Calling on original link handler");
	return self.hooks.SetItemRef(link, text, button, ...);

end

function DTracker:GetOptionsTable()
	
	return options;

end


-- Code that you want to run when the addon is first loaded goes here.
function DTracker:OnInitialize()

	-- Join the worlddefense channel and remove it from the default chat
	-- frame.
	local chan, no = JoinChannelByName("WorldDefense");
	RemoveChatWindowChannel(ChatFrame1:GetID(), "WorldDefense");

	self.db = LibStub("AceDB-3.0"):New("DefConDB");
	
	if (self.db.char.threshold == nil) then 
		self.db.char.threshold = 1;
	else
		self.db.char.threshold = tonumber(self.db.char.threshold);
	end;
	
end

-- Called when the addon is enabled
function DTracker:OnEnable()

	-- Register the CHAT_MSG_ADDON event so we can receive addon messages
	self:RegisterEvent("CHAT_MSG_CHANNEL");
	-- self:Hook("SetItemRef","OnLinkClicked");
    
end

-- Called when the addon is disabled
function DTracker:OnDisable()

	self:Unhook("SetItemRef");
    
end

-- Handles addon messages received
--   arg1: message
--   arg2: author
--   arg3: language
--   arg4: cnum + cname
--   arg5: target
--   arg6: flag
--   arg7: zone id (22=ldef, 23=wdef)
--   arg8: cnum
--   arg9: cname
function DTracker:CHAT_MSG_CHANNEL()

	-- channel 23 = worlddefense
	if (arg7 == 23) then

		-- Strip the data to remove the color codes
		local stripped = arg1:sub(11);
		
		for subzone in stripped:gmatch(L["zoneattack pattern"]) do
			-- self:Print(subzone);
			self:ZoneAttacked(subzone);
		end
		-- Broken Hill has been taken by the Alliance!
		for site, faction in stripped:gmatch("([%w%s'.]+) has been taken by the ([%w.]+)!") do
			self:ObjectiveCaptured(site,faction);
		end
		
	end

	-- process data here
	--DTracker:ProcessData();

end

function DTracker:ProcessData()

	-- This is where the actual event processing will be done

end

-- 
function DTracker:ShowDebug()

	self:Print("Debug status");
	for zone, data in pairs(ZoneData) do
		local time,events,weight = self:GetSubzoneData(zone);
		self:Print(L["zonedebugmessage"](zone,events,time,weight));
	end

end

-- Show a status dump of the World PVP data
function DTracker:ShowWorldPVPStatus()

	for zone, data in pairs(WorldPVPReverse) do
		local status = "";
		for site, _ in pairs(data) do
			local owner = self:GetPVPObjectiveOwner(site);
			status = status..site..": "..owner.." ";
		end
		self:Print(zone.." - "..status);
	end
		
end

-- Show a zones World PVP status
function DTracker:ShowZonePVPStatus(zone)

	local data = WorldPVPReverse[zone];
	local status = "";
	for site, _ in pairs(data) do
		local owner = self:GetPVPObjectiveOwner(site);
		status = status..site..": "..owner.." ";
	end
	self:Print(zone.." - "..status);

end

-- Trigger a ObjectiveCaptured event
function DTracker:ObjectiveCaptured(site,faction)

	local zone = self:GetPVPZoneInfo(site);
	local zonelink = self:GetPVPZoneLink(zone);

	-- self:GetPVPZoneLink()
	self:Print(L["objectivecaptured"](site,zone,faction));
	-- Update status
	ObjectiveData[site] = faction;

end

-- Trigger a ZoneAttacked event
function DTracker:ZoneAttacked(subzone)

	local t = GetTime();
	local status, zone = pcall(GetZoneFromSubZone,subzone);
	
	if (zone == nil) then
		zone = "unknown";
	end

	if ((ZoneData[subzone]) == nil) then
		ZoneData[subzone] = {};
		ZoneData[subzone].attacks = 1;
		ZoneData[subzone].time = t;
	else

		-- Increment the attack counter
		ZoneData[subzone].attacks = ZoneData[subzone].attacks + 1;

		-- Calculate the weight
		local timespan, events, weight = self:GetSubzoneData(subzone);

		-- Do pruning here if the last attack occured more than 60 secs ago and
		-- the weight is under the pruning threshold.
		if (timespan > 60) then
			ZoneData[subzone].attacks = 1;
			ZoneData[subzone].time = t;
		end
		
		-- Otherwise, match the weight to see if we should render an alert
		-- if ((timespan < 60) and (events > 5)) then
		if (weight > self.db.char.threshold) then
			if not self.muted then 
				self:Print(L["zone is under attack"](zone,subzone,events,timespan,weight));
			end
			-- This data should probably not be cleared here... But it is now
			ZoneData[subzone].attacks = 0;
			ZoneData[subzone].time = t;
		end
		
	end
	
end

-- Return PVP zone link
function DTracker:GetPVPZoneLink(zone)

	return "|Hdefcon:"..zone.."|h|cFFF0C040["..zone.."]|r|h";

end

-- Return a colored string for the owner of the objective
function DTracker:GetPVPObjectiveOwner(site)
	
	local owner = ObjectiveData[site];
	if (owner == nil) then return "|cFF404040n/a|r"; end;
	if (owner == "Alliance") then return "|cFF40F040Alliance|r"; end;
	if (owner == "Horde") then return "|cFFF04040Horde|r"; end;
	
	return "|cFFFF0000Error|r";

end

-- Return event timespan, count, and weight for the specified zone
function DTracker:GetSubzoneData(subzone)

	if (ZoneData[subzone] ~= nil) then
		local timespan = (GetTime() - ZoneData[subzone].time);
		local events = ZoneData[subzone].attacks;
		local weight = self:GetEventWeight(timespan,events);
		return timespan, events, weight;
	else
		return 0, 0, 0;
	end

end

-- Return the zone the PVP objective is in
function DTracker:GetPVPZoneInfo(pvpobjective)

	local zone = WorldPVPZones[pvpobjective];

	if (zone ~= nil) then
		return zone;
	else
		return "unknown";
	end

end

-- Return Zone from SubZone
function GetZoneFromSubZone(subzone)

	return SubZones[subzone];
	
end

-- Calculate a weight of the attack; the more attacks taking place the higher
-- the weight.
function DTracker:GetEventWeight(time,events)

	if (time < 1) then
		return 0
	else
		return ((events / 2) / (time / events));
	end

end

-- Getters and Setters for configuration properties ---------------------------

function DTracker:SetAlertThreshold(info,val)

	-- probably a good idea to do range checking here and make sure we're
	-- dealing with numbers
	if (val == "") then
		self:Print("Threshold is currently |cFFF0F040"..self.db.char.threshold.."|r");
	else
		if (tonumber(val) > 0) then
			self.db.char.threshold = tonumber(val);
			self:Print("Threshold is now set to |cFFF0F040"..val.."|r");
		else
			self:Print("Error - threshold must be at least 1");
		end
	end

end

function DTracker:GetAlertThreshold(info)

	return self.db.char.threshold;

end

function DTracker:GetMuteState(info)

	return DTracker.muted;

end

function DTracker:SetMuteState(info,val)

	DTracker.muted = val;
	if (val) then
		self:Print("DefCon is now |cFFF04040muted|r.");
	else
		self:Print("DefCon is now |cFF40F040unmuted|r.");
	end

end

function DTracker:SetShowSetting(info,val)

	self:Print("Not implemented");

end

function DTracker:GetShowSetting(info)

	return false;

end