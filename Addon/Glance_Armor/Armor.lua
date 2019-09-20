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
gf.AddButton("Armor","LEFT")
local btn = gb.Armor
btn.text			  	= "Armor"
btn.enabled		   		= true
btn.events				= {"MERCHANT_SHOW","UNIT_DAMAGE","UPDATE_INVENTORY_DURABILITY","PLAYER_EQUIPMENT_CHANGED","PLAYER_ENTERING_WORLD","UNIT_INVENTORY_CHANGED","INSPECT_READY","PLAYER_TARGET_CHANGED"}
btn.texture.scan1       = "Interface\\AddOns\\Glance_Armor\\scan1.tga"
btn.texture.scan2       = "Interface\\AddOns\\Glance_Armor\\scan2.tga"
btn.onload              = true
btn.update				= true
btn.tooltip		   		= true
btn.menu			  	= true
btn.click				= true
btn.save.perCharacter 	= {["autoRepair"] = true}
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
gf.Armor.iLvl = {}
gf.Armor.repair = {}
gv.currentInspectUnit = nil
gv.data = {}

---------------------------
-- arrays
---------------------------
ga.slotItems = {
	"HeadSlot",
	"NeckSlot",
	"ShoulderSlot",
	"ShirtSlot",
	"ChestSlot",
	"WaistSlot",
	"LegsSlot",
	"FeetSlot",
	"WristSlot",
	"HandsSlot",
	"Finger0Slot",
	"Finger1Slot",
	"Trinket0Slot",
	"Trinket1Slot",
	"BackSlot",
	"MainHandSlot",
	"SecondaryHandSlot",	
    "TabardSlot",
	--"Ranged",
    --"INVTYPE_RANGEDRIGHT",
}
--select(9,GetItemInfo(GetInventoryItemID("Player", GetInventorySlotInfo("MainHandSlot"))))
--/script local _, _, _, iLevel = GetItemInfo(GetInventoryItemID("Player", GetInventorySlotInfo("slot")));print(iLevel)
--/script print(select(9,GetItemInfo(link)))
gv.party.a["Armor"] = 0
gv.party.b["Armor"] = 0
gv.party.c["Armor"] = 0
gv.party.d["Armor"] = 0

---------------------------
-- tooltips for parsing
---------------------------
local ArmorTooltip = CreateFrame("GameTooltip","Glance_Tooltip_Armor",UIParent,"GameTooltipTemplate")
ArmorTooltip:SetOwner(_G.WorldFrame, "ANCHOR_NONE")
local iLevelTooltip = CreateFrame("GameTooltip","Glance_Tooltip_iLevel",UIParent,"GameTooltipTemplate")
iLevelTooltip:SetOwner(_G.WorldFrame, "ANCHOR_NONE")

---------------------------
-- scan in progress icon
---------------------------
local AI = CreateFrame("Frame","Glance_ArmorIcon",GameTooltip);
AI:SetWidth(45);
AI:SetHeight(45);	
AI.texture = AI:CreateTexture(nil,"BACKGROUND");
AI.texture:SetTexture(btn.texture.scan1);
AI.texture:SetAllPoints(AI);		
AI:SetPoint("CENTER",GameTooltip,"BOTTOMLEFT",0,0);
AI:Hide()

