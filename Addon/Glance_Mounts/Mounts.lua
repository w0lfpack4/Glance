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
gf.AddButton("Mounts","RIGHT")
local btn = gb.Mounts
btn.text              = "      "
btn.enabled           = true
btn.texture.normal    = "Interface\\AddOns\\Glance_Mounts\\mount.tga"
btn.texture.favorite  = "Interface\\AddOns\\Glance_Mounts\\favorites.tga"
btn.texture.filter    = "Interface\\ChatFrame\\ChatFrameExpandArrow"
btn.events            = {"COMPANION_LEARNED","COMPANION_UPDATE","MOUNT_JOURNAL_USABILITY_CHANGED","ZONE_CHANGED","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED_INDOORS"}
btn.update            = true
btn.timer1            = true
btn.click             = true
btn.tooltip           = true
btn.menu              = false
btn.options           = true
btn.save.perAccount   = {
	["showGround"] = true,
	["showFlying"] = true,
	["showUnderwater"] = true,
	["showChauffeured"] = true,
	["showNoSwimming"] = true,
	["showOverwater"] = true,
	["showZoneLocked"] = true,
	["showFavorites"] = true,
}
btn.save.allowProfile = true

---------------------------
-- shortcuts
---------------------------
local HEX = ga.colors.HEX
local tooltip = gf.Tooltip
local spa = btn.save.perAccount

---------------------------
-- variables
---------------------------
local totalCount, seqtime, position = 0,0,0
local firstRun = true
local modelWidth = 225
local mountHeight = 400
local iconSize = 20
local Filter = {}

---------------------------
-- not available till lvl 30
---------------------------
if UnitLevel("player") < 20 then btn.enabled = false end

---------------------------
-- commands
---------------------------
gf.AddCommand("Mounts","random","Summon a random mount",function() if IsMounted() then C_MountJournal.Dismiss() else C_MountJournal.SummonByID(0) end end)

---------------------------
-- arrays
---------------------------
ga.mountFlags = {
	--land, air, sea, swim, water walk, location lock, dead
	[230] = "This is a ground mount.", -- ground mounts
	[231] = "This is a ground and underwater breathing mount.", -- riding turtle and sea turtle
	[232] = "This underwater breathing mount can only be used in Vashj'ir.", -- vash seahorses
	[241] = "This ground mount can only be used in the Temple of Ahn'Qiraj.", -- battle tanks
	[242] = "This flying mount can only be used when dead.", -- spectral gryphon
	[247] = "This flying mount can not swim or jump.", -- red flying cloud no swimming
	[248] = "This is a flying mount.", -- flying mounts
	[254] = "This is an underwater breathing mount.", -- subdued seahorse
	[269] = "This is a water-walking ground mount.", -- water striders
	[284] = "This is a chauffeured mount available from level 1.", -- Chauffeured Mekgineer's Chopper and Chauffeured Mechano-Hog
}	

---------------------------
-- EasyMenu redirect
---------------------------
function gf.Mounts.EasyMenu(doubleToggle)
	Glance.Debug("function","EasyMenu","Mounts")
	-- needed to overload this function to get the filters to generate dynamically
    UIDropDownMenu_Initialize(gfrm.mountFrameFilterMenu, EasyMenu_Initialize, "MENU", nil, gf.Mounts.Filter());
	ToggleDropDownMenu(1, nil, gfrm.mountFrameFilterMenu, gfrm.mountFrameFilter, 0, 0, gf.Mounts.Filter(), nil, 1);
	if doubleToggle then
		ToggleDropDownMenu(1, doubleToggle, gfrm.mountFrameFilterMenu, gfrm.mountFrameFilter, 0, 0, gf.Mounts.Filter(), nil, 3);
	end
end

