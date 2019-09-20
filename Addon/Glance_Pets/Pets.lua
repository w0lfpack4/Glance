---------------------------
-- lets simplify a bit..
---------------------------
local gf = Glance.Functions
local gv = Glance.Variables
local ga = Glance.Arrays
local gb = Glance.Buttons
local gfrm = Glance.Frames

---------------------------
-- create the button
---------------------------
gf.AddButton("Pets","RIGHT")
local btn = gb.Pets
btn.text              = "      "
btn.enabled           = true
btn.texture.normal    = "Interface\\AddOns\\Glance_Pets\\paw.tga"
btn.texture.favorite  = "Interface\\AddOns\\Glance_Pets\\favorites.tga"
btn.texture.filter    = "Interface\\ChatFrame\\ChatFrameExpandArrow"
btn.texture.health    = "Interface\\AddOns\\Glance_Pets\\health.tga"
btn.texture.power     = "Interface\\AddOns\\Glance_Pets\\power.tga"
btn.texture.speed     = "Interface\\AddOns\\Glance_Pets\\speed.tga"
btn.texture.type      = "Interface\\AddOns\\Glance_Pets\\"
btn.events            = {"COMPANION_LEARNED","COMPANION_UPDATE","PET_JOURNAL_AUTO_SLOTTED_PET","PET_JOURNAL_LIST_UPDATE","PET_JOURNAL_PET_DELETED"}
btn.update            = true
btn.timer1            = true
btn.click             = true
btn.tooltip           = true
btn.menu              = false
btn.save.perAccount   = {}

---------------------------
-- shortcuts
---------------------------
local HEX = ga.colors.HEX
local QA = ga.colors.QUALITY
local QARGB = ga.colors.QUALITYRGB
local tooltip = gf.Tooltip

---------------------------
-- variables
---------------------------
local totalCount, seqtime, position = 0,0,0
local modelWidth = 235
local petHeight = 400
local petWidth = 230
local iconSize = 24
local nameLengthLimit = 18
local hurtCount, maxCount = 0,0
local searchText = ""

---------------------------
-- arrays
---------------------------
ga.PetQualityCount = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
}
ga.PetQuality = {
	[1] = "Poor",
	[2] = "Common",
	[3] = "Uncommon",
	[4] = "Rare",
	[5] = "Epic",
	[6] = "Legendary",
}
ga.petBreed = {
	["B/B"] = "Balance",			--[3]  {.5,.5,.5}
	["P/P"] = "Destruction",		--[4]  {0,2,0}
	["S/S"] = "Ninja",				--[5]  {0,0,2}
	["H/H"] = "Guardian",			--[6]  {2,0,0}
	["H/P"] = "Power & Health",		--[7]  {.9,.9,0}
	["P/S"] = "Power & Speed",		--[8]  {0,.9,.9}
	["H/S"] = "Health & Speed",		--[9]  {.9,0,.9}
	["P/B"] = "Balanced Power",		--[10] {.4,.9,.4}
	["S/B"] = "Balanced Speed",		--[11] {.4,.4,.9}
	["H/B"] = "Balanced Health",	--[12] {.9,.4,.4}
}

---------------------------
-- EasyMenu redirect
---------------------------
function gf.Pets.EasyMenu()
	Glance.Debug("function","EasyMenu","Pets")
	UIDropDownMenu_Initialize(gfrm.petFrameFilterMenu, gf.Pets.Filter_Initialize, "MENU");
	ToggleDropDownMenu(1, nil, gfrm.petFrameFilterMenu, gfrm.petFrameFilter, 0, 0);
end