---------------------------
-- onload
---------------------------
function gf.Armor.onload()
	Glance.Debug("function","onload","Armor")
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
		-- can't add the labels if the Frame doesn't exist
		if spa.showInspectOverlay then InspectUnit("player") end
		-- iterate slots
		for i = 1,18 do
			if (ga.slotItems[i] ~= "ShirtSlot" and ga.slotItems[i] ~= "TabardSlot") then
				-- create character sheet slot text
				if spa.showCharacterOverlay then
					local slot = "Character"..ga.slotItems[i];
					if (slot and _G[slot]) and not _G["Glance"..slot.."Text"] then
						createSlot(slot)
					end
				end
				-- create inspect sheet slot text
				if spa.showInspectOverlay then
					local slot = "Inspect"..ga.slotItems[i];
					if (slot and _G[slot]) and not _G["Glance"..slot.."Text"] then
						createSlot(slot)
					end
				end
			end
		end
		-- create inspect frame avg ilevel	
		if spa.showInspectOverlay then		
			local fs = InspectPaperDollFrame:CreateFontString("GlanceInspectFrameText","OVERLAY");
			fs:SetJustifyH("Center");
			fs:SetJustifyV("TOP")
			fs:SetPoint("TOP",InspectPaperDollFrame,"TOP",0,-45);
			fs:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+6)
			fs:SetText(HEX.gold.."Average Item Level: ");
			fs:Show();		
			-- hide the inspect frame
			ClearInspectPlayer()
		end
		-- hooks for iLvl on target
		GameTooltip:HookScript("OnTooltipSetUnit",function(self,...)
			if ( UnitExists("mouseover") ) then		
				if (UnitIsUnit("mouseover","target")) then	
					if gv.currentInspectUnit == UnitGUID("mouseover") then
						gf.Armor.iLvl.tooltipUpdate()
					end
				end
			elseif ( GameTooltip:IsUnit("target") ) then		
				if (UnitIsUnit("target","target")) then	
					if gv.currentInspectUnit == UnitGUID("target") then
						gf.Armor.iLvl.tooltipUpdate()
					end
				end
			end
		end);		
		-- set the player overlay data
		gf.Armor.iLvl.getEquipmentLevels()
		loaded = true
	end
end
	
---------------------------
-- update (event)
---------------------------
function gf.Armor.update(self, event, arg1)
	if btn.enabled and gv.loaded then -- loaded keeps it from launching when defined
		Glance.Debug("function","update","Armor")
		gf.setButtonText(btn.button,"Armor: ",gf.Armor.getDurability().."%","","")
		-- auto repair
		if event == "MERCHANT_SHOW" then
			gf.Armor.repair.repairAll()
		-- update character tab overlays
		elseif event == "PLAYER_EQUIPMENT_CHANGED" or  event == "PLAYER_ENTERING_WORLD" then
			if (loaded and spa.showIL) then gf.Armor.iLvl.getEquipmentLevels() end			
		-- target item level
		elseif event == "PLAYER_TARGET_CHANGED" then	
			if InspectFrame and InspectFrame:IsShown() then InspectUnit("target"); end
			if ( UnitExists("target") and spa.showIL ) then
				--reset variables
				gf.Armor.iLvl.reset();
				if (UnitIsUnit("target","target")) then	
					-- send the inspection request
					if CanInspect("target") then
						gv.data.scanning = true;
						gv.data.scanCount = 1;
						if spa.showTooltipOverlay then
							AI.texture:SetTexture(btn.texture.scan1);
							AI:Show()
						end
						gv.currentInspectUnit = UnitGUID("target")
						NotifyInspect("target")
					end
				end
			end
		-- after notify inspect
		elseif event == "INSPECT_READY" then
			if gv.currentInspectUnit == arg1 and spa.showIL then
				-- preload
				gf.Armor.iLvl.cacheItems()
				-- set the timer to get the stats
				Glance.Timers["Inspect"] = {1,5,false,"Armor","getStats",nil} --min,max,reset,button,func,var				
			end
		end
	end
end

---------------------------
-- tooltip
---------------------------
function gf.Armor.tooltip()
	Glance.Debug("function","tooltip","Armor")
	tooltip.Title("Armor", "GLD")
	
	-- repair line
	local TotalInvCost, TotalBagCost, TotalRepairCost = gf.Armor.repair.getRepairCost()
	if TotalRepairCost > 0 then
		tooltip.Line("The total cost to repair your armor is: "..GetCoinTextureString(TotalRepairCost,0), "WHT")
	else
		tooltip.Line("Your armor is fully repaired.", "WHT")
	end
	
	-- item levels
	local itemLevel, eItemLevel = GetAverageItemLevel()
	itemLevel = math.floor(itemLevel)
	eItemLevel = math.floor(eItemLevel)
	if itemLevel > 0 then
		tooltip.Space()
		tooltip.Line("Item Level (iLvl)", "GLD")
		--tooltip.Double("Average Item Level",gf.Armor.iLvl.color(itemLevel), "WHT", "WHT")
		tooltip.Double("Equipped Item Level",gf.Armor.iLvl.color(eItemLevel), "WHT", "WHT")
	end
		
	-- party stats
	local GetNumPartyMembers, _ = GetNumSubgroupMembers()
	if ((GetNumPartyMembers ~= 0 and sender ~= UnitName("player")) or gv.Debug) and Glance_Local.Options.sendStats then
		gf.addonQuery("Armor")
		tooltip.Space()
		tooltip.Double("Party"..gf.crossRealm(), "(eLVL/iLVL)/DUR", "GLD", "GLD")	
		gf.partyTooltip("Armor")
	end	
	
	-- options and notes
	local tbl = {
		[1] = {["Auto-Repair"] = spc.autoRepair},
		[2] = {["Check Item Level on Target"] = spa.showIL},
	}
	tooltip.Options(tbl)
	tooltip.Notes("open the character tab",nil,"change Options",nil)	
