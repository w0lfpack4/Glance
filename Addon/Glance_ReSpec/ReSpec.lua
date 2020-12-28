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
gf.AddButton("ReSpec","RIGHT")
local btn = gb.ReSpec
btn.text              = "     "
btn.enabled           = true
btn.texture.normal    = "Interface\\AddOns\\Glance_ReSpec\\die2.tga"
btn.events            = {"CHARACTER_POINTS_CHANGED","PLAYER_TALENT_UPDATE","WEAR_EQUIPMENT_SET","EQUIPMENT_SETS_CHANGED"}
btn.update            = true
btn.tooltip           = true
btn.click             = true
btn.menu              = true
btn.timer5            = true

---------------------------
-- shortcuts
---------------------------
local HEX = ga.colors.HEX
local tooltip = gf.Tooltip

---------------------------
-- tables
---------------------------
ga.SPEC_STAT_STRINGS = {
	[LE_UNIT_STAT_STRENGTH] = SPEC_FRAME_PRIMARY_STAT_STRENGTH,
	[LE_UNIT_STAT_AGILITY] = SPEC_FRAME_PRIMARY_STAT_AGILITY,
	[LE_UNIT_STAT_INTELLECT] = SPEC_FRAME_PRIMARY_STAT_INTELLECT,
};

ga.Stances = {
	[1] = "Cat Form",
	[2] = "Tree of Life",
	[3] = "Travel Form",
	[4] = "Aquatic Form",
	[5] = "Bear Form",
	[16] = "Ghost Wolf",
	[17] = "Battle Stance",
	[18] = "Defensive Stance",
	[19] = "Berserker Stance",
	[20] = "Stance of the Wise Serpent",
	[22] = "Metamorphosis",
	[23] = "Stance of the Sturdy Ox",
	[24] = "Stance of the Fierce Tiger",
	[27] = "Swift Flight Form",
	[29] = "Flight Form",
	[30] = "Stealth",
	[31] = "Moonkin Form",
}

---------------------------
-- update
---------------------------
function gf.ReSpec.update(self, event, arg1)
	local btn = gb.ReSpec
	if btn.enabled and gv.loaded then -- loaded keeps it from launching when defined
		Glance.Debug("function","update","ReSpec")
		local spec = GetSpecialization();
		if spec then
			local icon = select(4,GetSpecializationInfo(spec))
			btn.button:SetNormalTexture(icon)
		else
			btn.button:SetNormalTexture(btn.texture.normal)
		end
	end
end

---------------------------
-- tooltip
---------------------------
function gf.ReSpec.tooltip()
	Glance.Debug("function","tooltip","ReSpec")
	gf.ReSpec.update()
	tooltip.Title("ReSpec", "GLD")
	-- spec
	local spec = GetSpecialization();
	if spec then
		tooltip.Double("Specialization: ", select(2,GetSpecializationInfo(spec)), "WHT","GRN")
		tooltip.Double("Role: ", GetSpecializationRole(spec), "WHT","GRN")
		tooltip.Double("Primary Stat: ", ga.SPEC_STAT_STRINGS[select(6,GetSpecializationInfo(spec))], "WHT","GRN")
	else
		tooltip.Double("Specialization: ", "None", "WHT","RED")
	end
	-- unspent talents
	local unspent = GetNumUnspentTalents()
	if unspent > 0 then
		tooltip.Double("Unspent Talents: ", unspent, "WHT","RED")
	end
	-- equipment set
	local equipmentSetIDs, foundSet = C_EquipmentSet.GetEquipmentSetIDs(), false
	for i=1,#equipmentSetIDs do
		local name,icon,_,checked = C_EquipmentSet.GetEquipmentSetInfo(equipmentSetIDs[i]);
		if (checked) then tooltip.Double("Equipment Set:", name, "WHT", "GRN"); foundSet = true end
	end
	if not foundSet then tooltip.Double("Equipment Set:", "None", "WHT", "RED");  end

	-- stance
	local stance = GetShapeshiftFormID()
	if stance then
		tooltip.Double("Stance/Aura:", ga.Stances[stance], "WHT", "GRN");
	end
	tooltip.Notes("toggle talent frame",nil,"switch spec/gear",nil,"Items in the stance/presence/aura bar may be shown but not activated by Glance")
end

---------------------------
-- menu
---------------------------
function gf.ReSpec.menu(level,UIDROPDOWNMENU_MENU_VALUE)
	Glance.Debug("function","menu","ReSpec")
	level = level or 1
	if (level == 1) then
		-- spec
		gf.setMenuTitle("Switch Specialization")	
		local spec = GetSpecialization() or 0;
		for i=1,GetNumSpecializations() do	
			local id, name, description, icon, background, role, primaryStat = GetSpecializationInfo(i)
			func = function() SetSpecialization(i); gf.sendMSG("You have switched to your spec to |cffff0000"..name); gf.ReSpec.update() end;
			local equipmentSetID = C_EquipmentSet.GetEquipmentSetForSpec(i)
			if equipmentSetID then
				local set = select(1,C_EquipmentSet.GetEquipmentSetInfo(equipmentSetID))
				func = function() 
					SetSpecialization(i); 
					gf.sendMSG("You have switched to your spec to |cffff0000"..name); 
					C_EquipmentSet.UseEquipmentSet(equipmentSetID); 
					gf.sendMSG("You have switched to your equipment set to |cffff0000"..set); 
					gf.ReSpec.update() 
				end;
			end
			gf.setMenuOption(i==spec,HEX.gold..name.." ("..GetSpecializationRole(i)..")","spec",level,func, icon)
		end
		
		-- equipment sets
		local equipmentSetIDs = C_EquipmentSet.GetEquipmentSetIDs()
		if #equipmentSetIDs > 0 then
			gf.setMenuTitle(" ")
			gf.setMenuTitle("Switch Equipment Set")	
		end	
		for i=1,#equipmentSetIDs do
			local name,icon,_,checked = C_EquipmentSet.GetEquipmentSetInfo(equipmentSetIDs[i]);
			local specIndex = C_EquipmentSet.GetEquipmentSetAssignedSpec(equipmentSetIDs[i])
			if specIndex then icon = select(4,GetSpecializationInfo(specIndex))	end
			func = function() 
				C_EquipmentSet.UseEquipmentSet(equipmentSetIDs[i]); 
				gf.sendMSG("You have switched to your equipment set to |cffff0000"..name); 
				gf.ReSpec.update() 
			end;
			gf.setMenuOption(checked,HEX.gold..name,"name",level,func,icon)
		end
	end
end

---------------------------
-- click
---------------------------
function gf.ReSpec.click(self, button, down)
	Glance.Debug("function","click","ReSpec")
	if button == "LeftButton" then
		ToggleTalentFrame()
	end
end

---------------------------
-- load on demand
---------------------------
if gv.loaded then
	gf.Enable("ReSpec")
end