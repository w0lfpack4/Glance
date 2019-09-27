---------------------------
-- lets simplify a bit..
---------------------------
local gf = Glance.Functions
local gv = Glance.Variables
local ga = Glance.Arrays
local gb = Glance.Buttons

---------------------------
-- create the button
---------------------------
gf.AddButton("Reputation","LEFT")
local btn = gb.Reputation
btn.text              = "Reputation"
btn.enabled           = true
btn.events            = {"UPDATE_FACTION"}
btn.update            = true
btn.tooltip           = true
btn.click             = true
btn.menu              = true
btn.save.perCharacter = { ["DisplayReputation"] = "Percent", ["TrackList"] = {}, ["CountItems"] = true }
btn.save.allowProfile = true

---------------------------
-- shortcuts
---------------------------
local spc = btn.save.perCharacter
local HEX = ga.colors.HEX
local tooltip = gf.Tooltip

---------------------------
-- variables
---------------------------
ga.standing = {
	l = {
		"Hated",
		"Hostile",
		"Unfriendly",
		"Neutral",
		"Friendly",
		"Honored",
		"Revered",
		"Exalted"
		},
	c = {
		"|cffff0000",
		"|cffff4000",
		"|cffff8000",
		"|cffffff00",
		"|cff80ff00",
		"|cff00ff00",
		"|cff00ff80",
		"|cff02A5FD"
		},
	fc = {
		"|cffffb400",
		"|cffffff00",
		"|cff80ff00",
		"|cff00ff00",
		"|cff00ff80",
		"|cff02A5FD"
		},
		
}
gv.TrackMultiple = false

---------------------------
-- update
---------------------------
function gf.Reputation.update(self, event, arg1)
	if btn.enabled and gv.loaded then -- loaded keeps it from launching when defined
		Glance.Debug("function","update","Reputation")
		local title, rep, color = "Rep: ", nil, nil
		for factionIndex=1,GetNumFactions() do
			if select(12,GetFactionInfo(factionIndex)) then	--isWatched
				local id, name, clr, standing, minVal, maxVal, currentVal, percentVal, remainingVal, itemRep, isWatched, isHeader  = unpack(gf.Reputation.getFactionInfo(factionIndex))	
				rep = gf.getCondition(spc.DisplayReputation == "Percent",percentVal,remainingVal - itemRep); color = clr;
			end
		end		
		gf.setButtonText(btn.button,title,rep,gf.getCondition(rep == nil,HEX.red,HEX.white),color)
	end
end