end

---------------------------
-- click
---------------------------
function gf.Armor.click(self, button, down)
	Glance.Debug("function","click","Armor")
	if button == "LeftButton" then
		ToggleCharacter("PaperDollFrame")
	end
end

---------------------------
-- menu
---------------------------
function gf.Armor.menu(level,UIDROPDOWNMENU_MENU_VALUE)
	Glance.Debug("function","menu","Armor")
	level = level or 1
	if (level == 1) then
		gf.setMenuTitle("Armor Options")
		gf.setMenuHeader("Auto Repair","autorepair",level)
		gf.setMenuHeader("Check Item Level","showil",level)
	end
	if (level == 2) then
		if gf.isMenuValue("autorepair") then
			gf.setMenuOption(spc.autoRepair==true,"On","On",level,function() spc.autoRepair=true; end)
			gf.setMenuOption(spc.autoRepair==false,"Off","Off",level,function() spc.autoRepair=false; end)
		end
		if gf.isMenuValue("showil") then
			gf.setMenuOption(spa.showIL==true,"On","On",level,function() spa.showIL=true; gf.Armor.iLvl.showOverlays("Character",spa.showCharacterOverlay); gf.Armor.iLvl.showOverlays("Inspect",spa.showInspectOverlay); end)
			gf.setMenuOption(spa.showIL==false,"Off","Off",level,function() spa.showIL=false; gf.Armor.iLvl.showOverlays("Character",false); gf.Armor.iLvl.showOverlays("Inspect",false); end)
			gf.setMenuHeader("Character Frame Overlays","showCO",level, not spa.showIL)
			gf.setMenuHeader("Inspect Frame Overlays","showIO",level, not spa.showIL)
			gf.setMenuHeader("Tooltip Overlays","showTT",level, not spa.showIL)
		end
	end	
	if (level == 3) then
		if gf.isMenuValue("showCO") then
			gf.setMenuOption(spa.showCharacterOverlay==true,"On","On",level,function() spa.showCharacterOverlay=true; gf.Armor.iLvl.showOverlays("Character",true); end)
			gf.setMenuOption(spa.showCharacterOverlay==false,"Off","Off",level,function() spa.showCharacterOverlay=false; gf.Armor.iLvl.showOverlays("Character",false); end)
		end
		if gf.isMenuValue("showIO") then
			gf.setMenuOption(spa.showInspectOverlay==true,"On","On",level,function() spa.showInspectOverlay=true; gf.Armor.iLvl.showOverlays("Inspect",true); end)
			gf.setMenuOption(spa.showInspectOverlay==false,"Off","Off",level,function() spa.showInspectOverlay=false; gf.Armor.iLvl.showOverlays("Inspect",false); end)
		end
		if gf.isMenuValue("showTT") then
			gf.setMenuOption(spa.showTooltipOverlay==true,"On","On",level,function() spa.showTooltipOverlay=true; end)
			gf.setMenuOption(spa.showTooltipOverlay==false,"Off","Off",level,function() spa.showTooltipOverlay=false;  end)
		end
	end
end

---------------------------
-- messaging
---------------------------
function gf.Armor.Message()
	Glance.Debug("function","Message","Armor")
	local itemLevel, eItemLevel = GetAverageItemLevel()
	itemLevel = math.floor(itemLevel)
	eItemLevel = math.floor(eItemLevel)
	return "|r("..gf.Armor.iLvl.color(eItemLevel).."|r/"..gf.Armor.iLvl.color(itemLevel).."|r)/"..gf.Armor.getDurability().."%"