---------------------------
-- Update Filter Table
---------------------------
function gf.Mounts.Filter()
	Glance.Debug("function","Filter","Mounts")
	Filter = {
		{ 
			text = "Filter Types:", 
			isTitle = true, 
			notCheckable = true, 
			notClickable = true 
		},
		{ 
			text = "by Mount Type:", 
			hasArrow = true, 
			notCheckable = true, 
			menuList = { 					
				{ 
					text = "Show Only:", 
					isTitle = true, 
					notCheckable = true, 
					notClickable = true 
				},				
				{ 
					text = CHECK_ALL,     
					func = function() 
						spa.showGround = true; 
						spa.showFlying = true;
						spa.showUnderwater = true;
						gf.Mounts.applyFilters(); 
						gf.Mounts.EasyMenu(true); 
					end, 
					notCheckable = true, 
				},
				{ 
					text = UNCHECK_ALL,     
					func = function() 
						spa.showGround = false; 
						spa.showFlying = false;
						spa.showUnderwater = false;
						gf.Mounts.applyFilters(); 
						gf.Mounts.EasyMenu(true); 
					end, 
					notCheckable = true, 
				},
				{ 
					text = "Ground",     
					func = function() spa.showGround = not spa.showGround; gf.Mounts.applyFilters(); gf.Mounts.EasyMenu(true); end, 
					checked = spa.showGround, 
					isNotRadio = true, 
					keepShownOnClick = true, 
				},
				{ 
					text = "Flying",     
					func = function() spa.showFlying= not spa.showFlying; gf.Mounts.applyFilters(); gf.Mounts.EasyMenu(true); end, 
					checked = spa.showFlying, 
					isNotRadio = true, 
					keepShownOnClick = true, 
				},
				{ 
					text = "Underwater", 
					func = function() spa.showUnderwater = not spa.showUnderwater; gf.Mounts.applyFilters(); gf.Mounts.EasyMenu(true); end, 
					checked = spa.showUnderwater, 
					isNotRadio = true, 
					keepShownOnClick = true, 
				},			
			}
		},
		{ 
			text = "by Quirks:", 
			hasArrow = true, 
			notCheckable = true, 
			menuList = { 		
				{ 
					text = "Include:", 
					isTitle = true, 
					notCheckable = true, 
					notClickable = true 
				},
				{
					text = CHECK_ALL,     
					func = function() 
						spa.showChauffeured = true;
						spa.showNoSwimming = true;
						spa.showOverwater = true;
						spa.showZoneLocked = true;
						gf.Mounts.applyFilters(); 
						gf.Mounts.EasyMenu(true); 
					end, 
					notCheckable = true, 
				},
				{ 
					text = UNCHECK_ALL,     
					func = function() 
						spa.showChauffeured = false;
						spa.showNoSwimming = false;
						spa.showOverwater = false;
						spa.showZoneLocked = false;
						gf.Mounts.applyFilters(); 
						gf.Mounts.EasyMenu(true); 
					end, 
					notCheckable = true, 
				},
				{ 
					text = "Chauffeured",     
					func = function() spa.showChauffeured = not spa.showChauffeured; gf.Mounts.applyFilters(); gf.Mounts.EasyMenu(true); end, 
					checked = spa.showChauffeured, 
					isNotRadio = true, 
					keepShownOnClick = true, 
				},
				{ 
					text = "No Swimming",     
					func = function() spa.showNoSwimming = not spa.showNoSwimming; gf.Mounts.applyFilters(); gf.Mounts.EasyMenu(true); end, 
					checked = spa.showNoSwimming, 
					isNotRadio = true, 
					keepShownOnClick = true, 
				},
				{ 
					text = "Water Walking",  
					func = function() spa.showOverwater = not spa.showOverwater; gf.Mounts.applyFilters(); gf.Mounts.EasyMenu(true); end, 
					checked = spa.showOverwater, 
					isNotRadio = true, 
					keepShownOnClick = true, 
				},
				{ 
					text = "Zone Locked",     
					func = function() spa.showZoneLocked = not spa.showZoneLocked; gf.Mounts.applyFilters(); gf.Mounts.EasyMenu(true); end, 
					checked = spa.showZoneLocked, 
					isNotRadio = true, 
					keepShownOnClick = true, 
				},
			}
		},		
		{ 
			text = "by Favorites", 
			hasArrow = true, 
			notCheckable = true, 
			menuList = { 		
				{ 
					text = "Show Only:", 
					isTitle = true, 
					notCheckable = true, 
					notClickable = true 
				},
				{ 
					text = "Favorites",     
					func = function() spa.showFavorites = not spa.showFavorites; gf.Mounts.applyFilters(); gf.Mounts.EasyMenu(true);  end, 
					checked = spa.showFavorites, 
					isNotRadio = true, 
					keepShownOnClick = true, 
				},
			}
		},			
	}
	return Filter
end