---------------------------
-- Update Filter Table
---------------------------
function gf.Pets.Filter_Initialize(self,level)
	Glance.Debug("function","Filter_Initialize","Pets")
    local info = UIDropDownMenu_CreateInfo();
	
	-- default
    info.keepShownOnClick = true;   
 
	-- level 1
    if level == 1 then
		-- level 1 defaults
        info.checked =  nil;
        info.isNotRadio = nil;
        info.func =  nil;
        info.hasArrow = true;
        info.notCheckable = true;
        
		-- filter by family
        info.text = PET_FAMILIES
        info.value = 1;
        UIDropDownMenu_AddButton(info, level)
         
		-- filter by source
        info.text = SOURCES
        info.value = 2;
        UIDropDownMenu_AddButton(info, level)
        
		-- sort list
        info.text = RAID_FRAME_SORT_LABEL
        info.value = 3;
        UIDropDownMenu_AddButton(info, level)
     
	-- level 2
    else 	
		-- defaults
		info.hasArrow = false;
		info.isNotRadio = true;
		info.notCheckable = true;
		
		-- filter by family
        if UIDROPDOWNMENU_MENU_VALUE == 1 then
			----------------------
            -- check all         
            info.text = CHECK_ALL
            info.func = function()
                            C_PetJournal.AddAllPetTypesFilter();
                            UIDropDownMenu_Refresh(gfrm.petFrameFilterMenu, 1, 2);
                        end
            UIDropDownMenu_AddButton(info, level)             
			-- check none
            info.text = UNCHECK_ALL
            info.func = function()
                            C_PetJournal.ClearAllPetTypesFilter();
                            UIDropDownMenu_Refresh(gfrm.petFrameFilterMenu, 1, 2);
                        end
            UIDropDownMenu_AddButton(info, level)
			----------------------
			-- iterate families
            info.notCheckable = false;
            local numTypes = C_PetJournal.GetNumPetTypes();
            for i=1,numTypes do
                info.text = _G["BATTLE_PET_NAME_"..i];
                info.func = function(_, _, _, value)
                            C_PetJournal.SetPetTypeFilter(i, value);
                            UIDropDownMenu_Refresh(gfrm.petFrameFilterMenu, 1, 2);
							gf.Pets.applyFilters();
                        end
                info.checked = function() return not C_PetJournal.IsPetTypeFiltered(i) end;
                UIDropDownMenu_AddButton(info, level);
            end
		-- filter by source
        elseif UIDROPDOWNMENU_MENU_VALUE == 2 then
			----------------------
			-- check all
            info.text = CHECK_ALL
            info.func = function()
                            C_PetJournal.AddAllPetSourcesFilter();
                            UIDropDownMenu_Refresh(gfrm.petFrameFilterMenu, 2, 2);
                        end
            UIDropDownMenu_AddButton(info, level)
            -- check none
            info.text = UNCHECK_ALL
            info.func = function()
                            C_PetJournal.ClearAllPetSourcesFilter();
                            UIDropDownMenu_Refresh(gfrm.petFrameFilterMenu, 2, 2);
                        end
            UIDropDownMenu_AddButton(info, level)
			----------------------         
			-- iterate sources
            info.notCheckable = false;
            local numSources = C_PetJournal.GetNumPetSources();
            for i=1,numSources do
                info.text = _G["BATTLE_PET_SOURCE_"..i];
                info.func = function(_, _, _, value)
                            C_PetJournal.SetPetSourceFilter(i, value);
                            UIDropDownMenu_Refresh(gfrm.petFrameFilterMenu, 2, 2);
							gf.Pets.applyFilters()
                        end
                info.checked = function() return not C_PetJournal.IsPetSourceFiltered(i) end;
                UIDropDownMenu_AddButton(info, level);
            end
		-- sort list
        elseif UIDROPDOWNMENU_MENU_VALUE == 3 then
			-- change defaults
            info.isNotRadio = nil;
            info.notCheckable = nil;
            info.keepShownOnClick = nil;    
            -- sort by name
            info.text = NAME
            info.func = function()
                            C_PetJournal.SetPetSortParameter(LE_SORT_BY_NAME);
                            gf.Pets.applyFilters()
                        end
            info.checked = function() return C_PetJournal.GetPetSortParameter() == LE_SORT_BY_NAME end;
            UIDropDownMenu_AddButton(info, level);
            -- sort by level
            info.text = LEVEL
            info.func = function()
                            C_PetJournal.SetPetSortParameter(LE_SORT_BY_LEVEL);
                            gf.Pets.applyFilters()
                        end
            info.checked = function() return C_PetJournal.GetPetSortParameter() == LE_SORT_BY_LEVEL end;
            UIDropDownMenu_AddButton(info, level);
            -- sort by rarity
            info.text = RARITY
            info.func = function()
                            C_PetJournal.SetPetSortParameter(LE_SORT_BY_RARITY);
                            gf.Pets.applyFilters()
                        end
            info.checked = function() return C_PetJournal.GetPetSortParameter() == LE_SORT_BY_RARITY end;
            UIDropDownMenu_AddButton(info, level);
            --sort by type
            info.text = TYPE
            info.func = function()
                            C_PetJournal.SetPetSortParameter(LE_SORT_BY_PETTYPE);
                            gf.Pets.applyFilters()
                        end
            info.checked = function() return C_PetJournal.GetPetSortParameter() == LE_SORT_BY_PETTYPE end;
            UIDropDownMenu_AddButton(info, level);
        end
    end
end

---------------------------
-- update
---------------------------
function gf.Pets.update(self, event, arg1)
	Glance.Debug("function","update","Pets")
	if event == "COMPANION_LEARNED" then
		gf.Pets.build()
	elseif event == "COMPANION_UPDATE" or event == "PET_JOURNAL_AUTO_SLOTTED_PET" or event == "PET_JOURNAL_LIST_UPDATE" or event == "PET_JOURNAL_PET_DELETED" then
		gf.Pets.applyFilters()
	else
		-- hide if moving
		if GetUnitSpeed("Player") ~= 0 then
			if gfrm.petFrame == nil then
				return
			else
				if gfrm.petFrame:IsShown() then
					gfrm.petFrame:Hide()
				end
			end
		end
	end
end

