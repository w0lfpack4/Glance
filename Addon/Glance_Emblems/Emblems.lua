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
gf.AddButton("Emblems","LEFT")
local btn = gb.Emblems
btn.text              = "Emblems"
btn.enabled           = true
btn.events            = {"CURRENCY_DISPLAY_UPDATE","LFG_COMPLETION_REWARD", "PLAYER_MONEY"}
btn.update            = true
btn.tooltip           = true
btn.click             = true
btn.timer5            = true
btn.menu              = true
btn.save.perCharacter = {["DisplayEmblems"] = {}, ["Title"] = "Icon"}
btn.save.allowProfile = true

---------------------------
-- shortcuts
---------------------------
local spc = btn.save.perCharacter
local HEX = ga.colors.HEX
local tooltip = gf.Tooltip

---------------------------
-- locals
---------------------------
ga.caps = {
	["Valor Points"] = 396,
	["Justice Points"] = 395,
	["Honor Points"] = 392,
	["Conquest Points"] = 390,
}

---------------------------
-- update
---------------------------
function gf.Emblems.update()
	if btn.enabled and gv.loaded then -- loaded keeps it from launching when defined
		Glance.Debug("function","update","Emblems")
		local hasEmblems = false
		local BT,TMP = HEX.red.."Emblems",""
		for i=1, C_CurrencyInfo.GetCurrencyListSize() do
			local data = C_CurrencyInfo.GetCurrencyListInfo(i)
			--local name, isHeader, isExpanded, isUnused, isWatched, count, icon, itemID, extraCurrencyType = C_CurrencyInfo.GetCurrencyListInfo(i)
			if spc.DisplayEmblems[data.name] then
				if TMP ~= "" then TMP = TMP.."    |r" end
				local tip, cap = unpack(gf.Emblems.tipColors(data.name, data.quantity, true))
				TMP = TMP..gf.Emblems.getTitle(data.name,data.iconFileID)..cap..data.quantity				
				hasEmblems = true
			end
			if spc.DisplayEmblems["Weekly "..data.name] then
				if data.name == "Valor Points" or data.name == "Conquest Points" then
					if TMP ~= "" then TMP = TMP.."    |r" end
					local cap = HEX.green
					local earned, weekly, total = unpack(gf.Emblems.getCap(data.name))
					if earned == weekly then cap = HEX.red end
					TMP = TMP..gf.Emblems.getTitle(data.name,data.iconFileID,true)..cap..earned.."/"..weekly
				end
				hasEmblems = true
			end
		end
		if hasEmblems then
			BT = TMP
		end
		btn.button:SetText(BT)
		btn.button:SetWidth(btn.button:GetTextWidth())
	end
end

---------------------------
-- tooltip
---------------------------
function gf.Emblems.tooltip()
	Glance.Debug("function","tooltip","Emblems")
	local hasEmblems = false
	tooltip.Title("Emblems","GLD")
	for i=1, C_CurrencyInfo.GetCurrencyListSize() do
		local data = C_CurrencyInfo.GetCurrencyListInfo(i)
		--local name, isHeader, isExpanded, isUnused, isWatched, count, icon, itemID, extraCurrencyType = C_CurrencyInfo.GetCurrencyListInfo(i)
		if isHeader then
			tooltip.Space()
			tooltip.Line(name,"GLD")
		else
			local tip, cap = unpack(gf.Emblems.tipColors(data.name, data.quantity))
			tooltip.Double(gf.is(data.iconFileID,"tooltip")..data.name,data.quantity,tip,cap)
			if data.name == "Valor Points" or data.name == "Conquest Points" then
				local earned, weekly, total = unpack(gf.Emblems.getCap(data.name))
				local namecolor,capcolor = "WHT", "GRN"
				if earned == weekly then capcolor = "RED" end
				if spc.DisplayEmblems["Weekly "..data.name] then namecolor = "LBL" end
				tooltip.Double(gf.is(data.iconFileID,"tooltip").."Weekly "..data.name,earned.."/"..weekly,namecolor,capcolor)
			end
			hasEmblems = true
		end
	end
	if not hasEmblems then
		tooltip.Line("|rYou have no emblems","WHT")
	end
	local tbl = {
		[1] = {["Title"]=spc.Title},
	}
	tooltip.Options(tbl)
	--(left,shift-left,right,shift-right,other)
	tooltip.Notes("open the Currency tab",nil,"change Emblem tracking",nil,nil)
