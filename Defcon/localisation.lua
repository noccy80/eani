local L = LibStub("AceLocale-3.0"):NewLocale("DefCon", "enUS", true)
if L then
	L["X is under attack"] = function(X) 
		return X.." is under attack!";
	end
	L["zone is under attack"] = function(zone,subzone,attacks,timespan,weight)
		return subzone.." ("..zone..") is under attack ("..attacks.." attacks in the last "..math.floor(timespan).." seconds)";
	end
	L["objectivecaptured"] = function(objective,zone,faction)
		return objective.." ("..zone..") was taken by the "..faction.." (WorldPVP)";
	end
	L["commands"] = "Commands Here";
	L["muted"] = "Zone attack messages muted";
	L["unmuted"] = "Zone attack messages unmuted";
	L["zoneattack pattern"] = "([%w%s'.]+) is under attack!";
	L["zonedebugmessage"] = function(zone,events,time,weight) 
		return zone..": "..events.." events ("..time.." s) "..weight;
	end
end
