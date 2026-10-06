-- Sunny Side Cafe: a gentle, shape-drawn game about movement, choices, and helping.
local W, H = 1000, 720
local WORLD_BOTTOM = 520
local foods = {
	{ name = "Soda", color = {0.31, 0.75, 0.93}, station = 1, prep = 3 },
	{ name = "Hot dog", color = {0.96, 0.54, 0.28}, station = 2, prep = 5 },
	{ name = "Hamburger", color = {0.68, 0.48, 0.29}, station = 2, prep = 6 },
	{ name = "Pie", color = {0.91, 0.57, 0.35}, station = 3, prep = 5 },
	{ name = "Lollipop", color = {0.96, 0.45, 0.65}, station = 4, prep = 3 },
	{ name = "Bread", color = {0.91, 0.72, 0.40}, station = 3, prep = 4 },
	{ name = "Salad", color = {0.39, 0.72, 0.43}, station = 4, prep = 4 },
	{ name = "Candy", color = {0.73, 0.51, 0.87}, station = 4, prep = 3 },
	{ name = "Pizza", color = {0.97, 0.69, 0.30}, station = 3, prep = 6 },
	{ name = "French fries", color = {0.96, 0.78, 0.34}, station = 2, prep = 4 },
}
local guests = {}
local player = { x = 500, y = 285, speed = 235, radius = 14 }
local activeGuest = nil
local carrying = nil
local cooking = nil
local feedback = "Welcome! Use the arrow keys or WASD to move."
local feedbackTime = 5
local served = 0
local nextGuestIn = 8
local fonts = {}
local view = { scaleX = 1, scaleY = 1, x = 0, y = 0 }
local guestColors = {
	{0.97, 0.48, 0.48}, {0.43, 0.69, 0.90}, {0.95, 0.68, 0.30},
	{0.54, 0.76, 0.51}, {0.75, 0.55, 0.85}, {0.94, 0.57, 0.71},
}
local seats = {
	{ x = 700, y = 455 }, { x = 850, y = 455 },
}
local stations = {
	{ name = "DRINKS", x = 170, y = 158, color = {0.42, 0.74, 0.87} },
	{ name = "GRILL", x = 390, y = 158, color = {0.93, 0.57, 0.35} },
	{ name = "OVEN", x = 610, y = 158, color = {0.91, 0.68, 0.40} },
	{ name = "PREP", x = 830, y = 158, color = {0.48, 0.74, 0.48} },
}
-- Counter gaps are doorways; the other counter and appliance islands are solid.
local barriers = {
	{ x = 35, y = 326, w = 422, h = 85 },
	{ x = 543, y = 326, w = 422, h = 85 },
	{ x = 91, y = 115, w = 158, h = 86 },
	{ x = 311, y = 115, w = 158, h = 86 },
	{ x = 531, y = 115, w = 158, h = 86 },
	{ x = 751, y = 115, w = 158, h = 86 },
}

local function setColor(c, alpha)
	love.graphics.setColor(c[1], c[2], c[3], alpha or 1)
end

local function say(text)
	feedback, feedbackTime = text, 4
end

local function roundRect(x, y, w, h, r, color)
	setColor(color)
	love.graphics.rectangle("fill", x, y, w, h, r, r)
end