end
	
---------------------------
-- durability 
---------------------------
function gf.Armor.getDurability()
	Glance.Debug("function","getDurability","Armor")
	local have, most, pct = 0,0,0
	local sOut
	for i = 1, 19 do
		local current, max = GetInventoryItemDurability(i)
		if current ~= nil then
			have = have + current
			most = most + max
		end
	end
	if most > 0 then
		pct = math.floor((have/most) * 100)
		if pct >= 75 then
			sOut = HEX.green..pct
		elseif pct < 75 and pct > 50 then
			sOut = HEX.yellow..pct
		else
			sOut = HEX.red..pct
		end
	end
	return sOut or HEX.gray.."0"
end

---------------------------
-- return guild funds available
---------------------------
function gf.Armor.getGuildFunds()
	return nil
end

---------------------------
-- reset iLvl data
---------------------------
function gf.Armor.iLvl.reset()
	Glance.Debug("function","iLvl.reset","Armor")
	gv.data.spec = nil
	gv.data.iLvl = 0;
	gv.data.boa = 0;
	gv.data.badboa = 0;
	gv.data.pvp = 0;
	gv.data.mia = 0;
	gv.data.fury = false;
	gv.data.slot = {}
	for i = 1,17 do
		gv.data.slot[i] = 0
	end
end 

---------------------------
-- colorize avg iLvl
---------------------------
function gf.Armor.iLvl.color(iLvl,unit)
	Glance.Debug("function","iLvl.color","Armor")
	if not unit then unit = "player" end
	-- going with 30 points difference between each quality lvl
	local rare = gf.Armor.iLvl.getBOALevel(unit,2)
	local epic = rare + 30
	local legendary = epic + 30
	local uncommon = rare - 30
	local common = uncommon - 30
	local poor = common - 30		
	local r, g, b, hex
	if iLvl <= poor then 
		r, g, b, hex = GetItemQualityColor(0);
	end
	if iLvl > poor and iLvl <= common then 
		r, g, b, hex = GetItemQualityColor(1);
	end
	if iLvl > common and iLvl <= uncommon then 
		r, g, b, hex = GetItemQualityColor(2);
	end
	if iLvl > uncommon and iLvl <= rare then 
		r, g, b, hex = GetItemQualityColor(3);
	end
	if iLvl > rare and iLvl <= epic then 
		r, g, b, hex = GetItemQualityColor(4);
	end
	if iLvl > epic then 
		r, g, b, hex = GetItemQualityColor(5);
	end
	return "|c"..hex..iLvl
end

---------------------------
-- set slot text
---------------------------
function gf.Armor.iLvl.setSlotText(slot,il,avg)
	if (_G["Glance"..slot.."Text"]) then
		-- item level is less than average
		if (tonumber(il) < avg) then	
			-- item level is more than 15 points below avg (white)
			if (tonumber(il) < (avg-15)) then
				_G["Glance"..slot.."Text"]:SetTextColor(1,0.8,0,1);
			-- item level is within 15 points of avg (green)
			else
				_G["Glance"..slot.."Text"]:SetTextColor(0,1,0.2,1);
			end
		-- item level is greater than average
		else
			-- item level is greater than 15 points above average (purple)
			if (tonumber(il) > (avg+15)) then
				_G["Glance"..slot.."Text"]:SetTextColor(1,.5,1,1);
			-- item level is within 15 points of average (blue)
			else
				_G["Glance"..slot.."Text"]:SetTextColor(0,0.8,1,1);
			end
		end
		_G["Glance"..slot.."Text"]:SetText(il)
	end
end