---------------------------
-- options
---------------------------
function gf.Mounts.options()
	Glance.Debug("function","Options","Mounts")
	local pIDX = gf.createPanel("Macros","The following macro can be made to randomize your mounts.  The choice of mount is determined by your settings in the Mounts panel.",nil)
	gf.createText(pIDX,15,-60,"/glance random","GameFontNormal","")
	gf.createText(pIDX,15,-75,"Summons a favorite random mount best suited for the area you are in.","GameFontHighlight","")
end

---------------------------
-- update
---------------------------
function gf.Mounts.update(self, event, arg1)
	Glance.Debug("function","update","Mounts")
	if event == "COMPANION_LEARNED" then
		gf.Mounts.build()
	elseif event == "COMPANION_UPDATE" or event =="MOUNT_JOURNAL_USABILITY_CHANGED" or event=="ZONE_CHANGED" or event=="ZONE_CHANGED_NEW_AREA" or event=="ZONE_CHANGED_INDOORS" then
		gf.Mounts.checkForUpdates()
	else
		-- hide if moving
		if GetUnitSpeed("Player") ~= 0 then
			if gfrm.mountFrame == nil then
				return
			else
				if gfrm.mountFrame:IsShown() then
					gfrm.mountFrame:Hide()
				end
			end
		end
	end
end

---------------------------
-- tooltip
---------------------------
function gf.Mounts.tooltip()
	Glance.Debug("function","tooltip","Mounts")
	local cc, tc = gf.Mounts.GetNumMounts()
	tooltip.Title("Mounts", "GLD")
	tooltip.Line("You have collected "..HEX.green..tc..HEX.white.." mounts.","WHT")
	tooltip.Line(HEX.green..cc..HEX.white.." are available to this character.","WHT")
	tooltip.Space()
	tooltip.Line("Legend", "GLD")
	tooltip.Line(HEX.red.."Red |rmounts cannot be used in this area.","WHT")
	tooltip.Notes("summon or dismiss a random mount",nil,"summon a specific mount",nil,"Only favorite mounts will be summoned randomly")
end

---------------------------
-- actual mount count
---------------------------
function gf.Mounts.GetNumMounts()
	Glance.Debug("function","GetNumMounts","Mounts")
	local totalCount, charCount, pFaction = 0,0,0
	if UnitFactionGroup("player") == "Alliance" then pFaction = 1 end
	for i=1, C_MountJournal.GetNumMounts() do
		local cName, cSpellID, cIcon, isSummoned, isUsable, sourceType, isFavorite, isFactionSpecific, faction, hideOnChar, isCollected = C_MountJournal.GetMountInfoByID(i)
		if (isCollected) then
			totalCount = totalCount + 1
		end
		-- if you have it, and it's the right faction
		if (isCollected and not hideOnChar) then
			-- some incorrect faction models make it this far
			if (isFactionSpecific and faction == pFaction) or not isFactionSpecific then
				charCount = charCount + 1
			end
		end
	end
	return charCount, totalCount
end

---------------------------
-- icon click
---------------------------
function gf.Mounts.click(self, button, down)
	Glance.Debug("function","click","Mounts")
	if button == "LeftButton" then
		if IsMounted() then
			C_MountJournal.Dismiss()
		else
			C_MountJournal.SummonByID(0)
		end
	else	
		gf.Mounts.build()
		gf.Mounts.display()
	end
end

---------------------------
-- summon
---------------------------
function gf.Mounts.summon(cID)
	Glance.Debug("function","summon","Mounts")
	local isUsable = select(5,C_MountJournal.GetMountInfoByID(cID))
	local isSummoned = select(4,C_MountJournal.GetMountInfoByID(cID))
	if IsIndoors() then isUsable = false end
	if isSummoned then
		C_MountJournal.Dismiss(cID)
	else
		if isUsable then
			C_MountJournal.SummonByID(cID)
		end
	end
end

---------------------------
-- display mount frame
---------------------------
function gf.Mounts.display()
	Glance.Debug("function","display","Mounts")
	if gfrm.mountFrame:IsShown() then
		gfrm.mountFrame:Hide()
	else
		gfrm.mountFrame:Show()
		gfrm.mountDataFrame:Hide()
	end
end