local function foodIcon(index, x, y, size)
	local cx, cy = x + size / 2, y + size / 2
	local s = size
	local f = foods[index]
	if not f then return end
	setColor({0.18, 0.21, 0.25, 0.12})
	love.graphics.ellipse("fill", cx, y + s * 0.85, s * 0.39, s * 0.09)
	if index == 1 then -- soda cup
		setColor(f.color)
		love.graphics.polygon("fill", cx-s*.25, cy-s*.27, cx+s*.25, cy-s*.27, cx+s*.19, cy+s*.31, cx-s*.18, cy+s*.31)
		setColor({1,1,1,0.8}); love.graphics.rectangle("fill", cx-s*.13, cy-s*.13, s*.08, s*.28, 3, 3)
		setColor({0.95,0.42,0.49}); love.graphics.line(cx+s*.06, cy-s*.27, cx+s*.18, cy-s*.43)
	elseif index == 2 then -- hot dog
		setColor({0.93,0.70,0.39}); love.graphics.ellipse("fill", cx, cy, s*.37, s*.19)
		setColor({0.72,0.34,0.20}); love.graphics.ellipse("fill", cx, cy, s*.29, s*.115)
		setColor({0.94,0.68,0.27}); love.graphics.arc("line", "open", cx, cy, s*.23, 0, math.pi)
	elseif index == 3 then -- hamburger
		setColor({0.75,0.43,0.22}); love.graphics.ellipse("fill", cx, cy+s*.10, s*.34, s*.17)
		setColor({0.48,0.67,0.32}); love.graphics.rectangle("fill", cx-s*.32, cy-s*.02, s*.64, s*.08, 4, 4)
		setColor({0.94,0.71,0.37}); love.graphics.arc("fill", "pie", cx, cy, s*.34, math.pi, math.pi*2)
		setColor({1,0.91,0.68}); for i=1,3 do love.graphics.circle("fill", cx-s*.15+i*s*.12, cy-s*.18, 1.5) end
	elseif index == 4 then -- pie slice
		setColor(f.color); love.graphics.polygon("fill", cx-s*.34, cy+s*.24, cx+s*.34, cy+s*.24, cx+s*.05, cy-s*.29)
		setColor({0.75,0.35,0.23}); love.graphics.line(cx-s*.32, cy+s*.24, cx+s*.32, cy+s*.24)
		setColor({1,0.86,0.54}); love.graphics.arc("line", "open", cx, cy, s*.20, math.pi, math.pi*2)
	elseif index == 5 then -- lollipop
		setColor({0.82,0.67,0.48}); love.graphics.setLineWidth(3); love.graphics.line(cx, cy, cx, cy+s*.36)
		setColor(f.color); love.graphics.circle("fill", cx, cy-s*.10, s*.27)
		setColor({1,0.85,0.90}); love.graphics.arc("line", "open", cx, cy-s*.10, s*.16, math.pi, math.pi*1.8)
	elseif index == 6 then -- bread loaf
		setColor(f.color); love.graphics.ellipse("fill", cx, cy, s*.34, s*.24)
		setColor({0.76,0.51,0.27}); love.graphics.setLineWidth(2)
		love.graphics.arc("line", "open", cx-s*.10, cy, s*.13, math.pi, math.pi*2)
		love.graphics.arc("line", "open", cx+s*.10, cy, s*.13, math.pi, math.pi*2)
	elseif index == 7 then -- salad bowl
		setColor({0.84,0.91,0.94}); love.graphics.arc("fill", "pie", cx, cy-s*.05, s*.34, 0, math.pi)
		setColor(f.color); love.graphics.circle("fill", cx-s*.13, cy-s*.04, s*.12); love.graphics.circle("fill", cx+s*.12, cy-s*.09, s*.12)
		setColor({0.96,0.43,0.43}); love.graphics.circle("fill", cx+s*.02, cy+s*.03, s*.07)
	elseif index == 8 then -- wrapped candy
		setColor(f.color); love.graphics.rectangle("fill", cx-s*.23, cy-s*.16, s*.46, s*.32, 5, 5)
		love.graphics.polygon("fill", cx-s*.23,cy, cx-s*.39,cy-s*.13, cx-s*.39,cy+s*.13)
		love.graphics.polygon("fill", cx+s*.23,cy, cx+s*.39,cy-s*.13, cx+s*.39,cy+s*.13)
		setColor({1,1,1,0.75}); love.graphics.line(cx-s*.08, cy-s*.11, cx+s*.08, cy+s*.11)
	elseif index == 9 then -- pizza slice
		setColor({0.94,0.72,0.35}); love.graphics.polygon("fill", cx-s*.34,cy-s*.25, cx+s*.34,cy-s*.25, cx,cy+s*.34)
		setColor({0.91,0.39,0.30}); love.graphics.circle("fill", cx-s*.10,cy-s*.08,s*.045); love.graphics.circle("fill",cx+s*.12,cy-s*.07,s*.045)
		love.graphics.circle("fill", cx,cy+s*.08,s*.045)
	elseif index == 10 then -- fries
		setColor({0.89,0.35,0.34}); love.graphics.polygon("fill", cx-s*.28,cy-s*.08,cx+s*.28,cy-s*.08,cx+s*.20,cy+s*.32,cx-s*.20,cy+s*.32)
		setColor(f.color); for i=1,4 do local fx=cx-s*.21+i*s*.10; love.graphics.rectangle("fill",fx,cy-s*.32+(i%2)*s*.035,s*.075,s*.35,3,3) end
	end