---------------------------
-- update target tooltip
---------------------------
function gf.Armor.iLvl.tooltipUpdate()
	if gv.data.scanning or not spa.showTooltipOverlay then return end	
	Glance.Debug("function","iLvl.tooltipUpdate","Armor")
	local outputLine, matched, index = nil, false, 0;		
	-- adding or editing the spec line
	if gv.data.spec then
		outputLine = HEX.yellow.."Spec: "..gv.data.spec
		for i = 2, GameTooltip:NumLines() do
			if ((_G["GameTooltipTextLeft"..i]:GetText() or ""):match("^"..HEX.yellow.."Spec: ")) then
				index = i;
				break;
			end
		end
		gf.Armor.iLvl.tooltipAddLine(index,outputLine); index = 0;
	end
		
	-- adding or editing the iLvl lines
	if gv.data.iLvl > 0 then
		-- print the item level
		outputLine = HEX.white.."iLvl: |r"..gf.Armor.iLvl.color(gv.data.iLvl,"target")
		-- wearing BOA gear
		if gv.data.boa > 0 then
			outputLine = outputLine..HEX.boa.."  BOA: "..gv.data.boa
		end
		-- outdated boa gear
		if gv.data.badboa > 0 then
			outputLine = outputLine..HEX.red.."  BAD: "..gv.data.badboa
		end
		-- wearing PVP gear
		if gv.data.pvp > 0 then
			outputLine = outputLine..HEX.lightblue.."  PVP: "..gv.data.pvp	
		end
		-- missing items
		if gv.data.mia > 0 then
			outputLine = outputLine..HEX.red.."  MIA: "..gv.data.mia	
		end
		
		for i = 2, GameTooltip:NumLines() do
			if ((_G["GameTooltipTextLeft"..i]:GetText() or ""):match("^"..HEX.white.."iLvl: ")) then
				index = i;
				break;
			end
		end
		gf.Armor.iLvl.tooltipAddLine(index,outputLine); index = 0;
	end
end

---------------------------
-- insert/update tooltip line
---------------------------
function gf.Armor.iLvl.tooltipAddLine(line,text)	
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
function gf.Armor.iLvl.tooltipScan(link,upgrade)
	iLevelTooltip:ClearLines()
	iLevelTooltip:SetHyperlink(link)
	for i = 1, iLevelTooltip:NumLines() do
		local text = _G["Glance_Tooltip_iLevelTextLeft"..i]:GetText()
		-- if upgrade then
        --     local c,t = text:match("Heirloom Upgrade Level: (%d+)/(%d+)")
        --     print("TT Scan Match: Link="..link.." Level="..tonumber(c))
		-- 	if c ~= nil then return tonumber(c), i end
		-- else
		-- 	local match = text:match("Requires Level (%d+)")
        --     --print("TT Scan Match: Link="..link.." Level="..tonumber(match))
		-- 	if match ~= nil then return tonumber(match), i end
		-- end
	end
    local _, _, _, iLevel = GetItemInfo(link);
	return iLevel
end

---------------------------
-- calculate BOA iLvl
---------------------------
function gf.Armor.iLvl.getBOALevel(unit,upgrade)
	local pl = UnitLevel(unit)	
	-- upgrade cap 0 = 60, 1 = 90, 2 = 100
	if upgrade == 0 and pl > 60 then pl = 60; gv.data.badboa = gv.data.badboa + 1 end
	if upgrade == 1 and pl > 90 then pl = 90; gv.data.badboa = gv.data.badboa + 1 end
	if upgrade == 2 and pl > 100 then pl = 100; gv.data.badboa = gv.data.badboa + 1 end
	
	-- completely off the top of my head, but the numbers will all match wowhead's boa calculator
	-- draenor
	if pl >= 91 and pl <= 100 then
		-- previous iLvl (level 90)
		local base = 463
		if pl >= 98 then
			return ((base+((17*4)-1)) + ((tonumber(pl)-91) * 10) - ((tonumber(pl)-97)*5))
		else
			return ((base+((17*4)-1)) + ((tonumber(pl)-91) * 10))
		end
	
	-- pandaria (51 points from level 80 ilvl then increases 20pts per level)
	elseif pl >= 86 and pl <= 90 then
		-- previous iLvl (level 85)
		local base = 333
		-- wowhead calculator is 1 pt below this calculation from level 63-67, so we adjust
		if pl >= 89 then base = base -1 end
		return ((base+(17*3)) + ((tonumber(pl)-86) * 20))
	
	-- cata (out of control.. 92 points from level 80 iLvl, then increases 14pts per level)
	elseif pl >= 81 and pl <= 85 then
		-- previous iLvl (level 80)
		local base = 187
		-- wowhead calculator is 2 pts below this calculation for level 85, so we adjust
		if pl == 85 then base = base -2 end
		-- wowhead calculator is 1 pt below this calculation from level 83-84, so we adjust
		if pl >= 83 and pl <= 84 then base = base -1 end
		return ((base+92) + ((tonumber(pl)-81) * 14))
	
	-- wrath (34 points from level 67 ilvl then increases 4pts per level)
	elseif pl >= 68 and pl <= 80 then
		-- previous iLvl (level 67)
		local base = 105
		return ((base+(17*2)) + ((tonumber(pl)-68) * 4))
	
	-- outlands (17 points from level 57 ilvl then increases 3pts per level)
	elseif pl >= 58 and pl <= 67 then
		-- previous iLvl (level 57)
		local base = 62
		-- wowhead calculator is 1 pt below this calculation from level 63-67, so we adjust
		if pl >= 63 then base = base -1 end
		return ((base+17) + ((tonumber(pl)-58) * 3))
	
	-- vanilla (player level - 5)
	elseif pl >= 6 and pl <= 57 then
		return tonumber(pl) - 5
		
	-- first 5 levels are just 10
	elseif pl >= 1 and pl <= 5 then
		return 10
		
	-- default to something
	else
		return 0
	end
