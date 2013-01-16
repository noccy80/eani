-------------------------------------------------------------------------------
--
--
--  DedicatedDriver Plus
--  For Wizzelle. Now and forever
--
--  (c) 2008, Noccy - http://sophia.eani.net/projects/eani
--
-------------------------------------------------------------------------------

DDPlus = LibStub("AceAddon-3.0"):NewAddon("DDPlus", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MyAddon", true)

-- Register a SlashCommand handler here, we want to listen for '/dd'.
DDPlus:RegisterChatCommand("dd", "SlashCmdHandler")

-- The SlashCmdHandler handles '/dd' commands and performs the appropriate
-- action based on what's provided.
function DDPlus:SlashCmdHandler(input)

	-- For the command '/dd follow <player>'
	if (input:sub(1,6) == "follow") then
		local p = input:sub(8);
		self:Print(L["followrequestsend X"](p));
		SendAddonMessage( "DDP3" , "Follow" , "WHISPER" , p );
		return;
	end
	
	-- For the command '/dd followparty'
	if (input == "followparty") then
		self:Print(L["followrequestparty"]);
		SendAddonMessage( "DDP3" , "Follow" , "PARTY" , "" );
		return;
	end
	
	-- For the commands '/dd allow', '/dd remove', '/dd list'
	if (input:sub(1,6) == "allow ") then
		local player = input:sub(7);
		self:Print(L["allowed X"](player));
		self:SetPlayerPermission(player,true);
		return;
	end
	
	-- for the command '/dd resurrect'
	if (input:sub(1,10) == "resurrect ") then
		local player = input:sub(11);
		self:Print(L["resurrectrequest"](player));
		SendAddonMessage( "DDP3", "Resurrect", "WHISPER", player );
		return;
	end

	-- for the command '/dd resurrectparty'
	if (sub == "resurrectparty") then
		self:Print(L["resurrectpartyrequest"]);
		SendAddonMessage( "DDP3", "Resurrect", "PARTY", "" );
		return;
	end
	
	if (input:sub(1,7) == "remove ") then
		local player = input:sub(8);
		self:Print(L["removed X"](player));
		self:SetPlayerPermission(player,false);
		return;
	end
	
	if (input:sub(1,12) == "interactive ") then
		if (input:sub(13) == "on") then
			self:Print("interactive: enabled");
			self.db.char.interactive = true;
		else
			self:Print("interactive: disbled");
			self.db.char.interactive = false;
		end
		return;
	end
	
	if (input == "list") then
		return;
	end
	
	-- Print command help
	self:Print(L["commands"]);
  
end

-- Code that you want to run when the addon is first loaded goes here.
function DDPlus:OnInitialize()

	self.db = LibStub("AceDB-3.0"):New("DDPlusDB")
	if (self.db.char.access == nil) then
		self.db.char.access = {};
	end
	if (self.db.char.interactive == nil) then
		self.db.char.interactive = false;
	end

	StaticPopupDialogs["DDPLUS_FOLLOWREQUEST"] = {
		text = "%s has issued a follow request but is not on your access list. Add player to the list and follow?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(arg)
			DDPlus:AllowAndFollowPlayer(arg);
		end,
		timeout = 10,
		whileDead = 1,
		hideOnEscape = 1
	};

end

-- Called when the addon is enabled
function DDPlus:OnEnable()

	-- Register the CHAT_MSG_ADDON event so we can receive addon messages
	self:RegisterEvent("CHAT_MSG_ADDON");
    
end

-- Called when the addon is disabled
function DDPlus:OnDisable()
    
end

-- Handles addon messages received
--   arg1: prefix
--   arg2: message
--   arg3: distribution method (party, whisper, ..)
--   arg4: sender
function DDPlus:CHAT_MSG_ADDON()

	if ((arg1 == "DDP3") and (arg2 == "Follow")) then
		self:DoFollow(arg4);
	end
	if ((arg1 == "DDP3") and (arg2 == "Resurrect")) then
		AcceptResurrect();
	end

end

-- Invokes the actual following
function DDPlus:DoFollow(player) 

	if (DDPlus:GetPlayerPermission(player)) then
		self:Print(L["followrequestreceive X"](player));
		FollowUnit(player);
	else
		if (self.db.char.interactive == false) then
			self:Print(L["followrequestdenied"](player));
		else
			DDPlus:InteractiveQueryPlayerAccess(player);
		end
	end

end

function DDPlus:GetPlayerPermission(player) 

	if (self.db.char.access[player:lower()] == nil) then
		return false;
	end
	
	-- allow access
	return true;

end

function DDPlus:SetPlayerPermission(player,state)

	if (state) then
		self.db.char.access[player:lower()] = true;
	else
		self.db.char.access[player:lower()] = nil;
	end

end

function DDPlus:InteractiveQueryPlayerAccess(player)

	local dialog = StaticPopup_Show("DDPLUS_FOLLOWREQUEST", player);
	if (dialog) then
		dialog.data = player;
	end

end