end

local function addGuest()
	if #guests >= 6 then return end
	local occupied = {}
	for _, g in ipairs(guests) do if g.seat then occupied[g.seat] = true end end
	local available = {}
	for i=1,#seats do if not occupied[i] then available[#available+1] = i end end
	local seat = nil
	if #available > 0 and (#guests == 0 or love.math.random() < 0.58) then
		seat = available[love.math.random(#available)]
	end
	local i = #guests + 1
	local position = seat and seats[seat] or {x=130 + i*120, y=455}
	guests[#guests+1] = {
		x=position.x, y=position.y, seat=seat,
		food=love.math.random(#foods), color=guestColors[love.math.random(#guestColors)],
		state="waiting", timer=0, name=({"Pip", "Milo", "Sunny", "Bea", "Coco", "Remy"})[love.math.random(6)],
	}
end

local function nearestGuest(x, y, maxDistance)
	local best, bestD = nil, maxDistance or 78
	for _, g in ipairs(guests) do
		if g.state ~= "leaving" then
			local d = math.sqrt((g.x-x)^2 + (g.y-y)^2)
			if d < bestD then best, bestD = g, d end
		end
	end
	return best, bestD
end

local function nearPoint(x, y, point, distance)
	local dx, dy = x - point.x, y - point.y
	return dx * dx + dy * dy <= distance * distance
end

local function stationForPlayer()
	for i, station in ipairs(stations) do
		if nearPoint(player.x, player.y, {x = station.x, y = 226}, 68) then
			return i
		end
	end
	return nil
end

local function interact()
	if not activeGuest then
		local g = nearestGuest(player.x, player.y, 86)
		if g then activeGuest = g else say("Click a friend to select them, then walk close and press E."); return end
	end
	local g = activeGuest
	if g.state == "waiting" then
		if nearPoint(player.x, player.y, g, 86) then
			g.state = "ordering"
			say(g.name .. " would like " .. foods[g.food].name .. ". Choose it from the menu below!")
		else say("Walk close to " .. g.name .. " and press E to take their order.") end
	elseif g.state == "ordering" then
		say("Choose " .. foods[g.food].name .. " from the food menu below!")
	elseif g.state == "to_station" then
		local found = stationForPlayer()
		if not found then
			say("Carry the " .. foods[g.food].name .. " to the " .. stations[foods[g.food].station].name:lower() .. " station.")
		elseif found ~= foods[g.food].station then
			say("This is the " .. stations[found].name:lower() .. " station. Try the " .. stations[foods[g.food].station].name:lower() .. " station!")
		else
			cooking = {food = carrying, guest = g, station = found, remaining = foods[carrying].prep}
			g.state = "cooking"
			carrying = nil
			say("Cooking! Watch the countdown above the " .. stations[found].name:lower() .. " station.")
		end
	elseif g.state == "cooking" then
		say("Your " .. foods[g.food].name .. " is cooking. The countdown will tell you when it is ready!")
	elseif g.state == "ready" then
		if nearPoint(player.x, player.y, g, 86) then
			g.state, g.timer = "happy", 2.2
			carrying, activeGuest = nil, nil
			served = served + 1
			say("Great helping! Your friend is happy! ⭐")
		else say("Walk over to " .. g.name .. " and press E to serve!") end
	end
end

local function chooseFood(index)
	if not activeGuest or activeGuest.state ~= "ordering" then
		if activeGuest and activeGuest.state == "cooking" then
			say("Your " .. foods[activeGuest.food].name .. " is already cooking!")
		else
			say("First click a friend, walk close, and press E to take their order!")
		end
		return
	end
	if index == activeGuest.food then
		carrying, activeGuest.state = index, "to_station"
		local station = stations[foods[index].station]
		say("Order selected! Walk to the " .. station.name:lower() .. " station and press E to cook.")
	else
		say("Nice try! Look at the food picture in " .. activeGuest.name .. "'s bubble.")
	end
end

local function circleTouchesRect(x, y, radius, rect)
	local nearX = math.max(rect.x, math.min(x, rect.x + rect.w))
	local nearY = math.max(rect.y, math.min(y, rect.y + rect.h))
	local dx, dy = x - nearX, y - nearY
	return dx * dx + dy * dy < radius * radius
end

local function blockedAt(x, y)
	for _, barrier in ipairs(barriers) do
		if circleTouchesRect(x, y, player.radius, barrier) then return true end
	end
	for _, seat in ipairs(seats) do
		local tableBarrier = {x = seat.x - 44, y = seat.y - 26, w = 88, h = 52}
		if circleTouchesRect(x, y, player.radius, tableBarrier) then return true end
	end
	return false
end

local function movePlayer(dx, dy, dt)
	local stepX, stepY = dx * player.speed * dt, dy * player.speed * dt
	local nextX = math.max(player.radius, math.min(W - player.radius, player.x + stepX))
	local nextY = math.max(104 + player.radius, math.min(WORLD_BOTTOM - player.radius, player.y + stepY))
	if not blockedAt(nextX, player.y) then player.x = nextX end
	if not blockedAt(player.x, nextY) then player.y = nextY end
end

local function updateView()
	local width, height = love.graphics.getDimensions()
	local scale = math.min(width / W, height / H)
	view.scaleX, view.scaleY = scale, scale
	view.x = (width - W * scale) / 2
	view.y = (height - H * scale) / 2
end

local function screenToGame(x, y)
	return (x - view.x) / view.scaleX, (y - view.y) / view.scaleY
end

local function drawCafe()
	-- Mint walls and warm tiled floor
	setColor({0.95,0.88,0.70}); love.graphics.rectangle("fill",0,0,W,WORLD_BOTTOM)
	setColor({0.97,0.93,0.83}); love.graphics.rectangle("fill",0,105,W,WORLD_BOTTOM-105)
	setColor({0.91,0.85,0.72,0.32}); love.graphics.setLineWidth(1)
	for x=30,W,50 do love.graphics.line(x,110,x,WORLD_BOTTOM) end
	for y=135,WORLD_BOTTOM,50 do love.graphics.line(0,y,W,y) end
	-- Window and flowers
	roundRect(35,25,180,92,12,{0.65,0.86,0.91})
	setColor({0.88,0.97,0.97}); love.graphics.rectangle("fill",47,37,74,68,7,7); love.graphics.rectangle("fill",130,37,73,68,7,7)
	setColor({0.50,0.72,0.76}); love.graphics.setLineWidth(4); love.graphics.line(125,36,125,105); love.graphics.line(48,72,202,72)
	setColor({1,0.88,0.47}); love.graphics.circle("fill",176,53,12)
	-- Counter is split around a walk-through doorway; these shapes match solid barriers.
	for _, b in ipairs({barriers[1], barriers[2]}) do
		roundRect(b.x,b.y,b.w,b.h,15,{0.66,0.40,0.28})
		roundRect(b.x,b.y,b.w,26,12,{0.86,0.57,0.38})
		setColor({0.95,0.83,0.65}); love.graphics.rectangle("fill",b.x+15,b.y+35,b.w-30,8,4,4)
		for x=b.x+25,b.x+b.w-20,55 do setColor({0.82,0.53,0.37}); love.graphics.rectangle("fill",x,b.y+53,32,24,4,4) end
	end
	-- Four kitchen appliance islands are solid. Walk through the counter gap to reach them.
	for i, station in ipairs(stations) do
		local b = barriers[i+2]
		roundRect(b.x,b.y,b.w,b.h,13,{0.91,0.94,0.86})
		roundRect(b.x+8,b.y+8,b.w-16,14,6,station.color)
		setColor({0.40,0.47,0.40}); love.graphics.setFont(fonts.station)
		love.graphics.printf(station.name,b.x,b.y+31,b.w,"center")
		if i == 1 then
			foodIcon(1,b.x+55,b.y+45,42)
		elseif i == 2 then
			foodIcon(2,b.x+56,b.y+45,42); foodIcon(10,b.x+101,b.y+45,42)
		elseif i == 3 then
			foodIcon(9,b.x+48,b.y+45,38); foodIcon(4,b.x+92,b.y+45,38)
		else
			foodIcon(7,b.x+42,b.y+45,38); foodIcon(5,b.x+80,b.y+45,38); foodIcon(8,b.x+112,b.y+45,38)
		end
		if cooking and cooking.station == i then
			local progress = 1 - cooking.remaining / foods[cooking.food].prep
			roundRect(b.x+12,b.y+68,b.w-24,10,5,{0.82,0.84,0.78})
			roundRect(b.x+12,b.y+68,(b.w-24)*progress,10,5,{0.39,0.72,0.44})
			setColor({0.25,0.42,0.31}); love.graphics.setFont(fonts.small)
			love.graphics.printf(string.format("%s  %d",foods[cooking.food].name,math.max(0,math.ceil(cooking.remaining))),b.x,b.y+78,b.w,"center")
		end
	end
	-- Cafe tables, chairs, cups and little plants
	for _, s in ipairs(seats) do
		setColor({0.55,0.39,0.28}); love.graphics.circle("fill",s.x-42,s.y+2,18); love.graphics.circle("fill",s.x+42,s.y+2,18)
		setColor({0.90,0.67,0.43}); love.graphics.ellipse("fill",s.x,s.y,49,31)
		setColor({1,0.91,0.70}); love.graphics.ellipse("fill",s.x,s.y-5,43,24)
		setColor({0.48,0.74,0.48}); love.graphics.circle("fill",s.x+27,s.y-11,6)
	end
	-- Title sign
	roundRect(330,24,365,55,15,{1,0.97,0.84})
	setColor({0.35,0.48,0.38}); love.graphics.setFont(fonts.title); love.graphics.printf("☀  SUNNY SIDE CAFÉ  ☀",330,34,365,"center")
end

local function drawGuest(g)
	local x,y = g.x,g.y
	if g.seat then
		-- seated body and friendly round face
		setColor(g.color); love.graphics.ellipse("fill",x,y+13,23,19)
		setColor({0.99,0.80,0.62}); love.graphics.circle("fill",x,y-9,19)
		setColor({0.22,0.23,0.26}); love.graphics.circle("fill",x-6,y-11,2); love.graphics.circle("fill",x+6,y-11,2)
		setColor({0.85,0.39,0.38}); love.graphics.arc("line","open",x,y-6,6,0.15,math.pi-0.15)
	else
		setColor(g.color); love.graphics.ellipse("fill",x,y+18,20,18)
		setColor({0.99,0.80,0.62}); love.graphics.circle("fill",x,y-9,17)
		setColor({0.22,0.23,0.26}); love.graphics.circle("fill",x-5,y-10,1.8); love.graphics.circle("fill",x+5,y-10,1.8)
		setColor({0.85,0.39,0.38}); love.graphics.arc("line","open",x,y-5,5,0.15,math.pi-0.15)
	end
	if activeGuest == g then
		setColor({1,0.79,0.28}); love.graphics.setLineWidth(3); love.graphics.circle("line",x,y+2,30)
	end
	if g.state == "waiting" or g.state == "ordering" or g.state == "to_station" or g.state == "cooking" or g.state == "ready" then
		roundRect(x-48,y-81,96,50,12,{1,1,0.96})
		setColor({1,1,0.96}); love.graphics.polygon("fill",x-7,y-32,x+7,y-32,x,y-23)
		if g.state == "waiting" then
			love.graphics.setFont(fonts.small); setColor({0.34,0.42,0.36}); love.graphics.printf("Hi!",x-40,y-71,80,"center")
		elseif g.state == "cooking" then
			love.graphics.setFont(fonts.small); setColor({0.34,0.42,0.36})
			love.graphics.printf("Cooking...",x-45,y-70,90,"center")
		elseif g.state == "ready" then
			foodIcon(g.food,x-17,y-74,34)
		else
			foodIcon(g.food,x-17,y-74,34)
		end
	end
	if g.state == "happy" then
		love.graphics.setFont(fonts.small); setColor({0.30,0.59,0.38}); love.graphics.printf("YUM! ♥",x-40,y-67,80,"center")
	end
end

local function drawPlayer()
	local x,y=player.x,player.y
	setColor({0.25,0.54,0.73}); love.graphics.ellipse("fill",x,y+13,20,21)
	setColor({0.99,0.80,0.62}); love.graphics.circle("fill",x,y-13,17)
	setColor({0.36,0.26,0.19}); love.graphics.arc("fill","pie",x,y-18,17,math.pi,math.pi*2)
	setColor({0.22,0.23,0.26}); love.graphics.circle("fill",x-5,y-13,1.8); love.graphics.circle("fill",x+5,y-13,1.8)
	setColor({0.76,0.39,0.34}); love.graphics.arc("line","open",x,y-8,5,0.15,math.pi-0.15)
	if carrying then
		local badgeX, badgeY = x+26, y-31
		local readyToServe = activeGuest and activeGuest.state == "ready"
		setColor({1,1,0.96}); love.graphics.circle("fill",badgeX,badgeY,23)
		foodIcon(carrying,badgeX-16,badgeY-19,32)
		if readyToServe then
			-- Green double ring and check badge mean cooking is complete.
			setColor({0.22,0.67,0.39}); love.graphics.setLineWidth(3)
			love.graphics.circle("line",badgeX,badgeY,23)
			love.graphics.circle("line",badgeX,badgeY,19)
			love.graphics.circle("fill",badgeX+16,badgeY-16,8)
			setColor({1,1,1}); love.graphics.setLineWidth(2.5)
			love.graphics.line(badgeX+12,badgeY-16,badgeX+15,badgeY-13,badgeX+20,badgeY-19)
		else
			-- Orange ring and MAKE label mean this food still needs a station.
			setColor({0.94,0.58,0.16}); love.graphics.setLineWidth(3)
			love.graphics.circle("line",badgeX,badgeY,23)
			love.graphics.setFont(fonts.small)
			love.graphics.printf("MAKE",badgeX-19,badgeY+15,38,"center")
		end
	end
end

local function drawCard(i)
	local col=(i-1)%5
	local row=math.floor((i-1)/5)
	local x=24+col*192
	local y=560+row*70
	local selected = activeGuest and activeGuest.food == i
	local bg = selected and {0.83,0.96,0.79} or {1,0.98,0.90}
	roundRect(x,y,178,60,13,bg)
	setColor(selected and {0.34,0.67,0.40} or {0.87,0.82,0.70})
	love.graphics.setLineWidth(selected and 3 or 1); love.graphics.rectangle("line",x,y,178,60,13,13)
	foodIcon(i,x+6,y+5,48)
	setColor({0.29,0.36,0.31}); love.graphics.setFont(fonts.card)
	love.graphics.printf(tostring(i==10 and 0 or i).."  "..foods[i].name,x+55,y+20,116,"left")
end

function love.load()
	love.graphics.setDefaultFilter("nearest","nearest")
	fonts.title = love.graphics.newFont(21)
	fonts.small = love.graphics.newFont(13)
	fonts.card = love.graphics.newFont(14)
	fonts.ui = love.graphics.newFont(16)
	fonts.big = love.graphics.newFont(28)
	fonts.station = love.graphics.newFont(12)
	updateView()
	for _=1,3 do addGuest() end
end

function love.resize()
	updateView()
end

function love.update(dt)
	dt = math.min(dt, 0.05)
	if feedbackTime > 0 then feedbackTime=feedbackTime-dt end
	if #guests < 6 then
		nextGuestIn=nextGuestIn-dt
		if nextGuestIn <= 0 then addGuest(); nextGuestIn=10 end
	end
	for i=#guests,1,-1 do
		local g=guests[i]
		if g.state == "happy" then
			g.timer=g.timer-dt
			if g.timer <= 0 then table.remove(guests,i) end
		end
	end
	if cooking then
		cooking.remaining = cooking.remaining - dt
		if cooking.remaining <= 0 then
			local guest = cooking.guest
			cooking = nil
			guest.state = "ready"
			carrying = guest.food
			activeGuest = guest
			say("Ding! " .. foods[guest.food].name .. " is ready. Take it to " .. guest.name .. "!")
		end
	end
	local dx,dy=0,0
	if love.keyboard.isDown("left","a") then dx=dx-1 end
	if love.keyboard.isDown("right","d") then dx=dx+1 end
	if love.keyboard.isDown("up","w") then dy=dy-1 end
	if love.keyboard.isDown("down","s") then dy=dy+1 end
	if dx~=0 or dy~=0 then
		local length=math.sqrt(dx*dx+dy*dy)
		movePlayer(dx/length,dy/length,dt)
	end
end

function love.draw()
	love.graphics.clear(0.13,0.18,0.16)
	love.graphics.setColor(0.13,0.18,0.16)
	local screenWidth, screenHeight = love.graphics.getDimensions()
	love.graphics.rectangle("fill",0,0,screenWidth,screenHeight)
	love.graphics.push()
	love.graphics.translate(view.x,view.y)
	love.graphics.scale(view.scaleX, view.scaleY)
	drawCafe()
	for _,g in ipairs(guests) do drawGuest(g) end
	drawPlayer()
	-- Bottom control and food panel
	setColor({0.88,0.93,0.81}); love.graphics.rectangle("fill",0,WORLD_BOTTOM,W,H-WORLD_BOTTOM)
	setColor({0.39,0.49,0.39}); love.graphics.setFont(fonts.ui)
	love.graphics.print("FOOD MENU  ·  Click a picture or press its number",24,535)
	for i=1,#foods do drawCard(i) end
	-- Friendly status strip
	roundRect(24,700,952,1,1,{0.75,0.82,0.72})
	love.graphics.setFont(fonts.small); setColor({0.37,0.45,0.38})
	local status = feedbackTime>0 and feedback or (cooking and ("Making "..foods[cooking.food].name.." — "..math.max(0,math.ceil(cooking.remaining)).." seconds to go!") or (carrying and ("Carrying "..foods[carrying].name.." — walk to the "..stations[foods[carrying].station].name:lower().." station, then press E.") or "No rush! Move with WASD or arrow keys. Click a friend to select them; press E or Space to interact."))
	love.graphics.printf(status,28,687,760,"left")
	love.graphics.setFont(fonts.ui); setColor({0.40,0.58,0.40})
	love.graphics.printf("⭐ "..served.." happy friends",790,684,185,"right")
	love.graphics.pop()
end

function love.keypressed(key)
	if key == "escape" then love.event.quit(); return end
	if key=="e" or key=="space" then interact(); return end
	local index
	if key=="0" then index=10 else index=tonumber(key) end
	if index and index>=1 and index<=10 then chooseFood(index); return end
	if key == "f11" then
		local fullscreen = love.window.getFullscreen()
		love.window.setFullscreen(not fullscreen, "desktop")
	end
end

function love.mousepressed(x,y,button)
	if button~=1 then return end
	x,y = screenToGame(x,y)
	if x<0 or x>W or y<0 or y>H then return end
	if y>=555 and y<690 then
		local col=math.floor((x-24)/192)
		local row=math.floor((y-560)/70)
		local index=row*5+col+1
		if x>=24 and col>=0 and col<5 and row>=0 and row<2 and index<=10 then chooseFood(index) end
		return
	end
	if y>=WORLD_BOTTOM then return end
	local picked
	for _,g in ipairs(guests) do
		if g.state ~= "happy" and math.sqrt((g.x-x)^2+(g.y-y)^2)<45 then picked=g; break end
	end
	if picked then
		if activeGuest and activeGuest ~= picked and activeGuest.state ~= "waiting" and activeGuest.state ~= "happy" then
			say("Finish helping " .. activeGuest.name .. " first, then choose another friend.")
			return
		end
		activeGuest = picked
		say(""..picked.name.." is selected. Walk close and press E to help!")
	end
end