---------------------------
-- mount button mouseover
---------------------------
function gf.Mounts.mouseOver(cID, cSpellID, cDisplayID, cName, cDescription)
	Glance.Debug("function","mouseOver","Mounts")
	local isUsable = select(5,C_MountJournal.GetMountInfoByID(cID))
	local isSummoned = select(4,C_MountJournal.GetMountInfoByID(cID))
	local fs = _G["Glance_Mount_Buttons_FontString_"..cSpellID]
	if IsIndoors() then isUsable = false end
	-- update the model
	gf.Mounts.ModelUpdate(cDisplayID, cName, cDescription);
	-- if usable and not summoned then highlight gold
	if isUsable and not isSummoned then
		fs:SetTextColor(.9, .7, .2 ,1);
	end
end

---------------------------
-- mount button mouseout
---------------------------
function gf.Mounts.mouseOut(cID, cSpellID)
	Glance.Debug("function","mouseOut","Mounts")
	local isUsable = select(5,C_MountJournal.GetMountInfoByID(cID))
	local isSummoned = select(4,C_MountJournal.GetMountInfoByID(cID))
	local fs = _G["Glance_Mount_Buttons_FontString_"..cSpellID]
	if IsIndoors() then isUsable = false end
	-- mouseout, turn off the model
	gf.Mounts.ModelUpdate();
	-- if usable and not summoned then turn white
	if isUsable and not isSummoned then
		fs:SetTextColor(1,1,1,1);
	end		
end

---------------------------
-- mount button mouseclick
---------------------------
function gf.Mounts.mouseClick(cID, button)	
	Glance.Debug("function","mouseClick","Mounts")
	if button == "LeftButton" then
		-- dismiss or summon
		gf.Mounts.summon(cID)
	else	
		-- set/unset favorite
		C_MountJournal.SetIsFavorite(cID, not C_MountJournal.GetIsFavorite(cID))
	end
	--reset 
	gf.Mounts.checkForUpdates()
end

---------------------------
-- update model data
---------------------------
function gf.Mounts.ModelUpdate(id,title,desc)
	Glance.Debug("function","ModelUpdate","Mounts")
	if (id == nil) then
		gfrm.mountModelFrame:ClearModel()
		gfrm.mountDataFrame:Hide()
		gfrm.mountModelFrame:Hide()
	else
		gfrm.mountModelFrame:SetDisplayInfo(id)
		_G["Glance_Mount_Model_Title"]:SetText(title)
		_G["Glance_Mount_Model_Title"]:SetHeight(_G["Glance_Mount_Model_Title"]:GetStringHeight()+15)
		_G["Glance_Mount_Model_Description"]:SetText(desc)
		_G["Glance_Mount_Model_Description"]:SetHeight(_G["Glance_Mount_Model_Description"]:GetStringHeight()+35)
		gfrm.mountDataFrame:Show()
		gfrm.mountModelFrame:Show()
	end
end

---------------------------
-- update mount status
---------------------------
function gf.Mounts.checkForUpdates()
	Glance.Debug("function","checkForUpdates","Mounts")
	-- not built yet, go away
	if gfrm.mountFrame == nil then return end
	
	for i=1, C_MountJournal.GetNumMounts() do
		local cName, cSpellID, cIcon, isSummoned, isUsable, sourceType, isFavorite, isFactionSpecific, faction, hideOnChar, isCollected = C_MountJournal.GetMountInfoByID(i)
		local cDisplayID, cDescription, cSource, isSelfMount, mountFlags = C_MountJournal.GetMountInfoExtraByID(i)
		
		-- bliz used to handle this..
		if IsIndoors() then isUsable = false end
					
		-- link to the proper objects
		if cSpellID then
			local m_btn = _G["Glance_Mount_Buttons_"..cSpellID]
			local fs = _G["Glance_Mount_Buttons_FontString_"..cSpellID]
			
			-- if the button exists
			if m_btn ~= nil then		
				-- link to the textures
				m_btn.favtexture = _G["Glance_Mount_Buttons_FTexture_"..cSpellID]
				m_btn.usetexture = _G["Glance_Mount_Buttons_UTexture_"..cSpellID]		
				
				-- set everything white and no icon
				fs:SetTextColor(1,1,1,1)
				m_btn.usetexture:SetTexture(0,0,0,0)
				m_btn.favtexture:SetTexture(0,0,0,0)
				
				-- set favorite icon
				if isFavorite then
					m_btn.favtexture:SetTexture(btn.texture.favorite)	
					m_btn.favtexture:SetWidth(16)
				else
					m_btn.favtexture:SetTexture(0,0,0,0)
				end				
				
				-- set summoned color
				if isSummoned then
					fs:SetTextColor(.9, .7, .2 ,1)
					m_btn.usetexture:SetTexture(0,0,0,0)
				end
				
				-- set useable texture
				if not isUsable then
					fs:SetTextColor(1,0,0,.7)
					m_btn.usetexture:SetTexture(0,0,0,.7)
				end
			end
		end
	end
