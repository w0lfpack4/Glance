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
gf.AddButton("Titles","RIGHT")
local btn = gb.Titles
btn.text              = "     "
btn.enabled           = true
btn.texture.normal    = "Interface\\AddOns\\Glance_Titles\\title.tga"
btn.update            = true
btn.tooltip           = true
btn.menu              = true
btn.events            = {"PLAYER_TITLE_ID_CHANGED"}

---------------------------
-- shortcuts
---------------------------
local HEX = ga.colors.HEX
local CLS = ga.colors.CLASS
local tooltip = gf.Tooltip

---------------------------
-- best. title. ever.
---------------------------
--<Name>, Slayer of Stupid, Incompetent and Disappointing Minions

---------------------------
-- update
---------------------------
function gf.Titles.update()
	if btn.enabled and gv.loaded then -- loaded keeps it from launching when defined
		btn.button:SetWidth(gv.displayIcon)
	end
end

---------------------------
-- tooltip
---------------------------
function gf.Titles.tooltip()
	Glance.Debug("function","tooltip","Titles")
	tooltip.Title("Titles","GLD")
	local count, total = 0, 0
	for i=1,GetNumTitles() do
		if IsTitleKnown(i) then 
			if GetTitleName(i) ~= nil then	
				count = count + 1
			end
		end
		total = total + 1
	end
	tooltip.Line(gf.Titles.formatTitle(GetCurrentTitle()),"WHT")
	tooltip.Line("You have earned "..HEX.green..count.."|r of "..HEX.red..total.." |rpossible titles.","WHT")
	--(left,shift-left,right,shift-right,other)
	tooltip.Notes(nil,nil,"change titles",nil,nil)
end

---------------------------
-- menu
---------------------------
function gf.Titles.menu(level,UIDROPDOWNMENU_MENU_VALUE)
	Glance.Debug("function","menu","Titles")
	level = level or 1
	if (level == 1) then
		gf.setMenuTitle("Available Titles",level,true)
		for i=1,GetNumTitles() do
			if IsTitleKnown(i) then 
				if GetTitleName(i) ~= nil then	
					gf.setMenuOption(i==GetCurrentTitle(),gf.Titles.formatTitle(i),"title",level,function() gf.Titles.setTitle(i) end)
				end
			end
		end
	end
end

---------------------------
-- set title
---------------------------
function gf.Titles.setTitle(id)
	SetCurrentTitle(id)
	gf.sendMSG("Your title has been set to: "..gf.Titles.formatTitle(id))
end

---------------------------
-- format title
---------------------------
function gf.Titles.formatTitle(id)
	local titlename, title, player, class = GetTitleName(id), "", UnitName("player"), UnitClass("player"):upper()
	player = CLS[class]..player
	if not titlename then return player.." |rof no title" end
	if titlename:sub(1, 1) == " " then
		if titlename:find("Jenkins") == nil and titlename:sub(2, 3) ~= "of" and titlename:sub(2, 4) ~= "the" then
			title = player.."|r,"..titlename
		else			
			title = player.."|r"..titlename
		end
	else
		title = titlename..player
	end
	return title
end

---------------------------
-- load on demand
---------------------------
if gv.loaded then
	gf.Enable("Titles")
end