end

---------------------------
-- request server data
---------------------------
function gf.Armor.iLvl.cacheItems()
	Glance.Debug("function","iLvl.cacheItems","Armor")
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
-- get target stats
---------------------------
function gf.Armor.getStats() gf.Armor.iLvl.getStats(); end
function gf.Armor.iLvl.getStats()
	if not spa.showIL then return end
	Glance.Debug("function","iLvl.getStats","Armor")
	-- locals
	local specID, lvl, count = nil,1,0;
	local dualHand, miaMainHand, miaOffHand = false, false, false;
	local lClass, eClass = UnitClass("target");
	
	-- end if mismatch
	if not gv.currentInspectUnit == UnitGUID("target") then return end
		
    -- get the player spec
    -- Outdated 60200
	-- if (UnitIsUnit("target","player")) then
    --     local currentSpec = GetSpecialization();
	-- 	local specID = currentSpec and select(1, GetSpecializationInfo(currentSpec))
	-- 	gv.data.spec = select(2,GetSpecializationInfoByID(specID));
	-- -- get the target spec
	-- -- else
	-- -- 	if (UnitLevel("target") > 9) then
	-- -- 		local specID = GetInspectSpecialization("target");
	-- -- 		local _, specName = GetSpecializationInfoByID(specID);
	-- -- 		gv.data.spec = select(2,GetSpecializationInfoByID(specID));
	-- -- 	end
	-- end
	
	-- fury spec
	if (specID == "268") then
		gv.data.fury = true
	end	
	
	-- iterate equipment
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
			-- if we get a link
			if (link) then
				--get the item info
				local iname,_,rarity,wowlevel,_,_,subtype,_,equiptype = GetItemInfo(link);	
				
				-- get the item level from the tooltip
				local level, line = gf.Armor.iLvl.tooltipScan(link)
				
				--do two-handed check based on mainhand weapon
				if (i == 16) then
					if (equiptype == "INVTYPE_2HWEAPON" or equiptype == "INVTYPE_RANGED" or equiptype == "INVTYPE_RANGEDRIGHT") then
						dualHand = true;
					else
						dualHand = false;
					end
				end
				
                --print("Info: Link="..link.." Level="..level.." Rarity="..rarity)
				-- check other stats
				if (level) then
					-- check for boa gear
					if (rarity == 7) then
						-- boa returned earlier as 1 from GetItemInfo or 436 from tooltip scan. 
						-- this is the default boa level before the player level is calculated.
						local upgrade, line = gf.Armor.iLvl.tooltipScan(link,true)					
						level = gf.Armor.iLvl.getBOALevel("target",upgrade)
						--print("upg:"..upgrade.." lvl:"..level.." bad:"..gv.data.badboa)
						-- count the boa gear
						gv.data.boa = gv.data.boa + 1;
						count = count + 1;
					-- check for pvp gear
					else
						local stats = GetItemStats(link);
						count = count + 1

						-- check for resilience
						for stat, value in pairs(stats) do
							if (stat == "ITEM_MOD_RESILIENCE_RATING_SHORT" or stat == "ITEM_MOD_PVP_POWER_SHORT") then
								gv.data.pvp = gv.data.pvp + 1;
								break;
							end
						end
					end
					lvl = lvl + level
                    gv.data.slot[i] = level
				end
			else
				--could not get item information, probably missing
				if (i==16) then
					miaMainHand = true;
				elseif (i==17) then
					miaOffHand = true;
				end
				--based on furySpec, evaluate the equipped weapons
				if (i==17 and gv.data.fury) then
					--player has titan's grip, so we should count this as a missing item.
					count = count + 1;
					gv.data.mia = gv.data.mia + 1;
				else
					--player does not have titans grip. Check if they have a two-hander equipped.
					if (i==17 and dualHand == true) then
						--two hander equipped, so we can't ding them for the missing off-hand
					else
						--not a two hander so we need to ding them for missing a slot
						count = count + 1;
						gv.data.mia = gv.data.mia + 1;
					end
				end
			end
		end
	end
	
	--make adjustments to the calculation based on above equipment evaluation
	if (miaMainHand and miaOffHand and eClass ~= "ROGUE" and gv.data.fury == false) then
		--if they are missing both main and offhand but can cover both by equipping a two-hander,
		--only count it against them once.
		gv.data.mia = gv.data.mia - 1;
		count = count - 1;
	end
	
	--set the item level average
	if (count > 0) then		
		gv.data.iLvl = floor((lvl/count)*1)/1;
	else
		gv.data.iLvl = 0;
	end
	
	-- if mia is greater than the true number of missing items then rescan (max 5 times)
	if (gv.data.mia > gv.data.missing) and gv.data.scanCount < 5 then
		gv.data.scanCount = gv.data.scanCount + 1
		if spa.showTooltipOverlay then AI.texture:SetTexture(btn.texture.scan2); end
		gf.Armor.update(self, "INSPECT_READY", UnitGUID("target"))
	else
		--[[print("----------------")
		print("ScanCount: "..HEX.yellow..gv.data.scanCount)
		print("Missing: "..HEX.yellow..gv.data.missing)
		print("MIA: "..HEX.yellow..gv.data.mia)
		print("BOA: "..HEX.yellow..gv.data.boa)
		print("BAD: "..HEX.yellow..gv.data.badboa)
		print("TotalLevel / ItemsWorn = "..lvl.."/"..count.." = "..HEX.yellow..gv.data.iLvl)--]]
		gv.data.scanning = false;
		if spa.showTooltipOverlay then
			AI:Hide()		
			gf.Armor.iLvl.tooltipUpdate()
		end
		if spa.showInspectOverlay then
			for i = 1,17 do
				local slot = "Inspect"..ga.slotItems[i];
				gf.Armor.iLvl.setSlotText(slot,gv.data.slot[i],gv.data.iLvl)
			end
			_G["GlanceInspectFrameText"]:SetText(HEX.gold.."Average Item Level: "..gf.Armor.iLvl.color(gv.data.iLvl,"target"))
		end
	end
	--ClearInspectPlayer()