end

---------------------------
-- apply mount list filters
---------------------------
function gf.Mounts.applyFilters(text)
	Glance.Debug("function","applyFilters","Mounts")
	-- not built yet, go away
	if gfrm.mountFrame == nil then return end
	local previousFrame = gfrm.mountListFrame
	for i=1, C_MountJournal.GetNumMounts() do
		local cName, cSpellID, cIcon, isSummoned, isUsable, sourceType, isFavorite, isFactionSpecific, faction, hideOnChar, isCollected = C_MountJournal.GetMountInfoByID(i)
		local cDisplayID, cDescription, cSource, isSelfMount, mountFlags = C_MountJournal.GetMountInfoExtraByID(i)
		
		if cSpellID then
		-- link to the proper objects
		local m_btn = _G["Glance_Mount_Buttons_"..cSpellID]
			if m_btn ~= nil then
				-- hide all to start
				m_btn:Hide();
				
				-- search box
				if text ~= nil and text ~= "" then 
					if string.find(strlower(cName), strlower(text)) then		
						m_btn:Show();
					end
				-- or other filters
				else
					------------------------
					-- if show ground mounts
					if (spa.showGround and (mountFlags == 230 or mountFlags == 231)) then			
						m_btn:Show();
					end
					-- if show flying mounts
					if (spa.showFlying and (mountFlags == 242 or mountFlags == 248)) then			
						m_btn:Show();
					end
					-- if show underwater mounts
					if (spa.showUnderwater and (mountFlags == 231 or mountFlags == 232 or mountFlags == 254)) then			
						m_btn:Show();
					end
					------------------------
					-- if show overwater mounts
					if (spa.showGround and spa.showOverwater and (mountFlags == 269)) then			
						m_btn:Show();
					end
					-- if show Chauffeured mounts
					if (spa.showGround and  spa.showChauffeured and (mountFlags == 284)) then			
						m_btn:Show();
					end
					-- if show Zone Locked mounts
					if (spa.showZoneLocked and ((spa.showUnderwater and mountFlags == 232) or (spa.showGround and mountFlags == 241))) then			
						m_btn:Show();
					end
					-- if show no swimming mounts
					if (spa.showFlying and spa.showNoSwimming and (mountFlags == 247)) then			
						m_btn:Show();
					end	
					-- if show favorites checked
					if (spa.showFavorites) then	
						-- hide if not favorite and shown
						if not isFavorite and m_btn:IsShown() then
							m_btn:Hide();
						end						
					end
				end
				
				-- REPOSITION EVERYTHING IF VISIBLE
				if m_btn:IsShown() then
					-- position it
					if previousFrame == gfrm.mountListFrame then
						m_btn:SetPoint("TOPLEFT", gfrm.mountListFrame, "TOPLEFT", 5, -5)
					else
						m_btn:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -5)
					end			
					--make this frame the previous frame
					previousFrame = _G["Glance_Mount_Buttons_"..cSpellID]	
				end
			end
		end
	end
end

---------------------------
-- build all
---------------------------
function gf.Mounts.build()
	Glance.Debug("function","build","Mounts")
	gf.Mounts.buildFrames()
	gf.Mounts.buildButtons()
	gf.Mounts.checkForUpdates()
	gf.Mounts.applyFilters();
end