---------------------------
-- tooltip
---------------------------
function gf.Pets.tooltip()	
	Glance.Debug("function","tooltip","Pets")
	local numPets, totalPets = C_PetJournal.GetNumPets()
	-- reset tooltip counts
	for i=1,6 do
		ga.PetQualityCount[i]=0
	end
	hurtCount = 0	
	maxCount = 0	
	-- update tooltip counts
	for i=1,numPets do
		local data = gf.Pets.petInfo(i)
		ga.PetQualityCount[data.rarity] = ga.PetQualityCount[data.rarity] + 1
		if C_PetJournal.PetIsHurt(select(1,C_PetJournal.GetPetInfoByIndex(i, false))) then
			hurtCount = hurtCount + 1
		end
		if data.level >= 25 then
			maxCount = maxCount +1
		end
	end
	tooltip.Title("Pets", "GLD")
	tooltip.Wrap("You have obtained a total of "..HEX.green..totalPets..HEX.white.." companion pets. ","WHT")
	tooltip.Space()
	tooltip.Line("Pet Journal", "GLD")
	tooltip.Wrap("You are displaying "..HEX.green..numPets..HEX.white.." companion pets.","WHT")
	tooltip.Space()
	tooltip.Line("Quality", "GLD")
	tooltip.Wrap(gf.Pets.getBreakdown(),"GLD")
	tooltip.Space()
	tooltip.Line("Health", "GLD")
	if hurtCount == 0 then
		tooltip.Wrap(hurtCount.."/"..numPets..HEX.white.." are injured.","GRN")
	else
		tooltip.Wrap(hurtCount.."/"..numPets..HEX.white.." are injured.","RED")
	end
	tooltip.Space()
	tooltip.Line("Level", "GLD")
	tooltip.Wrap(HEX.green..maxCount..HEX.white.." pets are level 25.","GLD")
	tooltip.Space()
	tooltip.Line("Legend", "GLD")
	tooltip.Line("Pets marked with a star are favorites.","WHT")
	tooltip.Line(HEX.red.."Red |rpets cannot be used as battle pets.","WHT")
	tooltip.Line("Pets are otherwise colored by their "..QA[1].."q"..QA[2].."u"..QA[3].."a"..QA[4].."l"..QA[5].."i"..QA[6].."t|ry.","WHT")
	tooltip.Notes("summon a random pet","dismiss a pet","summon a specific pet",nil,"This list is controlled by the filters in your Pet Journal")
end



---------------------------
-- tooltip quality count
---------------------------
function gf.Pets.getBreakdown()
	Glance.Debug("function","getBreakdown","Pets")
	local b = ""
	if ga.PetQualityCount[6] > 0 then b = b.."|r"..tostring(ga.PetQualityCount[6])..QA[6].." "..ga.PetQuality[6]..". " end
	if ga.PetQualityCount[5] > 0 then b = b.."|r"..tostring(ga.PetQualityCount[5])..QA[5].." "..ga.PetQuality[5]..". " end
	if ga.PetQualityCount[4] > 0 then b = b.."|r"..tostring(ga.PetQualityCount[4])..QA[4].." "..ga.PetQuality[4]..". " end
	if ga.PetQualityCount[3] > 0 then b = b.."|r"..tostring(ga.PetQualityCount[3])..QA[3].." "..ga.PetQuality[3]..". " end
	if ga.PetQualityCount[2] > 0 then b = b.."|r"..tostring(ga.PetQualityCount[2])..QA[2].." "..ga.PetQuality[2]..". " end
	if ga.PetQualityCount[1] > 0 then b = b.."|r"..tostring(ga.PetQualityCount[1])..QA[1].." "..ga.PetQuality[1]..". " end
	return b
end

---------------------------
-- click
---------------------------
function gf.Pets.click(self, button, down)
	Glance.Debug("function","click","Pets")
	Glance.Debug("function","click","Pets")
	if button == "LeftButton" then	
		if IsShiftKeyDown() then
			DismissCompanion("CRITTER")
		else
			C_PetJournal.SummonRandomPet(true);
		end
	elseif button == "RightButton" then
		gf.Pets.build()
		gf.Pets.display()
	end
end

---------------------------
-- is summoned
---------------------------
function gf.Pets.isSummoned(petID)
	Glance.Debug("function","isSummoned","Pets")
	if C_PetJournal.GetSummonedPetGUID() == petID then
		return true
	else
		return false
	end
end

---------------------------
-- get pet info
---------------------------
function gf.Pets.petInfo(id)
	Glance.Debug("function","petInfo","Pets")
	--petID, speciesID, isOwned, customName, level, isFavorite, isRevoked, name, icon, petType, creatureID, cSource, cDescription, isWildPet, canBattle, tradable, unique
	local petID = select(1,C_PetJournal.GetPetInfoByIndex(id, false))
	if petID then
		local data = {}
		local temp = nil
		--speciesID, customName, level, xp, maxXp, displayID, isFavorite, petName, petIcon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique
		temp, data.customName, data.level, data.xp, data.maxXp, data.displayID, data.isFavorite, data.name, data.icon, data.family, temp, data.source, data.description, temp, data.canBattle = C_PetJournal.GetPetInfoByPetID(petID)
		--health, maxHealth, attack, speed, rarity
		data.health, data.maxHealth, data.power, data.speed, data.rarity = C_PetJournal.GetPetStats(petID);		
		data.petID = petID
		
		-- rarity
		data.rarityString = QA[data.rarity]..ga.PetQuality[data.rarity].." |r"
		
		-- specs
		data.healthString = "|T"..btn.texture.health..":16|t "..data.health
		data.powerString = "|T"..btn.texture.power..":16|t "..data.power
		data.speedString = "|T"..btn.texture.speed..":16|t "..data.speed
		
		-- status bars
		data.healthValue = math.floor((data.health/data.maxHealth)*100)
		data.xpValue = math.floor((data.xp/data.maxXp)*100)
		
		-- set the breed if possible
		if IsAddOnLoaded("BattlePetBreedID") then
			data.breed = QA[data.rarity]..ga.petBreed[GetBreedID_Journal(petID)].." |r"
			data.breedSymbol = QA[data.rarity].."("..GetBreedID_Journal(petID)..")|r"
		else
			data.breed = ""
			data.breedSymbol = ""
		end
		
		return data
	else
		return nil
	end
