---------------------------
-- lets simplify a bit..
---------------------------
local gf = Glance.Functions
local gv = Glance.Variables
local ga = Glance.Arrays
local gb = Glance.Buttons
local gd = Glance.Data

---------------------------
-- create the button
---------------------------
gf.AddButton("Quests","LEFT")
local btn = gb.Quests
btn.text			  	= "Quests"
btn.enabled		   		= true
btn.events				= {"QUEST_ACCEPTED", "QUEST_AUTOCOMPLETE", "QUEST_COMPLETE", "QUEST_DETAIL", "QUEST_LOG_UPDATE", "QUEST_REMOVED", "QUEST_TURNED_IN", "QUEST_WATCH_LIST_CHANGED", "QUEST_WATCH_UPDATE", "TASK_PROGRESS_UPDATE", "QUEST_ACCEPT_CONFIRM", "QUEST_FINISHED", "QUEST_GREETING",  "QUEST_ITEM_UPDATE", "QUEST_PROGRESS"}
btn.texture.scan1       = "Interface\\AddOns\\Glance_Quests\\scan1.tga"
btn.texture.scan2       = "Interface\\AddOns\\Glance_Quests\\scan2.tga"
btn.onload              = true
btn.update				= true
btn.tooltip		   		= true
btn.menu			  	= true
btn.click				= true
btn.save.perCharacter 	= {["autoAccept"] = true,["autoComplete"] = true,["playSound"] = true,["debug"] = true}
btn.save.perAccount 	= {["showIL"] = true,["showCharacterOverlay"] = true,["showInspectOverlay"] = true,["showTooltipOverlay"] = true}
btn.save.allowProfile 	= true


---------------------------
-- shortcuts
---------------------------
local spc = btn.save.perCharacter
local spa = btn.save.perAccount
local HEX = ga.colors.HEX
local tooltip = gf.Tooltip
local loaded = false

---------------------------
-- variables
---------------------------
gf.Quests.Log = {}
gf.Quests.Debug = ""
gv.data = {}
gv.complete = 0

---------------------------
-- arrays
---------------------------
ga.questLog = {
}

---------------------------
-- tooltips for parsing
---------------------------
local QuestsTooltip = CreateFrame("GameTooltip","Glance_Tooltip_Quests",UIParent,"GameTooltipTemplate")
QuestsTooltip:SetOwner(_G.WorldFrame, "ANCHOR_NONE")
local iLevelTooltip = CreateFrame("GameTooltip","Glance_Tooltip_iLevel",UIParent,"GameTooltipTemplate")
iLevelTooltip:SetOwner(_G.WorldFrame, "ANCHOR_NONE")

---------------------------
-- scan in progress icon
---------------------------
local AI = CreateFrame("Frame","Glance_QuestsIcon",GameTooltip);
AI:SetWidth(45);
AI:SetHeight(45);	
AI.texture = AI:CreateTexture(nil,"BACKGROUND");
AI.texture:SetTexture(btn.texture.scan1);
AI.texture:SetAllPoints(AI);		
AI:SetPoint("CENTER",GameTooltip,"BOTTOMLEFT",0,0);
AI:Hide()

---------------------------
-- get Quest Log Status
---------------------------
function gf.Quests.getQuestStatus()
    local numEntries, numQuests = GetNumQuestLogEntries();
    return HEX.yellow .. numQuests .. HEX.white .. "/" .. HEX.green .. 20
end
---------------------------
-- onload
---------------------------
function gf.Quests.onload()
	Glance.Debug("function","onload","Quests")
	-- create character sheet font strings for item levels
	if spa.showIL then
		local function createSlot(slot)
			local fs = _G[slot]:CreateFontString("Glance"..slot.."Text","OVERLAY");
			fs:SetJustifyH("Left");
			fs:SetPoint("BOTTOM",_G[slot],"BOTTOM");
			fs:SetFont("Fonts\\FRIZQT__.TTF", 9, "THICKOUTLINE")
			fs:SetText("|cff00ccff0|r");
			fs:Show();		
        end

		-- hooks for Log on target
		GameTooltip:HookScript("OnTooltipSetUnit",function(self,...)
			if ( UnitExists("mouseover") ) then		
				if (UnitIsUnit("mouseover","target")) then	
					if gv.currentInspectUnit == UnitGUID("mouseover") then
						gf.Quests.Log.tooltipUpdate()
					end
				end
			elseif ( GameTooltip:IsUnit("target") ) then
				if (UnitIsUnit("target","target")) then	
					if gv.currentInspectUnit == UnitGUID("target") then
						gf.Quests.Log.tooltipUpdate()
					end
				end
			end
		end);
		-- set the player overlay data
		gf.Quests.getQuestStatus()
		loaded = true
	end
end
	