---------------------------
-- build frames
---------------------------
function gf.Mounts.buildFrames()
	Glance.Debug("function","buildFrames","Mounts")
	if gfrm.mountFrame == nil then
		-- create main container
		gfrm.mountFrame = CreateFrame("FRAME", "Glance_mountFrame", Glance_Buttons_Mounts, "TooltipBorderedFrameTemplate")
		gfrm.mountFrame:SetPoint("TOPRIGHT", Glance_Buttons_Mounts, "BOTTOMRIGHT", 0, 0)	
		gfrm.mountFrame:SetWidth(350)
		gfrm.mountFrame:SetHeight(mountHeight)
		gfrm.mountFrame:SetAlpha(.9)
		gfrm.mountFrame:SetFrameStrata("High")
		gfrm.mountFrame:Hide()
		--gfrm.mountFrame:SetScript("OnLeave", function(self, button, down) gfrm.mountFrame:Hide() end)

		-- create list mountScrollFrame
		gfrm.mountScrollFrame = CreateFrame("ScrollFrame", "Glance_mountScrollFrame", gfrm.mountFrame, "UIPanelScrollFrameTemplate")
		gfrm.mountScrollFrame:SetPoint("TOPLEFT", gfrm.mountFrame, "TOPLEFT", 10, -40)	
		gfrm.mountScrollFrame:SetWidth(gfrm.mountFrame:GetWidth()-40)
		gfrm.mountScrollFrame:SetHeight(gfrm.mountFrame:GetHeight()-51)
		gfrm.mountScrollFrame:Show()

		-- create list frame
		gfrm.mountListFrame = CreateFrame("FRAME", "Glance_mountListFrame", gfrm.mountScrollFrame)
		gfrm.mountListFrame:SetPoint("TOPLEFT", gfrm.mountScrollFrame, "TOPLEFT", 0, 0)	
		gfrm.mountListFrame:SetWidth(gfrm.mountScrollFrame:GetWidth())
		gfrm.mountListFrame:SetHeight(gfrm.mountScrollFrame:GetHeight())
		gfrm.mountListFrame:Show()	

		-- bind the list to the mountScrollFrame
		gfrm.mountScrollFrame:SetScrollChild(gfrm.mountListFrame)
		
		-- create the filter by type button
		gfrm.mountFrameFilterMenu = CreateFrame("Frame", "Glance_mountFrameFilterMenu", nil, "UIDropDownMenuTemplate")
		gfrm.mountFrameFilter = CreateFrame("BUTTON", "Glance_mountFrameFilter", gfrm.mountFrame, "UIMenuButtonStretchTemplate")
		gfrm.mountFrameFilter:SetPoint("TOPLEFT", gfrm.mountFrame, "TOPLEFT", 10, -10)	
		gfrm.mountFrameFilter:SetWidth(150)
		gfrm.mountFrameFilter:SetHeight(30)
		gfrm.mountFrameFilter:Show()				
		-- create the icon overlay
		gfrm.mountFrameFilter.arrowtexture = gfrm.mountFrameFilter:CreateTexture("Glance_Mount_Filter_Icon", "OVERLAY")
		gfrm.mountFrameFilter.arrowtexture:SetTexture(btn.texture.filter)
		gfrm.mountFrameFilter.arrowtexture:SetPoint("RIGHT",-5,0)
		gfrm.mountFrameFilter.arrowtexture:SetWidth(12)
		gfrm.mountFrameFilter.arrowtexture:SetHeight(10)
		-- create the font
		local fs = gfrm.mountFrameFilter:CreateFontString("Glance_mountFrameFilter_FontString")
		fs:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+7)
		fs:SetJustifyH("LEFT")
		fs:SetJustifyV("CENTER")
		fs:SetPoint("LEFT", 10, 0)
		fs:SetTextColor(.9, .7, .2,1)					
		-- create the text
		gfrm.mountFrameFilter:SetFontString(fs)
		gfrm.mountFrameFilter:SetText("Filters")
		-- reset the width to actual width
		gfrm.mountFrameFilter:SetWidth(fs:GetStringWidth()+30)
		gfrm.mountFrameFilter:SetHeight(fs:GetStringHeight()+10)
		-- register for clicks
		gfrm.mountFrameFilter:RegisterForClicks("AnyUp")					
		-- mouse events
		gfrm.mountFrameFilter:SetScript("OnClick", function(self, button, down) gf.Mounts.EasyMenu() end)
		
		-- create the search box
		gfrm.mountFrameSearch = CreateFrame("EDITBOX", "Glance_mountFrameSearch", gfrm.mountFrameFilter, "SearchBoxTemplate")
		gfrm.mountFrameSearch:SetPoint("TOPLEFT", gfrm.mountFrameFilter, "TOPRIGHT", 10, 5)	
		gfrm.mountFrameSearch:SetWidth(100)
		gfrm.mountFrameSearch:SetHeight(30)
		gfrm.mountFrameSearch:SetScript("OnTextChanged", function(self, userInput) SearchBoxTemplate_OnTextChanged(self); gf.Mounts.applyFilters(gfrm.mountFrameSearch:GetText()) end)
		
		-- create the close button
		gfrm.mountFrameClose = CreateFrame("BUTTON", "Glance_mountFrameClose", gfrm.mountFrame, "UIPanelCloseButton")
		gfrm.mountFrameClose:SetPoint("TOPRIGHT", gfrm.mountFrame, "TOPRIGHT", -5, -6)	
		gfrm.mountFrameClose:SetWidth(30)
		gfrm.mountFrameClose:SetHeight(30)
				
		-- create main model data container
		gfrm.mountDataFrame = CreateFrame("FRAME", "Glance_mountDataFrame", gfrm.mountFrame, "TooltipBorderedFrameTemplate")
		gfrm.mountDataFrame:SetPoint("TOPRIGHT", gfrm.mountFrame, "TOPLEFT", 0, 0)	
		gfrm.mountDataFrame:SetWidth(modelWidth)
		gfrm.mountDataFrame:SetHeight(mountHeight)
		gfrm.mountDataFrame:Hide()
		
		-- create model frame
		gfrm.mountModelFrame = CreateFrame("PlayerModel","Glance_mountModelFrame",gfrm.mountFrame)
		gfrm.mountModelFrame:SetPoint("TOP",gfrm.mountDataFrame,"TOP",0,-15)
		gfrm.mountModelFrame:SetHeight(modelWidth-40)
		gfrm.mountModelFrame:SetWidth(modelWidth-10)
		gfrm.mountModelFrame:SetPosition(0,0,0)
		gfrm.mountFrame:SetAlpha(1)
		gfrm.mountModelFrame:Hide()
		-- rotate the critter smoothly..
		gfrm.mountModelFrame:SetScript("OnUpdate", function(self, elapsed) 
			seqtime = seqtime + elapsed; 
			if seqtime >= .01 then
				seqtime = 0
				position = position + .01
				if position <= 6.2 then
					gfrm.mountModelFrame:SetFacing(position);
				else
					position = 0
					gfrm.mountModelFrame:SetFacing(position);
				end
			end
		end)
		-- create the title
		local title = gfrm.mountDataFrame:CreateFontString("Glance_Mount_Model_Title")
		title:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+8)
		title:SetJustifyH("CENTER")
		title:SetJustifyV("CENTER")
		title:SetWordWrap(true)
		title:SetPoint("TOPLEFT", gfrm.mountDataFrame, "TOPLEFT", 0, -10)
		title:SetTextColor(.9, .7, .2 ,1)
		title:SetHeight(20)
		title:SetWidth(modelWidth)
		-- create the description
		local description = gfrm.mountModelFrame:CreateFontString("Glance_Mount_Model_Description")
		description:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+6)
		description:SetJustifyH("LEFT")
		description:SetJustifyV("TOP")
		description:SetPoint("TOPLEFT", gfrm.mountModelFrame, "BOTTOMLEFT", 5, 0)
		description:SetTextColor(1, 1, 1 ,1)
		description:SetWidth(modelWidth-15)
		-- create the notes
		local notes = gfrm.mountDataFrame:CreateFontString("Glance_Mount_Model_Notes")
		notes:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+6)
		notes:SetJustifyH("LEFT")
		notes:SetJustifyV("BOTTOM")
		notes:SetPoint("BOTTOMLEFT", gfrm.mountDataFrame, "BOTTOMLEFT", 10, 10)
		notes:SetTextColor(1, .46, 0 ,1)
		notes:SetWidth(modelWidth)
		notes:SetText("Left-Click to summon.\nRight-Click to set favorite.")
	end