end

---------------------------
-- display pet frame
---------------------------
function gf.Pets.display()
	Glance.Debug("function","display","Pets")
	if gfrm.petFrame:IsShown() then
		gfrm.petFrame:Hide()
	else
		gfrm.petFrame:Show()
		gfrm.petDataFrame:Hide()
	end
end

---------------------------
-- pet button mouseover
---------------------------
function gf.Pets.mouseOver(index, petID, canBattle)
	Glance.Debug("function","mouseOver","Pets")
	local isSummoned = gf.Pets.isSummoned(petID)
	local m_btn = gf.Pets.mapObjects(index)
	-- update the model
	gf.Pets.ModelUpdate(index);
	-- if usable and not summoned then highlight gold
	if not isSummoned and canBattle then
		m_btn.name:SetTextColor(.9, .7, .2 ,1);
	end
end

---------------------------
-- pet button mouseout
---------------------------
function gf.Pets.mouseOut(index, petID, canBattle)
	Glance.Debug("function","mouseOut","Pets")
	local isSummoned = gf.Pets.isSummoned(petID)
	local m_btn = gf.Pets.mapObjects(index)
	-- mouseout, turn off the model
	gf.Pets.ModelUpdate();
	-- if usable and not summoned then turn white
	if not isSummoned and canBattle then
		m_btn.name:SetTextColor(1,1,1,1);
	end		
end

---------------------------
-- pet button mouseclick
---------------------------
function gf.Pets.mouseClick(petID, button)	
	Glance.Debug("function","mouseClick","Pets")
	if button == "LeftButton" then
		-- dismiss or summon
		C_PetJournal.SummonPetByGUID(petID)
	else	
		-- set/unset favorite
		if C_PetJournal.PetIsFavorite(petID) then
			C_PetJournal.SetFavorite(petID, 0)
		else
			C_PetJournal.SetFavorite(petID, 1)
		end
	end
	--reset 
	gf.Pets.applyFilters()
end

---------------------------
-- update model data
---------------------------
function gf.Pets.ModelUpdate(index)
	Glance.Debug("function","ModelUpdate","Pets")
	if (index == nil) then
		gfrm.petModelFrame:ClearModel()
		gfrm.petDataFrame:Hide()
		gfrm.petModelFrame:Hide()
	else
		local data = gf.Pets.petInfo(index)		
		gfrm.petModelFrame:SetDisplayInfo(data.displayID)
		
		local model = gf.Pets.mapObjects()
		-- fontstrings
		model.title:SetText(data.customName or data.name)
		model.title:SetHeight(model.title:GetStringHeight()+15)
		model.description:SetText(data.description.."\n\n"..data.source)
		model.description:SetHeight(model.description:GetStringHeight()+35)
		model.level:SetText(data.level)
		model.specs:SetText(data.breed..data.breedSymbol.."\n"..data.healthString.."  "..data.powerString.."  "..data.speedString)
		model.specs:SetHeight(model.specs:GetStringHeight()+35)
		-- status bars
		model.health:SetValue(data.healthValue)
		model.xp:SetValue(data.xpValue)
		-- icons
		model.family:SetTexture(btn.texture.type..data.family..".tga")	
		if data.isFavorite then
			model.favorite:SetTexture(btn.texture.favorite)	
			model.favorite:SetWidth(16)
		else
			model.favorite:SetTexture(0,0,0,0)	
		end
		-- show the frame
		gfrm.petDataFrame:Show()
		gfrm.petModelFrame:Show()
	end
end

---------------------------
-- update pet status
---------------------------
function gf.Pets.applyFilters()
	Glance.Debug("function","applyFilters","Pets")
	-- not built yet, go away
	if gfrm.petFrame == nil then return end
	local numPets, totalPets = C_PetJournal.GetNumPets()
	-- hide all buttons
	for i=1, totalPets do	
		-- link to the proper objects		
		local m_btn = gf.Pets.mapObjects(i)		
		if m_btn ~= nil then
			-- hide all to start
			m_btn:Hide();
		end
	end	
	-- now iterate the number of pets the filter shows
	for i=1, numPets do	
		-- get the raw data
		local data = gf.Pets.petInfo(i)				
		
		-- link to the proper objects
		local m_btn = gf.Pets.mapObjects(i)	
		
		-- if the button exists
		if m_btn ~= nil then					
		
			-- set everything white and no icon
			m_btn.name:SetTextColor(1,1,1,1)
			m_btn.favorite:SetTexture(0,0,0,0)
			
			-- set rarity
			local r,g,b = unpack(QARGB[data.rarity])
			m_btn.rarity:SetTexture(r,g,b,1)
			
			-- set text (retain a decent width)
			local bName = data.name
			if string.len(bName) > nameLengthLimit then
				bName = string.sub(bName,1,nameLengthLimit)..".."
			end
			
			-- set the level text
			if string.len(data.level) == 1 then
				m_btn.level:SetText("0"..data.level)
			else
				m_btn.level:SetText(data.level)
			end
			
			-- set the breed if available
			if IsAddOnLoaded("BattlePetBreedID") then
				m_btn.breed:SetText(data.breed)
			end
			
			-- set the pet portrait
			m_btn.icon:SetTexture(data.icon)
			
			-- set the pet Family
			m_btn.family:SetTexture(btn.texture.type..data.family..".tga")
			
			-- set the pet name
			m_btn:SetText(bName) 
			
			-- reset the width to actual width
			m_btn:SetWidth(m_btn.name:GetStringWidth()+iconSize+20)
							
			-- mouse events
			m_btn:SetScript("OnEnter", function(self, button, down) gf.Pets.mouseOver(i, data.petID, data.canBattle) end)
			m_btn:SetScript("OnLeave", function(self, button, down) gf.Pets.mouseOut(i, data.petID, data.canBattle) end)
			m_btn:SetScript("OnClick", function(self, button, down) gf.Pets.mouseClick(data.petID, button) end)
			
			-- set favorite icon
			if data.isFavorite then
				m_btn.favorite:SetTexture(btn.texture.favorite)	
				m_btn.favorite:SetWidth(16)
			else
				m_btn.favorite:SetTexture(0,0,0,0)
			end				
			
			-- set summoned color
			if gf.Pets.isSummoned(data.petID) then
				m_btn.name:SetTextColor(.9, .7, .2 ,1)
			end
			
			-- set useable texture
			if not data.canBattle then
				m_btn.name:SetTextColor(1,0,0,.7)
				m_btn.rarity:SetTexture(1,0,0,1)
			end
			
			-- show this one
			m_btn:Show();
		end
	end