end

---------------------------
-- click
---------------------------
function gf.Emblems.click(self, button, down)
	Glance.Debug("function","click","Emblems")
	if button == "LeftButton" then
		ToggleCharacter("TokenFrame")
	end
end

---------------------------
-- menu
---------------------------
function gf.Emblems.menu(level,UIDROPDOWNMENU_MENU_VALUE)
	Glance.Debug("function","menu","Emblems")
	local HEX = ga.colors.HEX
	level = level or 1
	if (level == 1) then
		gf.setMenuTitle("Emblems Options")
		gf.setMenuHeader("Title","title",level)
		gf.setMenuHeader("Tracking","tracking",level)
	end
	if (level == 2) then
		if gf.isMenuValue("title") then	
			--checked,text,value,level,func,icon,keepShown,notRadio
			gf.setMenuOption(spc.Title == "Text","Text","Text",level,function() spc.Title = "Text"; gf.Emblems.update() end)
			gf.setMenuOption(spc.Title == "Icon","Icon","Icon",level,function() spc.Title = "Icon"; gf.Emblems.update() end)
		end
		if gf.isMenuValue("tracking") then	
			for i=1, C_CurrencyInfo.GetCurrencyListSize() do
				local data = C_CurrencyInfo.GetCurrencyListInfo(i)
				--local name, isHeader, isExpanded, isUnused, isWatched, count, icon, itemID, extraCurrencyType = C_CurrencyInfo.GetCurrencyListInfo(i)
				if data.isHeader then
					gf.setMenuTitle(data.name,level,true)
				else
					gf.setMenuOption(spc.DisplayEmblems[data.name]==true,data.name,data.name,level,function() if spc.DisplayEmblems[data.name] then spc.DisplayEmblems[data.name]=false else spc.DisplayEmblems[name]=true end; gf.Emblems.update() end,data.iconFileID)
					if name == "Valor Points" or name == "Conquest Points" then
						gf.setMenuOption(spc.DisplayEmblems["Weekly "..data.name]==true,"Weekly "..data.name,"Weekly "..data.name,level,function() if spc.DisplayEmblems["Weekly "..data.name] then spc.DisplayEmblems["Weekly "..data.name]=false else spc.DisplayEmblems["Weekly "..data.name]=true end; gf.Emblems.update() end,data.iconFileID)		
					end
				end
			end
		end
	end
end

---------------------------
-- get weekly caps
---------------------------
function gf.Emblems.getCap(coin)
	if ga.caps[coin] ~= nil then
		local name, amount, texturePath, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo(ga.caps[coin])
		if coin == "Valor Points" then 
			weeklyMax = floor(weeklyMax/100)
		end
		return {earnedThisWeek, weeklyMax, floor(totalMax/100)}
	else
		return {0,0,0}
	end
end

---------------------------
-- get tooltip colors
---------------------------
function gf.Emblems.tipColors(name, count, display)
	local capcolor, tipcolor = "GRN", "WHT"
	if display then capcolor = HEX.green end
	-- no count or capped
	if count == 0 or (count == select(3,unpack(gf.Emblems.getCap(ga.caps[name])))) then		
		if display then capcolor = HEX.red else capcolor = "RED" end
	end
	-- favorite
	if spc.DisplayEmblems[name] then
		tipcolor = "LBL"
	end
	return {tipcolor, capcolor}
end

---------------------------
-- get display title
---------------------------
function gf.Emblems.getTitle(name,icon,weekly)
	local ARR, TMP = { strsplit(" ", name) }, ""
	for i=1, #ARR do
		TMP = TMP..string.sub(ARR[i], 1, 1)
	end
	if weekly then TMP = "W"..TMP end
	TMP = TMP..": "
	if spc.Title == "Icon" then 
		TMP = gf.is(icon,"display")
	end
	return TMP
end

---------------------------
-- load on demand
---------------------------
if gv.loaded then
	gf.Enable("Emblems")
end