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
gf.AddButton("DevTools","RIGHT")
local btn = gb.DevTools
btn.text              = "      "
btn.texture.normal    = "Interface\\AddOns\\Glance_DevTools\\devtools.tga"
btn.events            = {}
btn.enabled           = true
btn.click             = true
btn.menu              = true
btn.tooltip           = true
btn.save.perCharacter = {["showHidden"] = false}

---------------------------
-- shortcuts
---------------------------
local spc = btn.save.perCharacter
local HEX = ga.colors.HEX
local tooltip = gf.Tooltip
local DT = DevTools;

---------------------------
-- commands
---------------------------
gf.AddCommand("DevTools","framestack","Show or hide the DevTools FrameStack",function() DT:FrameStack_Toggle() end)

---------------------------
-- click
---------------------------
function gf.DevTools.click(self, button, down)
	Glance.Debug("function","click","DevTools")
	if (button == "LeftButton") then 
		DT:FrameStack_Toggle()
	end
end

---------------------------
-- tooltip
---------------------------
function gf.DevTools.tooltip()
	Glance.Debug("function","tooltip","DevTools")
	tooltip.Title("DevTools","GLD")
	tooltip.Wrap("A frame stack tracing tool by Daniel Stephens/Iriel, now ported to Glance.","WHT")
	local tbl = {
		[1] = {["Show Hidden Frames"]=spc.showHidden},
	}
	tooltip.Options(tbl)
	--(left,shift-left,right,shift-right,other)
	tooltip.Notes("show or hide the DevTools FrameStack",nil,"change Options",nil,nil)
end

---------------------------
-- menu
---------------------------
function gf.DevTools.menu(level,UIDROPDOWNMENU_MENU_VALUE)
	Glance.Debug("function","menu","DevTools")
	level = level or 1
	if (level == 1) then
		gf.setMenuTitle("DevTools Options")
		gf.setMenuHeader("Show Hidden Frames","hidden",level)
	end
	if (level == 2) then
		if gf.isMenuValue("hidden") then
			gf.setMenuOption(spc.showHidden==true,"On","On",level,function() spc.showHidden=true; end)
			gf.setMenuOption(spc.showHidden==false,"Off","Off",level,function() spc.showHidden=false; end)
		end
	end
end

---------------------------
-- load on demand
---------------------------
if gv.loaded then
	gf.Enable("DevTools")
	--DT:FrameStack_Toggle()
end