end

---------------------------
-- search
---------------------------
function gf.Pets.search(self)
	searchText = self:GetText();
	if searchText == SEARCH then
		C_PetJournal.SetSearchFilter("");
		return;
	end	
	C_PetJournal.SetSearchFilter(searchText);
	gf.Pets.applyFilters()
end

---------------------------
-- build all
---------------------------
function gf.Pets.build()
	Glance.Debug("function","build","Pets")
	gf.Pets.buildFrames()
	gf.Pets.buildButtons()
	gf.Pets.applyFilters()
end

---------------------------
-- build frames
---------------------------
function gf.Pets.buildFrames()
	Glance.Debug("function","buildFrames","Pets")
	if gfrm.petFrame == nil then	
		-------------------------------------------------------------
		-- create main container
		gfrm.petFrame = CreateFrame("FRAME", "Glance_petFrame", Glance_Buttons_Pets, "TooltipBorderedFrameTemplate")
		gfrm.petFrame:SetPoint("TOPRIGHT", Glance_Buttons_Pets, "BOTTOMRIGHT", 0, 0)	
		gfrm.petFrame:SetWidth(petWidth)
		gfrm.petFrame:SetHeight(petHeight)
		gfrm.petFrame:SetAlpha(.9)
		gfrm.petFrame:SetFrameStrata("High")
		gfrm.petFrame:Hide()
		--gfrm.petFrame:SetScript("OnLeave", function(self, button, down) gfrm.petFrame:Hide() end)

		-- create list petScrollFrame
		gfrm.petScrollFrame = CreateFrame("ScrollFrame", "Glance_petScrollFrame", gfrm.petFrame, "UIPanelScrollFrameTemplate")
		gfrm.petScrollFrame:SetPoint("TOPLEFT", gfrm.petFrame, "TOPLEFT", 10, -40)	
		gfrm.petScrollFrame:SetWidth(gfrm.petFrame:GetWidth()-40)
		gfrm.petScrollFrame:SetHeight(gfrm.petFrame:GetHeight()-51)
		gfrm.petScrollFrame:Show()

		-- create list frame
		gfrm.petListFrame = CreateFrame("FRAME", "Glance_petListFrame", gfrm.petScrollFrame)
		gfrm.petListFrame:SetPoint("TOPLEFT", gfrm.petScrollFrame, "TOPLEFT", 0, 0)	
		gfrm.petListFrame:SetWidth(gfrm.petScrollFrame:GetWidth())
		gfrm.petListFrame:SetHeight(gfrm.petScrollFrame:GetHeight())
		gfrm.petListFrame:Show()	

		-- bind the list to the petScrollFrame
		gfrm.petScrollFrame:SetScrollChild(gfrm.petListFrame)
		
		-- create the filter by type button
		gfrm.petFrameFilterMenu = CreateFrame("Frame", "Glance_petFrameFilterMenu", nil, "UIDropDownMenuTemplate")
		gfrm.petFrameFilter = CreateFrame("BUTTON", "Glance_petFrameFilter", gfrm.petFrame, "UIMenuButtonStretchTemplate")
		gfrm.petFrameFilter:SetPoint("TOPLEFT", gfrm.petFrame, "TOPLEFT", 10, -10)	
		gfrm.petFrameFilter:SetWidth(100)
		gfrm.petFrameFilter:SetHeight(30)
		gfrm.petFrameFilter:Show()		
		
		-- create the icon overlay
		gfrm.petFrameFilter.arrowtexture = gfrm.petFrameFilter:CreateTexture("Glance_Pet_Filter_Icon", "OVERLAY")
		gfrm.petFrameFilter.arrowtexture:SetTexture(btn.texture.filter)
		gfrm.petFrameFilter.arrowtexture:SetPoint("RIGHT",-5,0)
		gfrm.petFrameFilter.arrowtexture:SetWidth(12)
		gfrm.petFrameFilter.arrowtexture:SetHeight(10)
		
		-- create the font
		local fs = gfrm.petFrameFilter:CreateFontString("Glance_petFrameFilter_FontString")
		fs:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+7)
		fs:SetJustifyH("LEFT")
		fs:SetJustifyV("CENTER")
		fs:SetPoint("LEFT", 10, 0)
		fs:SetTextColor(.9, .7, .2,1)				
		
		-- create the text
		gfrm.petFrameFilter:SetFontString(fs)
		gfrm.petFrameFilter:SetText("Filters")
		
		-- reset the width to actual width
		gfrm.petFrameFilter:SetWidth(fs:GetStringWidth()+30)
		gfrm.petFrameFilter:SetHeight(fs:GetStringHeight()+10)
		
		-- register for clicks
		gfrm.petFrameFilter:RegisterForClicks("AnyUp")			
		
		-- mouse events
		gfrm.petFrameFilter:SetScript("OnClick", function(self, button, down) gf.Pets.EasyMenu() end)
		
		-- create the close button
		gfrm.petFrameClose = CreateFrame("BUTTON", "Glance_petFrameClose", gfrm.petFrame, "UIPanelCloseButton")
		gfrm.petFrameClose:SetPoint("TOPRIGHT", gfrm.petFrame, "TOPRIGHT", -5, -6)	
		gfrm.petFrameClose:SetWidth(30)
		gfrm.petFrameClose:SetHeight(30)
						
		-- create the search box
		gfrm.petFrameSearch = CreateFrame("EDITBOX", "Glance_petFrameSearch", gfrm.petFrameFilter, "SearchBoxTemplate")
		gfrm.petFrameSearch:SetPoint("TOPLEFT", gfrm.petFrameFilter, "TOPRIGHT", 10, 5)	
		gfrm.petFrameSearch:SetWidth(gfrm.petFrame:GetWidth()-gfrm.petFrameFilter:GetWidth()-gfrm.petFrameClose:GetWidth()-25)
		gfrm.petFrameSearch:SetHeight(30)
		gfrm.petFrameSearch:SetScript("OnTextChanged", function(self, userInput) SearchBoxTemplate_OnTextChanged(self); gf.Pets.search(self) end)
		
		-------------------------------------------------------------
		
		-- create main model data container
		gfrm.petDataFrame = CreateFrame("FRAME", "Glance_petDataFrame", gfrm.petFrame, "TooltipBorderedFrameTemplate")
		gfrm.petDataFrame:SetPoint("TOPRIGHT", gfrm.petFrame, "TOPLEFT", 0, 0)	
		gfrm.petDataFrame:SetWidth(modelWidth)
		gfrm.petDataFrame:SetHeight(petHeight)
		gfrm.petDataFrame:Hide()
				
		-- create the title
		local title = gfrm.petDataFrame:CreateFontString("Glance_Pet_Model_Title")
		title:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+7)
		title:SetJustifyH("CENTER")
		title:SetJustifyV("CENTER")
		title:SetWordWrap(true)
		title:SetPoint("TOP", gfrm.petDataFrame, "TOP", 0, -5)
		title:SetTextColor(.9, .7, .2 ,1)
		title:SetHeight(20)
		title:SetWidth(modelWidth-40)		
		
		-- create the level
		local level = gfrm.petDataFrame:CreateFontString("Glance_Pet_Model_Level")
		level:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+9)
		level:SetJustifyH("CENTER")
		level:SetJustifyV("CENTER")
		level:SetWordWrap(true)
		level:SetPoint("TOPRIGHT", gfrm.petDataFrame, "TOPRIGHT", -10, -8)
		level:SetTextColor(.9, .7, .2 ,1)
		level:SetHeight(20)
		level:SetWidth(20)	
		
		-- set favorite icon
		gfrm.petDataFrame.favtexture = gfrm.petDataFrame:CreateTexture("Glance_Pet_Model_Favorite", "OVERLAY")
		gfrm.petDataFrame.favtexture:SetTexture(0,0,0,0)
		gfrm.petDataFrame.favtexture:SetPoint("TOPLEFT",10,-10)
		gfrm.petDataFrame.favtexture:SetWidth(16)
		
		-- create the notes
		local notes = gfrm.petDataFrame:CreateFontString("Glance_Pet_Model_Notes")
		notes:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+6)
		notes:SetJustifyH("LEFT")
		notes:SetJustifyV("BOTTOM")
		notes:SetPoint("BOTTOMLEFT", gfrm.petDataFrame, "BOTTOMLEFT", 10, 10)
		notes:SetTextColor(1, .46, 0 ,1)
		notes:SetWidth(modelWidth)
		notes:SetText("Left-Click to summon.\nRight-Click to set favorite.")
		
		-------------------------------------------------------------
		
		-- create model frame
		gfrm.petModelFrame = CreateFrame("PlayerModel","Glance_petModelFrame",gfrm.petFrame)
		gfrm.petModelFrame:SetPoint("TOP",gfrm.petDataFrame,"TOP",0,-25)
		gfrm.petModelFrame:SetHeight(modelWidth-100)
		gfrm.petModelFrame:SetWidth(modelWidth-10)
		gfrm.petModelFrame:SetPosition(0,0,0)
		gfrm.petModelFrame:SetAlpha(1)
		gfrm.petModelFrame:Hide()
		-- rotate the critter smoothly..
		gfrm.petModelFrame:SetScript("OnUpdate", function(self, elapsed) 
			seqtime = seqtime + elapsed; 
			if seqtime >= .01 then
				seqtime = 0
				position = position + .01
				if position <= 6.2 then
					gfrm.petModelFrame:SetFacing(position);
				else
					position = 0
					gfrm.petModelFrame:SetFacing(position);
				end
			end
		end)
		
		-- set type icon
		gfrm.petModelFrame.typetexture = gfrm.petModelFrame:CreateTexture("Glance_Pet_Model_Family", "OVERLAY")
		gfrm.petModelFrame.typetexture:SetTexture(0,0,0,0)
		gfrm.petModelFrame.typetexture:SetPoint("BOTTOMLEFT",8,8)
		gfrm.petModelFrame.typetexture:SetHeight(32)
		gfrm.petModelFrame.typetexture:SetWidth(32)
		
		-- set health bar
		gfrm.petModelHealthBar = CreateFrame("StatusBar", "Glance_Pet_Model_Health_Bar", gfrm.petModelFrame)
		gfrm.petModelHealthBar:SetPoint("TOPLEFT", gfrm.petModelFrame, "BOTTOMLEFT", 0, 0)
		gfrm.petModelHealthBar:SetWidth(gfrm.petModelFrame:GetWidth())
		gfrm.petModelHealthBar:SetHeight(5)
		gfrm.petModelHealthBar:SetMinMaxValues(0, 100)
		gfrm.petModelHealthBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
		gfrm.petModelHealthBar:GetStatusBarTexture():SetHorizTile(false)
		gfrm.petModelHealthBar:GetStatusBarTexture():SetVertTile(false)
		gfrm.petModelHealthBar:SetStatusBarColor(0, 0.65, 0)
		gfrm.petModelHealthBar.bg = gfrm.petModelHealthBar:CreateTexture(nil, "BACKGROUND")
		gfrm.petModelHealthBar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
		gfrm.petModelHealthBar.bg:SetAllPoints(true)
		gfrm.petModelHealthBar.bg:SetVertexColor(0, 0.35, 0)
		
		-- set xp bar
		gfrm.petModelXPBar = CreateFrame("StatusBar", "Glance_Pet_Model_XP_Bar", gfrm.petModelHealthBar)
		gfrm.petModelXPBar:SetPoint("TOPLEFT", gfrm.petModelHealthBar, "BOTTOMLEFT", 0, -37)
		gfrm.petModelXPBar:SetWidth(gfrm.petModelFrame:GetWidth())
		gfrm.petModelXPBar:SetHeight(5)
		gfrm.petModelXPBar:SetMinMaxValues(0, 100)
		gfrm.petModelXPBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
		gfrm.petModelXPBar:GetStatusBarTexture():SetHorizTile(false)
		gfrm.petModelXPBar:GetStatusBarTexture():SetVertTile(false)
		gfrm.petModelXPBar:SetStatusBarColor(.4, .8, .94)
		gfrm.petModelXPBar.bg = gfrm.petModelXPBar:CreateTexture(nil, "BACKGROUND")
		gfrm.petModelXPBar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
		gfrm.petModelXPBar.bg:SetAllPoints(true)
		gfrm.petModelXPBar.bg:SetVertexColor(0, 0, 0.65)
				
		-- create the specs
		local specs = gfrm.petModelHealthBar:CreateFontString("Glance_Pet_Model_Specs")
		specs:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+7)
		specs:SetJustifyH("CENTER")
		specs:SetJustifyV("TOP")
		specs:SetPoint("TOP", gfrm.petModelHealthBar, "BOTTOM", 5, -5)
		specs:SetTextColor(1, 1, 1 ,1)
		specs:SetWidth(modelWidth-15)
		
		-- create the description
		local description = gfrm.petModelXPBar:CreateFontString("Glance_Pet_Model_Description")
		description:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+6)
		description:SetJustifyH("LEFT")
		description:SetJustifyV("TOP")
		description:SetPoint("TOPLEFT", gfrm.petModelXPBar, "BOTTOMLEFT", 5, -5)
		description:SetTextColor(1, 1, 1 ,1)
		description:SetWidth(modelWidth-15)
		
	end