---------------------------
-- tooltip
---------------------------
function gf.Reputation.tooltip()
	Glance.Debug("function","tooltip","Reputation")
	tooltip.Title("Reputation", "GLD")
	local hasWatch,hasFriends,printedHeader,showMultiple = false,false,false,false
	for factionIndex=1,GetNumFactions() do
        local id, name, color, standing, minVal, maxVal, currentVal, percentVal, remainingVal, itemRep, isWatched, isHeader  = unpack(gf.Reputation.getFactionInfo(factionIndex))
        if color == nil then
            color = ""
        end
        if standing == nil then
            standing = "?"
        end
		local val = gf.getCondition(spc.DisplayReputation == "Percent",percentVal,remainingVal)
		if isHeader then hasFriends = false end -- reset friend check on next header
		if select(12,GetFactionInfo(factionIndex)) then	--isWatched		
			tooltip.Line("Currently tracking "..color..name.."|r reputation: "..color..standing, "WHT")
			tooltip.Space()
			tooltip.Double("Percent Earned",color..percentVal,"WHT","GRN")
			tooltip.Double("Points Remaining",color..remainingVal,"WHT","GRN")
			tooltip.Double("Item Rep",color..itemRep,"WHT","GRN")
			tooltip.Double("Total Remaining",color..(remainingVal - itemRep),"WHT","GRN")
			hasWatch = true
			if isHeader and select(11,GetFactionInfo(factionIndex)) then -- header and hasRep means friends
				hasFriends = true
			end
		end
		if hasFriends then
			local isFriend = true
			for loop=1, #ga.standing.l do
				if standing == ga.standing.l[loop] then
					isFriend = false -- standing matches standard list, not a friend.
				end
			end
			if isFriend and not isHeader then
				if not printedHeader then --only show if rep actually has friends..
					tooltip.Space()
					tooltip.Line("Friends","GLD")
					printedHeader = true
				end
				tooltip.Double(name.." ("..color..standing.."|r)",color..val.." |r("..id.."/6)","WHT","WHT")
			end
		end
		if spc.TrackList[name] then
			showMultiple = true
		end
	end
	if not hasWatch then
		tooltip.Line("You are not tracking any reputation.", "WHT")
	else			
		if showMultiple then
			tooltip.Space()
			tooltip.Line("Multiple Tracking","GLD")
			for factionIndex=1,GetNumFactions() do
				local id, name, color, standing, minVal, maxVal, currentVal, percentVal, remainingVal, itemRep, isWatched, isHeader  = unpack(gf.Reputation.getFactionInfo(factionIndex))	
				if spc.TrackList[name] then			
					local val = gf.getCondition(spc.DisplayReputation == "Percent",percentVal,remainingVal)
					local isFriend = true
					for loop=1, #ga.standing.l do
						if standing == ga.standing.l[loop] then
							isFriend = false -- standing matches standard list, not a friend.
						end
					end
					local friendStat = gf.getCondition(isFriend," |r("..id.."/6)","")
					tooltip.Double(name.." ("..color..standing.."|r)",color..val..friendStat,"WHT","WHT")
				end
			end
		end
	end
	local tbl = {
		[1] = {["Display"]=spc.DisplayReputation},
	}
	tooltip.Options(tbl)
	--(left,shift-left,right,shift-right,other)
	tooltip.Notes("open the Reputation tab",nil,"change tracking","track multiple reputations",nil)
end

---------------------------
-- menu
---------------------------
function gf.Reputation.menu(level,UIDROPDOWNMENU_MENU_VALUE)
	Glance.Debug("function","menu","Reputation")
	ExpandAllFactionHeaders()
	local hName = " "
	level = level or 1
	if (level == 1) then
		gf.setMenuTitle("Reputation Options")
		gf.setMenuHeader("Display","display",level)
		gf.setMenuTitle(" ")
		gf.setMenuTitle("Reputation Tracking",level)
		for factionIndex=1,GetNumFactions() do
			if select(9,GetFactionInfo(factionIndex)) then -- header
				gf.setMenuHeader(select(1,GetFactionInfo(factionIndex)),select(1,GetFactionInfo(factionIndex)),level)
			end
		end
	end
	if (level == 2) then
		for factionIndex=1,GetNumFactions() do
			local id, name, color, standing, minVal, maxVal, currentVal, percentVal, remainingVal, isWatched, isHeader = unpack(gf.Reputation.getFactionInfo(factionIndex))	
			local val = gf.getCondition(spc.DisplayReputation == "Percent",percentVal,remainingVal)
			if isHeader then hName = name end -- set the next header
			if gf.isMenuValue(hName) and ((not isHeader) or (select(11,GetFactionInfo(factionIndex)))) then -- name match and (not header or hasRep)
				local ks, nr = gf.getCondition(gv.TrackMultiple,true,false), gf.getCondition(gv.TrackMultiple,true,false)
				if select(11,GetFactionInfo(factionIndex)) then -- hasRep, add a border
					gf.setMenuDivider(level)
				end
				local checked, func, text
				text = color..standing.." ("..val..") |r"..name -- text	
				if gv.TrackMultiple then -- tracking multiple, func updates tracklist
					if spc.TrackList[name]==true then checked = true else checked = false end
					func = function() if spc.TrackList[name] then spc.TrackList[name]=false else spc.TrackList[name]=true end; end;
				else -- tracking single, func changes watch
					if isWatched then
						checked = true
						func = function() SetWatchedFactionIndex(0); gf.Reputation.update() end;
					else
						checked = false
						func = function() SetWatchedFactionIndex(factionIndex); gf.Reputation.update() end;
					end
				end
				--disabled,isTitle,hasArrow,notCheckable,checked,text,value,level,func,icon,keepShown,notRadio
				gf.setInfo(nil,false,false,false,checked,text,hName,level,func,nil,ks,nr)
				if select(11,GetFactionInfo(factionIndex)) then -- hasRep, add a border
					gf.setMenuDivider(level)
				end
			end
		end
		if gf.isMenuValue("display") then
			--checked,text,value,level,func,icon
			gf.setMenuOption(spc.DisplayReputation=="Percent","Percent","Percent",level,function() spc.DisplayReputation="Percent"; gf.Reputation.update() end)
			gf.setMenuOption(spc.DisplayReputation=="Remaining","Remaining","Remaining",level,function() spc.DisplayReputation="Remaining"; gf.Reputation.update() end)
		end
	end
