local L = LibStub("AceLocale-3.0"):NewLocale("MyAddon", "enUS", true)
if L then
	L["followrequestsend X"] = function(X) 
		return "Sending follow request to "..X.."...";
	end
	L["followrequestreceive X"] = function(X)
		return "Player "..X.." sent a follow request! Following";
	end
	L["followrequestparty"] = "Sending follow request to party";
	L["resurrectrequest"] = function(X)
		return "Sending resurrection requst to "..X.."...";
	end
	L["resurrectpartyrequest"] = "Sending resurrection request to party";
	L["allowed X"] = function(X) 
		return "Player "..X.." added to allow list";
	end
	L["removed X"] = function(X) 
		return "Player "..X.." removed from allow list";
	end
	L["followrequestdenied"] = function(X)
		return "Player "..X.." sent a follow request but is not in the allow list. To allow this player to control you, type: /dd allow "..X;
	end
	L["commands"] = "Use: /dd - follow <player>, followparty, resurrect <player>, resurrectparty, allow <player>, remove <player>, enable, disable";
end