end

---------------------------
-- build buttons
---------------------------
function gf.Pets.buildButtons()
	Glance.Debug("function","buildButtons","Pets")
	-- variables
	local previousFrame = gfrm.petListFrame
	local numPets, totalPets = C_PetJournal.GetNumPets()
	-- counts do not match, update buttons
	if totalCount ~= totalPets then
		-- totalCount not zero, buttons have been built before, reset previous
		if totalCount > 0 then
			if _G["Glance_Pet_Buttons_"..totalCount] == nil then
				-- let's not throw an error checking for nil
			else
				-- this should be the last button
				previousFrame = _G["Glance_Pet_Buttons_"..totalCount]
			end
		end
		for i=1, totalPets do	
			-- if we have not yet created this button.
			if _G["Glance_Pet_Buttons_"..i] == nil then
				-- create the frame
				local m_btn = CreateFrame("BUTTON", "Glance_Pet_Buttons_"..i, gfrm.petListFrame)
				m_btn:SetHeight(iconSize)
				m_btn:SetWidth(250)
				
				-- create the icon overlay
				m_btn.rarity = m_btn:CreateTexture("Glance_Pet_Buttons_Texture_Highlight_"..i, "BACKGROUND")
				m_btn.rarity:SetTexture(0,0,0,0)
				m_btn.rarity:SetPoint("TOPLEFT",-1,1)
				m_btn.rarity:SetWidth(iconSize+2)
				m_btn.rarity:SetHeight(iconSize+2)
				
				-- set the icon
				m_btn.icon = m_btn:CreateTexture("Glance_Pet_Buttons_Texture_Icon_"..i, "ARTWORK")
				m_btn.icon:SetTexture(0,0,0,0)
				m_btn.icon:SetPoint("TOPLEFT",0,0)
				m_btn.icon:SetWidth(iconSize)
				m_btn.icon:SetHeight(iconSize)			
				
				-- set favorite icon
				m_btn.favorite = m_btn:CreateTexture("Glance_Pet_Buttons_Texture_Favorite_"..i, "OVERLAY")
				m_btn.favorite:SetTexture(0,0,0,0)
				m_btn.favorite:SetPoint("TOPLEFT",-5,5)
				m_btn.favorite:SetWidth(16)
				m_btn.favorite:SetHeight(16)
				
				-- set family icon
				m_btn.family = m_btn:CreateTexture("Glance_Pet_Buttons_Texture_Family_"..i, "OVERLAY")
				m_btn.family:SetTexture(0,0,0,0)
				m_btn.family:SetPoint("TOPLEFT", m_btn.rarity, "TOPRIGHT", 2, 0)
				m_btn.family:SetWidth(16)
				m_btn.family:SetHeight(16)	
				
				-- create the font
				local fs = m_btn:CreateFontString("Glance_Pet_Buttons_FontString_Name_"..i)
				fs:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+7)
				fs:SetJustifyH("LEFT")
				if IsAddOnLoaded("BattlePetBreedID") then
					fs:SetJustifyV("TOP")
				else
					fs:SetJustifyV("CENTER")
				end
				fs:SetPoint("TOPLEFT", iconSize+20, 0)
				fs:SetTextColor(1,1,1,1)
				
				-- create the level font
				local lvlfs = m_btn:CreateFontString("Glance_Pet_Buttons_FontString_Level_"..i)
				lvlfs:SetFont("Fonts\\FRIZQT__.TTF", 9, "THICKOUTLINE")
				lvlfs:SetJustifyH("CENTER")
				lvlfs:SetJustifyV("CENTER")
				lvlfs:SetPoint("BOTTOMLEFT", m_btn.rarity, "BOTTOMRIGHT", 2, 0)
				lvlfs:SetTextColor(.9, .7, .2,1)
				
				-- create the breed font
				local brdfs = m_btn:CreateFontString("Glance_Pet_Buttons_FontString_Breed_"..i)
				brdfs:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+5)
				brdfs:SetJustifyH("LEFT")
				brdfs:SetJustifyV("CENTER")
				brdfs:SetPoint("BOTTOMLEFT", m_btn.rarity, "BOTTOMRIGHT", 21, 0)
				brdfs:SetTextColor(.9, .7, .2,.6)
				
				
				-- create the text
				m_btn:SetFontString(fs)
				m_btn:SetText("Button"..i)
				
				-- position it
				if previousFrame == gfrm.petListFrame then
					m_btn:SetPoint("TOPLEFT", gfrm.petListFrame, "TOPLEFT", 5, -5)
				else
					m_btn:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -5)
				end
				
				--make this frame the previous frame
				previousFrame = _G["Glance_Pet_Buttons_"..i]	
				
				-- reset the width to actual width
				m_btn:SetWidth(fs:GetStringWidth()+iconSize+20)
				m_btn:SetHeight(iconSize+6)
				
				-- register for clicks
				m_btn:RegisterForClicks("AnyUp")					
				
				-- turn it on
				m_btn:Show()
			end
		end
		totalCount = totalPets
	end
