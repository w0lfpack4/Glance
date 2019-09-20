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
gf.AddButton("DualSpec","RIGHT")
local btn = gb.DualSpec
btn.text              = "     "
btn.enabled           = true
btn.texture.normal    = "Interface\\AddOns\\Glance_DualSpec\\die2.tga"
btn.events            = {"CHARACTER_POINTS_CHANGED","PLAYER_TALENT_UPDATE","WEAR_EQUIPMENT_SET","EQUIPMENT_SETS_CHANGED"}
btn.update            = true
btn.tooltip           = true
btn.click             = true
btn.menu              = true
btn.timer5            = true

---------------------------
-- not available till lvl 30
---------------------------
if UnitLevel("player") < 30 then btn.enabled = false end

---------------------------
-- shortcuts
---------------------------
local HEX = ga.colors.HEX
local tooltip = gf.Tooltip

---------------------------
-- update
---------------------------
function gf.DualSpec.update(self, event, arg1)
	local btn = gb.DualSpec
	if btn.enabled and gv.loaded then -- loaded keeps it from launching when defined
		Glance.Debug("function","update","DualSpec")
		local spec = GetActiveSpecGroup();
		local hasStance = false
		for i=1,GetNumShapeshiftForms() do
			local icon, name, checked, isCastable = GetShapeshiftFormInfo(i)
			if (checked) then hasStance = true; end
		end
		if (spec == 1) then
			if not hasStance then
				btn.button:SetNormalTexture("Interface\\AddOns\\Glance_DualSpec\\die1red.tga")
			else
				btn.button:SetNormalTexture("Interface\\AddOns\\Glance_DualSpec\\die1.tga")
			end
		else
			if not hasStance then
				btn.button:SetNormalTexture("Interface\\AddOns\\Glance_DualSpec\\die2red.tga")
			else
				btn.button:SetNormalTexture("Interface\\AddOns\\Glance_DualSpec\\die2.tga")
			end
		end
	end
end

---------------------------
-- tooltip
---------------------------
function gf.DualSpec.tooltip()
	Glance.Debug("function","tooltip","DualSpec")
	gf.DualSpec.update()
	tooltip.Title("DualSpec", "GLD")
	tooltip.Double("Talent Tree: ", gf.DualSpec.getSpec()..": "..gf.DualSpec.getBuild(GetActiveSpecGroup()), "WHT","GRN")
	for i=1,GetNumEquipmentSets() do
		local name,icon,_,checked = GetEquipmentSetInfo(i);
		if (checked) then tooltip.Double("Equipment Set:", name, "WHT", "GRN") end
	end
	local hasStance = false
	for i=1,GetNumShapeshiftForms() do
		local icon, name, checked, isCastable = GetShapeshiftFormInfo(i)
		if (checked) then tooltip.Double("Stance/Aura:", name, "WHT", "GRN"); hasStance = true; end
	end
	if not hasStance then
		tooltip.Double("Stance/Aura:", "NONE SELECTED", "WHT", "RED");
	end
	local tabid = GetInventoryItemID("player", GetInventorySlotInfo("TabardSlot"))
	local tabname = "none"
	local tabquality = 0
	if type(tonumber(tabid)) == "number" then
		if tonumber(tabid) > 0 then
			tabname,_,tabquality = GetItemInfo(tabid)
		end
	end
	local r, g, b, hex = GetItemQualityColor(tabquality)
	tooltip.Double("Tabard:", "|c"..hex..tabname, "WHT", "RED")
	tooltip.Notes("switch specs",nil,"switch gear sets",nil,"Items in the stance/presence/aura bar may be shown but not activated by Glance")
end

---------------------------
-- menu
---------------------------
function gf.DualSpec.menu(level,UIDROPDOWNMENU_MENU_VALUE)
	Glance.Debug("function","menu","DualSpec")
	level = level or 1
	if (level == 1) then
		-- talent tree
		gf.setMenuTitle("DualSpec: Talent Tree")		
		gf.setMenuOption(gf.DualSpec.getSpecCheck(1),HEX.green.."P: "..HEX.gold..gf.DualSpec.getBuild(1),"spec1",level,function() gf.DualSpec.setSpec() end)
		gf.setMenuOption(gf.DualSpec.getSpecCheck(2),HEX.red.."S: "..HEX.gold..gf.DualSpec.getBuild(2),"spec2",level,function() gf.DualSpec.setSpec() end)
		
		-- equipment sets
		gf.setMenuTitle(" ")
		gf.setMenuTitle("DualSpec: Equipment Sets")		
		for i=1,GetNumEquipmentSets() do
			local name,icon,_,checked = GetEquipmentSetInfo(i);
			func = function() UseEquipmentSet(name); gf.sendMSG("You have switched to your |cffff0000"..name.."|r Equipment Set") end;
			gf.setMenuOption(checked,HEX.gold..name,"name",level,func,icon)
		end
		
		-- stance
		gf.setMenuTitle(" ")
		gf.setMenuTitle("DualSpec: Stance")		
		for i=1,GetNumShapeshiftForms() do
			local icon, name, checked, isCastable = GetShapeshiftFormInfo(i)
			gf.setDisabledMenuOption(checked,HEX.gold..name,"name",level,nil,icon)
		end
	end
end

---------------------------
-- messaging
---------------------------
function gf.DualSpec.click(self, button, down)
	Glance.Debug("function","click","DualSpec")
	if button == "LeftButton" then
		gf.DualSpec.setSpec()
		gf.DualSpec.update()
	end
end

---------------------------
-- get talent build
---------------------------
function gf.DualSpec.getBuild(spec)
	local index = GetSpecialization(false,false,spec);
	if ( index ~= nil ) then
		local _,currentSpecName,_ = GetSpecializationInfo(index);
		return currentSpecName;
	else 
		return "";
	end
end

---------------------------
-- get spec
---------------------------
function gf.DualSpec.getSpec()
	local spec = GetActiveSpecGroup();
	if (spec == 1) then
		return "|cff00ff00Primary|r";
	else
		return "|cffff0000Secondary|r";
	end
end
function gf.DualSpec.getSpecCheck(which)
	local spec = GetActiveSpecGroup();
	if (spec == which) then
		return true
	else
		return false
	end
end

---------------------------
-- set spec
---------------------------
function gf.DualSpec.setSpec()
	local spec = GetActiveSpecGroup();
	if (spec == 1) then
		SetActiveSpecGroup(2)
		btn.button:SetNormalTexture("Interface\\AddOns\\Glance_DualSpec\\die2.tga")
		gf.sendMSG("You have switched to your |cffff0000Secondary|r spec. "..gf.DualSpec.getBuild(2))
	else
		SetActiveSpecGroup(1)
		btn.button:SetNormalTexture("Interface\\AddOns\\Glance_DualSpec\\die1.tga")
		gf.sendMSG("You have switched to your |cff00ff00Primary|r spec. "..gf.DualSpec.getBuild(1))
	end
end

---------------------------
-- load on demand
---------------------------
if gv.loaded then
	gf.Enable("DualSpec")
end