---------------------------
-- update (event)
---------------------------
function gf.Quests.update(self, event, arg1)
	if btn.enabled and gv.loaded then -- loaded keeps it from launching when defined
        Glance.Debug("function","update","Quests")

        if (event ~= nil) then
            if (arg1 == nil) then
                if spc.debug then
                    --print("Log: "..event.." - Empty Update")
                end
            end
        end

        gf.setButtonText(btn.button,"Quests: ",gf.Quests.getQuestStatus(),"","")
        -- Play Sound on Objectives Completed
        if event == "QUEST_WATCH_UPDATE" then
            local questID = GetQuestID()

            title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle(arg1);
            local done = true
            --local isInArea, isOnMap, numObjectives1 = GetTaskInfo(arg1)
            local numObjectives = tonumber(GetNumQuestLeaderBoards(arg1))
            if spc.debug then
                --print("QUEST [", arg1,"]", title, ": ", numObjectives, isComplete, questID)
            end
            local i=0
            for i=0,numObjectives do
                --local c, oType, finished = GetQuestObjectiveInfo(arg1, i, false)
                c, otype, finished = GetQuestLogLeaderBoard(i, arg1)
                if finished == false then
                    done = false
                    break
                else
                    if spc.debug then
                        --print("OBJ ", c, ": Completed")
                    end
                end
            end
            --print("QUEST_WATCH_UPDATE: ",title, isComplete)
            if done and spc.playSound then
                if spc.debug then
                    --print("QUEST [", arg1,"]", title, ": Completed")
                end
                PlaySoundFile("Interface\\AddOns\\Glance_Quests\\Sfx\\QuestComplete.ogg", "Master")
            end
        end
        if event == "QUEST_LOG_UPDATE" and arg1 ~= nil then
            local questID = GetQuestID()

            title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle(arg1);
            local done = true
            --local isInArea, isOnMap, numObjectives1 = GetTaskInfo(arg1)
            local numObjectives = tonumber(GetNumQuestLeaderBoards(arg1))
            if spc.debug then
                --print("QUEST [", arg1,"]", title, ": ", numObjectives, isComplete, questID)
            end
            local i=0
            for i=0,numObjectives do
                --local c, oType, finished = GetQuestObjectiveInfo(arg1, i, false)
                c, otype, finished = GetQuestLogLeaderBoard(i, arg1)
                if finished == false then
                    done = false
                    break
                else
                    if spc.debug then
                        --print("OBJ ", c, ": Completed")
                    end
                end
            end
            --print("QUEST_WATCH_UPDATE: ",title, isComplete)
            if done and spc.playSound then
                if spc.debug then
                    --print("QUEST [", arg1,"]", title, ": Completed")
                end
                PlaySoundFile("Interface\\AddOns\\Glance_Quests\\Sfx\\QuestComplete.ogg", "Master")
            end
        end
        -- Accept Quest
        if event == "QUEST_DETAIL" and spc.autoAccept then
            AcceptQuest()
        end
        -- Accept Escort
        if event == "QUEST_ACCEPT_CONFRIM" and spc.autoAccept then
            --ConfirmAcceptQuest()
        end

        -- Talk to NPC (More than 1 Quest)
        if event == "QUEST_GREETING" then
            --CompleteQuest()
        end
        -- Continue to Completion
        if event == "QUEST_ACCEPT_CONFIRM" then
            --CompleteQuest()
            --if ( IsQuestCompletable() ) then QuestFrameCompleteButton:Enable(); end
        end
        if event == "QUEST_PROGRESS" and spc.autoComplete then
            CompleteQuest()
        end
        -- Quest Reward Dialog Reached
        if event == "QUEST_COMPLETE" and spc.autoComplete then
            numChoices = GetNumQuestChoices()
            if spc.debug then
                --print(numChoices.." Quest Rewards")
            end
            if numChoices == 0 then
                GetQuestReward();
            end
        end
        -- Closed Menu
        if event == "QUEST_FINISHED" and spc.autoComplete then
        end
        if event == "QUEST_QUERY_COMPLETE" and spc.autoComplete then
            gv.complete = arg1
        end
	end
end

---------------------------
-- tooltip
---------------------------
function gf.Quests.tooltip()
	Glance.Debug("function","tooltip","Quests")
	tooltip.Title("Quests", "GLD")
    
    
    local numEntries, numQuests = GetNumQuestLogEntries()
    gf.Tooltip.Double("Quests",numQuests,"WHT","GLD")
    gf.Tooltip.Double("Completed",gv.complete,"WHT","GRN")

	-- options and notes
	local tbl = {
		[1] = {["Auto-Accept"] = spc.autoAccept},
		[2] = {["Auto-Complete"] = spc.autoComplete},
		[3] = {["Play Sound"] = spc.playSound},
		[4] = {["Debugging"] = spc.debug},
	}
	tooltip.Options(tbl)
	tooltip.Notes("open the Quest Log",nil,"change Options",nil)	
end

---------------------------
-- click
---------------------------
function gf.Quests.click(self, button, down)
	Glance.Debug("function","click","Quests")
	if button == "LeftButton" then
		--ToggleCharacter("PaperDollFrame")
	end
end