end

---------------------------
-- do the fontstrings exist?
---------------------------
function gf.Armor.iLvl.showOverlays(which,show)
	Glance.Debug("function","iLvl.showOverlays","Armor")
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
			gf.Armor.onload()
		elseif which=="Character" then
			gf.Armor.iLvl.getEquipmentLevels()
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
-- find item levels
---------------------------

---------------------------
-- item level by slot
---------------------------

function gf.Armor.iLvl.GetItemLevel(slot)
	if GetInventoryItemID("Player", GetInventorySlotInfo(slot)) ~= nil then
		local _, _, _, iLevel = GetItemInfo(GetInventoryItemID("Player", GetInventorySlotInfo(slot)));
		return iLevel;
	else 
		return -1;
	end
end

---------------------------
-- legacy average item level
---------------------------

function GetAverageItemLevel()
	local itemLevel = 0
    local eItemLevel = 0
	for i=1,#ga.slotItems do
		eItemLevel = eItemLevel + gf.Armor.iLvl.GetItemLevel(ga.slotItems[i]);
	end
	if select(9,GetItemInfo(GetInventoryItemID("Player", GetInventorySlotInfo("MainHandSlot")))) == "INVTYPE_2HWEAPON" then
		eItemLevel = math.floor(eItemLevel/#ga.slotItems-1)
	else
		eItemLevel = math.floor(eItemLevel/#ga.slotItems)
    end
    print("Average Item Level: ",eItemLevel)
    return eItemLevel, eItemLevel
end

function gf.Armor.iLvl.getEquipmentLevels()
	if not spa.showCharacterOverlay then return end
	Glance.Debug("function","iLvl.getEquipmentLevels","Armor")
    --local itemLevel, eItemLevel = GetAverageItemLevel() Oudated 60200
    local itemLevel, eItemLevel = GetAverageItemLevel()
	for i = 1,18 do
		local slot = "Character"..ga.slotItems[i];
		if (i ~= 4) then
            local link = GetInventoryItemLink(GetUnitName("player",true),i);
			if (link) then
				local il, line = gf.Armor.iLvl.tooltipScan(link)
				if not il then il = -1 end
				gf.Armor.iLvl.setSlotText(slot,il,itemLevel)
			end
		end
	end	
end

---------------------------
-- repair costs
---------------------------
function gf.Armor.repair.getRepairCost()
	Glance.Debug("function","repair.getRepairCost","Armor")
	local TotalInventoryCost = 0
	local TotalBagCost = 0
	-- equipped
	for i=1, #ga.slotItems do
		local slotId, textureName = GetInventorySlotInfo(ga.slotItems[i])
		local hasItem, hasCooldown, repairCost = Glance_Tooltip_Armor:SetInventoryItem("player", slotId);
		if hasItem then
			TotalInventoryCost = TotalInventoryCost + (repairCost or 0)
		end
	end
	-- bags
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local _, repairCost = Glance_Tooltip_Armor:SetBagItem(bag, slot);
			TotalBagCost = TotalBagCost + (repairCost or 0)
		end
	end
	Glance_Tooltip_Armor:Hide()
	return TotalInventoryCost, TotalBagCost, TotalInventoryCost + TotalBagCost
end
 	
---------------------------
-- return guild funds available
---------------------------
function CanGuildBankRepair()
    return false -- Outdated 60200
end
function gf.Armor.repair.canRepair()
	Glance.Debug("function","repair.canRepair","Armor")
	local val
	if spc.guildRepair then val = "On" else val = "Off" end
	if not CanGuildBankRepair() then val=HEX.gray..val end
	return val
end

---------------------------
-- armor repair
---------------------------
function gf.Armor.repair.repairAll()
	Glance.Debug("function","repair.repairAll","Armor")			
	if CanMerchantRepair()==true and spc.autoRepair then
		local cost, needed = GetRepairAllCost();	
		if needed then
			if CanGuildBankRepair() and spc.guildRepair then
				local funds = GetGuildBankWithdrawMoney()
				if cost > funds then
					local funds = GetMoney()
					if cost > funds then
						gf.sendMSG("You don't have enough money for repair!");
					else
						RepairAllItems();
						--PlaySound("LOOTWINDOWCOINSOUND")
						gf.sendMSG("There was not enough money in your daily guild bank allotment for repair.  Your items have been repaired from your own funds for "..GetCoinTextureString(cost,0))		
					end
				else
					RepairAllItems(1)
					--PlaySound("LOOTWINDOWCOINSOUND")
					gf.sendMSG("Your items have been repaired by the guild for "..GetCoinTextureString(cost,0))
					return
				end
			else
				local funds = GetMoney()
				if cost > funds then
					gf.sendMSG("You don't have enough money for repair!");
				else
					RepairAllItems();
					--PlaySound("LOOTWINDOWCOINSOUND")
					gf.sendMSG("Your items have been repaired for "..GetCoinTextureString(cost,0))	
				end
			end
		end
	end
end

---------------------------
-- load on demand
---------------------------
if gv.loaded then
	gf.Enable("Armor")
end