end

---------------------------
-- build buttons
---------------------------
function gf.Mounts.buildButtons()
	Glance.Debug("function","buildButtons","Mounts")
	-- variables
	local pFaction = 0
	if UnitFactionGroup("player") == "Alliance" then pFaction=1 end
	local previousFrame = gfrm.mountListFrame
	local widest = 0
	
	-- iterate mounts
	for i=1, C_MountJournal.GetNumMounts() do
		local cName, cSpellID, cIcon, isSummoned, isUsable, sourceType, isFavorite, isFactionSpecific, faction, hideOnChar, isCollected = C_MountJournal.GetMountInfoByID(i)
		local cDisplayID, cDescription, cSource, isSelfMount, mountFlags = C_MountJournal.GetMountInfoExtraByID(i)		
		if IsIndoors() then isUsable = false end
		
		-- if you have it, and it's the right faction
		if (isCollected and not hideOnChar) then
			-- some incorrect faction models make it this far
			if (isFactionSpecific and faction == pFaction) or not isFactionSpecific then
				-- if we have not yet created this button.
				if _G["Glance_Mount_Buttons_"..cSpellID] == nil then
				
					-- create the frame
					local m_btn = CreateFrame("BUTTON", "Glance_Mount_Buttons_"..cSpellID, gfrm.mountListFrame)
					m_btn:SetHeight(iconSize)
					m_btn:SetWidth(250)
					
					-- create the font
					local fs = m_btn:CreateFontString("Glance_Mount_Buttons_FontString_"..cSpellID)
					fs:SetFont(ga.Font[3][2], Glance_Local.Options.fontSize+7)
					fs:SetJustifyH("LEFT")
					fs:SetJustifyV("CENTER")
					fs:SetPoint("TOPLEFT", 0, 0)
					fs:SetTextColor(1,1,1,1)
					
					-- create the icon overlay
					m_btn.usetexture = m_btn:CreateTexture("Glance_Mount_Buttons_UTexture_"..cSpellID, "OVERLAY")
					m_btn.usetexture:SetTexture(0,0,0,0)
					m_btn.usetexture:SetPoint("TOPLEFT",0,0)
					m_btn.usetexture:SetWidth(iconSize)
					m_btn.usetexture:SetHeight(iconSize)
					
					-- set favorite icon
					m_btn.favtexture = m_btn:CreateTexture("Glance_Mount_Buttons_FTexture_"..cSpellID, "OVERLAY")
					m_btn.favtexture:SetTexture(0,0,0,0)
					m_btn.favtexture:SetPoint("TOPLEFT",-5,5)
					m_btn.favtexture:SetWidth(16)
					
					-- create the text
					m_btn:SetFontString(fs)
					local bName = cName
					if string.len(bName) > 20 then
						bName = string.sub(bName,1,20).."..."
					end
					m_btn:SetText("|T"..cIcon..":"..iconSize.."|t "..bName)
					
					-- position it
					if previousFrame == gfrm.mountListFrame then
						m_btn:SetPoint("TOPLEFT", gfrm.mountListFrame, "TOPLEFT", 5, -5)
					else
						m_btn:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -5)
					end
					
					--make this frame the previous frame
					previousFrame = _G["Glance_Mount_Buttons_"..cSpellID]	
					
					-- reset the width to actual width
					m_btn:SetWidth(fs:GetStringWidth())
					if m_btn:GetWidth() > widest then widest = m_btn:GetWidth() end		
					
					-- register for clicks
					m_btn:RegisterForClicks("AnyUp")					
					-- mouse events
					m_btn:SetScript("OnEnter", function(self, button, down) gf.Mounts.mouseOver(i, cSpellID, cDisplayID, cName, cDescription.."\n\n"..cSource.."\n\n"..HEX.gold..tostring(ga.mountFlags[mountFlags])) end)
					m_btn:SetScript("OnLeave", function(self, button, down) gf.Mounts.mouseOut(i, cSpellID) end)
					m_btn:SetScript("OnClick", function(self, button, down) gf.Mounts.mouseClick(i, button) end)
					
					-- turn it on
					m_btn:Show()
				end
			end
		end
	end
	-- reset the width to the largest button width.. only once please
	if firstRun then
		gfrm.mountFrame:SetWidth(widest+50)
		gfrm.mountScrollFrame:SetWidth(gfrm.mountFrame:GetWidth()-40)
		gfrm.mountListFrame:SetWidth(gfrm.mountScrollFrame:GetWidth())		
		gfrm.mountFrameSearch:SetWidth(gfrm.mountFrame:GetWidth()-gfrm.mountFrameFilter:GetWidth()-gfrm.mountFrameClose:GetWidth()-25)
		firstRun = false
	end
end

---------------------------
-- load on demand
---------------------------
if gv.loaded then
	gf.Enable("Mounts")
end