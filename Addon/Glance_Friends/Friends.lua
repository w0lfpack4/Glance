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
gf.AddButton("Friends","LEFT")
local btn = gb.Friends
btn.text		= "Friends"
btn.enabled		= true
btn.events		= {"BN_FRIEND_ACCOUNT_OFFLINE","BN_FRIEND_ACCOUNT_ONLINE","FRIENDLIST_UPDATE"}
btn.update		= true
btn.tooltip		= true
btn.click		= true

---------------------------
-- shortcuts
---------------------------
local HEX = ga.colors.HEX
local CLS = ga.colors.CLASS
local tooltip = gf.Tooltip

---------------------------
-- arrays
---------------------------
ga.Clients = {
	["WoW"] = "WoW",
	["D3"] = "Diablo III",
	["S2"] = "StarCraft II",
	["HS"] = "Hearthstone",
	["WTCG"] = "Hearthstone",	
	["App"] = "Launcher",
}

---------------------------
-- update
---------------------------
function GetNumFriends()
    local _,WoWFriends = C_FriendList.GetNumFriends()
    if (WoWFriends == nil) then
        return _, "0"
    end
    return _, WoWFriends
end
function gf.Friends.update()
	if btn.enabled and gv.loaded then -- loaded keeps it from launching when defined
		Glance.Debug("function","update","Friends")
        local _,WoWFriends = GetNumFriends() -- Outdate 60200
		local _,RealFriends = BNGetNumFriends()
		gf.setButtonText(btn.button,"Friends: ",WoWFriends..","..RealFriends,nil,nil)
	end
end

---------------------------
-- tooltip
---------------------------
function gf.Friends.tooltip()
	Glance.Debug("function","tooltip","Friends")
    local _,WoWFriends = GetNumFriends()
	local _,RealFriends = BNGetNumFriends()
	
	-- Friends
	tooltip.Double(WoWFriends.." Friend(s) Online","Location","GLD","GLD")
	for i = 0, GetNumFriends() do
        --local name, level, class, area, connected, status, note = GetFriendInfo(i) Outdated 60200
        local name, level, class, area, connected, status, note = C_FriendList.GetFriendInfo(i)
		if connected then
			local msg1, msg2 = unpack(gf.Friends.formatFriend(name, level, race, class, area))
			tooltip.Double(msg1, msg2, "WHT", "LBL")
		end
	end
	-- BNET Friends under friends
	for j = 1, RealFriends do
		local presenceID, presenceName,_,_,toon,toonID,client,isOnline,_ = BNGetFriendInfo(j)
        -- local _, toonName, _, realmName, _, _, race, class, _, zoneName, level, gameText, _ = BNGetToonInfo(toonID or presenceID) Outdated 60200
        local _, toonName, _, realmName, _, _, race, class, _, zoneName, level, gameText, _ = BNGetGameAccountInfo(toonID or presenceID)
		if isOnline then
			client = ga.Clients[client] or client			
			if string.upper(client) == "WOW" then			
				local msg1, msg2 = unpack(gf.Friends.formatFriend(toonName, level, race, class, zoneName))
				tooltip.Double(HEX.lightblue.."BN: |r"..msg1, msg2, "WHT", "LBL")
			end
		end
	end
	
	--BNET IDS
	tooltip.Space()
	tooltip.Double(RealFriends.." BattleNet Friend(s) Online","Character","GLD","GLD")
	for j = 1, RealFriends do
		local presenceID, presenceName,_,_,toon,toonID,client,isOnline,_ = BNGetFriendInfo(j)
		-- local _, toonName, _, realmName, _, _, race, class, _, zoneName, level, gameText, _ = BNGetToonInfo(toonID or presenceID) Outdated 60200
		local _, toonName, _, realmName, _, _, race, class, _, zoneName, level, gameText, _ = BNGetGameAccountInfo(toonID or presenceID)
		if isOnline then
			local msg1, msg2 = unpack(gf.Friends.formatBNET(presenceName, client, realmName, toonName))
			tooltip.Double(msg1, msg2, "WHT", "LBL")
		end
	end
	--(left,shift-left,right,shift-right,other)
	tooltip.Notes("open the Friends tab",nil,nil,nil,nil)
end

---------------------------
-- click
---------------------------
function gf.Friends.click(self, button, down)
	Glance.Debug("function","click","Friends")
	if button == "LeftButton" then
		ToggleFriendsFrame() --removed the value "1" from being passed to fix bug.
	end
end

---------------------------
-- tired of concatenation errors
---------------------------
function gf.Friends.bp(str,val)
	if not str then
		str = ""
	end
	if val then
		str = str..tostring(val)
	end
	return str
end

---------------------------
-- format friends
---------------------------
function gf.Friends.formatFriend(name, level, race, class, area)
	local color, msg1, msg2 = "","",""
	if class then 
		local clss= string.upper(class) or "PRIEST"
		color = CLS[clss]
		msg1 = gf.Friends.bp(msg1,color)
	end
	if name then
		msg1 = gf.Friends.bp(msg1,name)
		if level ~= nil and level ~= "" then
			msg1 = gf.Friends.bp(msg1," |r("..HEX.green)
			msg1 = gf.Friends.bp(msg1,level)
			msg1 = gf.Friends.bp(msg1,"|r")
			if race then 
				msg1 = gf.Friends.bp(msg1," ")
				msg1 = gf.Friends.bp(msg1,race)
			end
			if class then 
				msg1 = gf.Friends.bp(msg1," ")
				msg1 = gf.Friends.bp(msg1, color)
				msg1 = gf.Friends.bp(msg1,class)
			end
			msg1 = gf.Friends.bp(msg1,"|r)")
		else
			area = "MIA"
		end
		if area then
			msg2 = gf.Friends.bp(msg2,area)
		end
	end
	return {msg1,msg2}
end

---------------------------
-- format BNET friends
---------------------------
function gf.Friends.formatBNET(name, client, realm, toon)
	local msg1, msg2 = "","",""
	if name then
		msg1 = gf.Friends.bp(msg1,HEX.lightblue)
		msg1 = gf.Friends.bp(msg1,name)
		if client then
			msg1 = gf.Friends.bp(msg1," |r[")
			client = ga.Clients[client] or client			
			if string.upper(client) == "WOW" then	
				msg1 = gf.Friends.bp(msg1,HEX.green)
				msg1 = gf.Friends.bp(msg1,client)
				if realm ~= nil and realm ~= "" then
					msg1 = gf.Friends.bp(msg1," - ")
					msg1 = gf.Friends.bp(msg1,realm)
				end
			else
				msg1 = gf.Friends.bp(msg1,HEX.red)
				msg1 = gf.Friends.bp(msg1,client)
			end
			msg1 = gf.Friends.bp(msg1,"|r]")
		end
		if toon then
			msg2 = gf.Friends.bp(msg2,toon)
		end
	end
	return {msg1,msg2}
end

---------------------------
-- load on demand
---------------------------
if gv.loaded then
	gf.Enable("Friends")
end