end

---------------------------
-- click
---------------------------
function gf.Reputation.click(self, button, down)
	Glance.Debug("function","click","Reputation")
	if button == "LeftButton" then
		ToggleCharacter("ReputationFrame")
	elseif button == "RightButton" then
		gv.TrackMultiple = gf.getCondition(IsShiftKeyDown(),true,false)
	end
end

---------------------------
-- get faction info
---------------------------
function gf.Reputation.getFactionInfo(factionIndex)
	local name, _, standingID, barMin, barMax, barValue, _, _, isHeader, _, _, isWatched, _, factionID, _, _ = GetFactionInfo(factionIndex)
	local fsText, fsColor, fsPercent, fsRemaining;
	-- local friendID, friendRep, _, _, _, _, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID);
	-- if (friendID ~= nil) then
	-- 	if ( nextFriendThreshold ) then
	-- 		barMin, barMax, barValue = friendThreshold, nextFriendThreshold, friendRep;
	-- 	else
	-- 		barMin, barMax, barValue = 0, 1, 1;
	-- 	end
	-- 	fsText = friendTextLevel;
	-- 	fsColor = ga.standing.fc[standingID];
	-- else
		fsText = ga.standing.l[standingID];
		fsColor = ga.standing.c[standingID];
	-- end	
	fsPercent = gf.Reputation.calculate(barMin,barValue,barMax)
    fsRemaining = barMax - barValue
	return {standingID, name, fsColor, fsText, barMin, barMax, barValue, fsPercent, fsRemaining, gf.Reputation.getFactionItems(factionID), isWatched, isHeader}
end

---------------------------
-- get faction reputation from items
---------------------------
function gf.Reputation.getFactionItems(factionID)
    if not spc.CountItems then return 0; end
    --print ("Faction: ",factionID)
    local itemRep = 0
    for bagID=0,5 do
        numberOfSlots = GetContainerNumSlots(bagID);
        for slot=1,numberOfSlots do
            local itemID = select(10, GetContainerItemInfo(bagID, slot))
            if (itemID ~= nil) then
                local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemID)
                local count = GetItemCount(itemLink)
                if (factionID == 576 and itemID == 21377) then -- Deadwood Headdress Feather
                    itemRep = itemRep + (floor( count / 5 ) * 50)
                    --print(count, " Feathers == ", (( count / 5 ) * 50), " rep")
                elseif (factionID == 576 and itemID == 21383) then -- Winterfall Spirit Beads
                    itemRep = itemRep + (floor( count / 5 ) * 50)
                    --print(count, " Beads == ", (( count / 5 ) * 50), " rep")
                end
            end
        end
    end
    return itemRep
end
---------------------------
-- calculate rep %
---------------------------
function gf.Reputation.calculate(bv,ev,tv)
	local pct
	if tv > 0 then
		pct = math.floor(((ev-bv)/(tv-bv))*100)
	else
		pct = -(math.floor(((ev-tv)/(tv-bv))*100))
	end
	return pct.."%"
end

---------------------------
-- load on demand
---------------------------
if gv.loaded then
	gf.Enable("Reputation")
end