---------------------------
-- menu
---------------------------
function gf.Quests.menu(level,UIDROPDOWNMENU_MENU_VALUE)
	Glance.Debug("function","menu","Quests")
	level = level or 1
	if (level == 1) then
		gf.setMenuTitle("Quests Options")
		gf.setMenuHeader("Auto Accept","autoAccept",level)
		gf.setMenuHeader("Auto Complete","autoComplete",level)
		gf.setMenuHeader("Play Sound","playSound",level)
		gf.setMenuHeader("Debugging","debug",level)
	end
	if (level == 2) then
		if gf.isMenuValue("autoAccept") then
			gf.setMenuOption(spc.autoAccept==true,"On","On",level,function() spc.autoAccept=true; end)
			gf.setMenuOption(spc.autoAccept==false,"Off","Off",level,function() spc.autoAccept=false; end)
		end
		if gf.isMenuValue("autoComplete") then
			gf.setMenuOption(spc.autoComplete==true,"On","On",level,function() spc.autoComplete=true; end)
			gf.setMenuOption(spc.autoComplete==false,"Off","Off",level,function() spc.autoComplete=false; end)
		end
		if gf.isMenuValue("playSound") then
			gf.setMenuOption(spc.playSound==true,"On","On",level,function() spc.playSound=true; end)
			gf.setMenuOption(spc.playSound==false,"Off","Off",level,function() spc.playSound=false; end)
		end
		if gf.isMenuValue("debug") then
			gf.setMenuOption(spc.debug==true,"On","On",level,function() spc.debug=true; end)
			gf.setMenuOption(spc.debug==false,"Off","Off",level,function() spc.debug=false; end)
		end
	end	
end

---------------------------
-- messaging
---------------------------
function gf.Quests.Message()
	Glance.Debug("function","Message","Quests")
	return "|r("..gf.Quests.."%"
end

---------------------------
-- update target tooltip
---------------------------
function gf.Quests.Log.tooltipUpdate()
	if gv.data.scanning or not spa.showTooltipOverlay then return end
	Glance.Debug("function","Log.tooltipUpdate","Quests")
end

---------------------------
-- insert/update tooltip line
---------------------------
function gf.Quests.Log.tooltipAddLine(line,text)	
	-- updating existing line
	if (line > 0) then
		_G["GameTooltipTextLeft"..line]:SetText(text);
	-- adding a new line
	else
		GameTooltip:AddLine(text);
	end
	GameTooltip:Show();
end

---------------------------
-- scan tooltip
---------------------------
function gf.Quests.Log.tooltipScan(link,upgrade)
	iLevelTooltip:ClearLines()
	iLevelTooltip:SetHyperlink(link)
	for i = 1, iLevelTooltip:NumLines() do
		local text = _G["Glance_Tooltip_iLevelTextLeft"..i]:GetText()
		if upgrade then
			local c,t = text:match("Heirloom Upgrade Level: (%d+)/(%d+)")
			if c ~= nil then return tonumber(c), i end
		else
			local match = text:match("Item Level (%d+)")
			if match ~= nil then return tonumber(match), i end
		end
	end
	return 0
end

---------------------------
-- request server data
---------------------------
function gf.Quests.Log.cacheItems()
	Glance.Debug("function","Log.cacheItems","Quests")
	-- checking the items early will start the server requests for data
	-- BOA items are already available, but we have to wait for the rest
	gv.data.missing = 0
	for i = 1,17 do
		local link = nil
		-- not the shirt
		if (i ~= 4) then	
			-- player
			if (UnitIsUnit("target","player")) then
				link = GetInventoryItemLink(GetUnitName("target",true),i);
			-- target
			else
				link = GetInventoryItemLink("target",i);
			end
			if (link) then local iname,_,rarity,level,_,_,subtype,_,equiptype = GetItemInfo(link); end	
			-- the textures if the items are already available
			-- so we can get the true number of missing items
			if not GetInventoryItemTexture("target",i) then
				gv.data.missing = gv.data.missing + 1
			end
		end
	end
end

---------------------------
-- do the fontstrings exist?
---------------------------
function gf.Quests.Log.showOverlays(which,show)
	Glance.Debug("function","Log.showOverlays","Quests")
	DoesNotExist = true
	for i = 1,18 do
		local slot = which..ga.slotItems[i];
		if (_G["Glance"..slot.."Text"]) then
			if show then
				_G["Glance"..slot.."Text"]:Show()
			else
				_G["Glance"..slot.."Text"]:Hide()
			end
			DoesNotExist = false
		end
	end
	if show then
		if DoesNotExist then
			gf.Quests.onload()
		elseif which=="Character" then
			gf.Quests.Log.getEquipmentLevels()
		end
		if which == "Inspect" then
			_G["GlanceInspectFrameText"]:Show()
		end
	else
		if which == "Inspect" then
			_G["GlanceInspectFrameText"]:Hide()
		end
	end
end

---------------------------
-- load on demand
---------------------------
if gv.loaded then
	gf.Enable("Quests")
end