end

---------------------------
-- return a list of linked objects
---------------------------
function gf.Pets.mapObjects(index)
	if index then
		local m_btn = _G["Glance_Pet_Buttons_"..index]
		if m_btn then
			m_btn.name     = _G["Glance_Pet_Buttons_FontString_Name_"..index]
			m_btn.level    = _G["Glance_Pet_Buttons_FontString_Level_"..index]
			m_btn.breed    = _G["Glance_Pet_Buttons_FontString_Breed_"..index]
			m_btn.icon     = _G["Glance_Pet_Buttons_Texture_Icon_"..index]
			m_btn.favorite = _G["Glance_Pet_Buttons_Texture_Favorite_"..index]
			m_btn.family   = _G["Glance_Pet_Buttons_Texture_Family_"..index]
			m_btn.rarity   = _G["Glance_Pet_Buttons_Texture_Highlight_"..index]			
			return m_btn
		else
			return nil
		end
	else
		local model = {}		
		model.title       = _G["Glance_Pet_Model_Title"]
		model.description = _G["Glance_Pet_Model_Description"]
		model.health      = _G["Glance_Pet_Model_Health_Bar"]
		model.xp          = _G["Glance_Pet_Model_XP_Bar"]
		model.favorite    = _G["Glance_Pet_Model_Favorite"]
		model.level       = _G["Glance_Pet_Model_Level"]
		model.specs       = _G["Glance_Pet_Model_Specs"]
		model.family      = _G["Glance_Pet_Model_Family"]
		return model
	end
end

---------------------------
-- load on demand
---------------------------
if gv.loaded then
	gf.Enable("Pets")
end