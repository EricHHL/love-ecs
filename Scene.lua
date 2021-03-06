--[[
	Scene: 
	-> Responsável por manter e gerenciar todos os gameObjects
	-> Chama as funções draw e update dos gameObjects
]]

Scene = {}
Scene.__index = Scene

local nextID = 0;

local function new(name)
	local s = {}
	setmetatable(s, Scene)

	s.gameObjects = {}
	s.name = name

	ECS:registerScene(s)

	return s
end

function Scene:_update(dt)
	for k,go in pairs(self.gameObjects) do
		go:update(dt)
	end
	if self.update then
		self:update(dt)
	end
end

function Scene:_draw()
	for k,go in pairs(self.gameObjects) do
 			go:draw()
	end
	if self.draw then
		self:draw()
	end
end

function Scene:addGO(go)
	assert(go.isInstance, "GameObject needs to be an instance")
	go:setScene(self)
	self.gameObjects[go.id] = go
end

function Scene:instantiate(go, args)
	args = args or {}
	local inst = {}
	inst.components = {}
	inst.children = {}
	setmetatable(inst, GameObject)

	for k,v in pairs(go) do 	--Copia valores
		if v ~= go.components and v ~= go.children then
			inst[k] = v
		end
	end

	for k,c in pairs(go.components) do
		inst:addComponent(c:clone())
	end
	for k,ch in pairs(go.children) do
		inst:addChild(ch)	
	end

	go.nInstances = go.nInstances + 1

	inst.name = args.name or go.name..go.nInstances and go.nInstances > 1 or go.name

	inst.id = nextID
	nextID = nextID + 1
	

	if inst.transform then
		inst.transform.localPos = args.pos or inst.transform.localPos
		inst.transform.o = args.o or inst.transform.o
		inst.transform.localScale = args.scale or inst.transform.localScale
	end

	inst.active = true
	inst.isInstance = true


	inst:init()

	self:addGO(inst)

	return inst
end

function Scene:removeGO(go)
	self.gameObjects[go.id] = nil
end

function Scene:loadMap(name)
	map = require("maps."..name)
	map.tiles = {}

	for i,ts in ipairs(map.tilesets) do
		ts.texture = ResourceMgr.get("tileset", ts.image)
		local curID = ts.firstgid
		ts.lastid = curID + ts.tilecount
		for j=0, (ts.imageheight/ts.tileheight)-1 do
			for i=0, (ts.imagewidth/ts.tilewidth)-1 do
				map.tiles[curID] = {}
				map.tiles[curID].quad = love.graphics.newQuad(i*ts.tilewidth, j*ts.tileheight, ts.tilewidth, ts.tileheight, ts.imagewidth, ts.imageheight)
				curID = curID + 1
			end
		end

		for k,t in pairs(ts.tiles) do
			for k,p in pairs(t.properties) do
				map.tiles[t.id+1][k] = p
			end
		end
	end

	local function getTileSet(id)
		for i,ts in ipairs(map.tilesets) do
			if (id>=ts.firstgid and id < ts.lastid) then
				return i
			end
		end
		return 0
	end

	for k,l in pairs(map.layers) do
		if (l.properties.static) then 	--Estatico, nunca muda. Poe tudo num spriteBatch em um gameObject
			local layerGO = GameObject(l.name)	 
			local batchs = {}	--Precisa de um spritebatch para cada tileset
		    local curTile = 1

		    --Pra não criar um collider por tile, detecta os tiles adjacentes pra criar um collider só

		    local colX = 0	
		    local colY = 0
		    local colW = 0
		    local colCount = 0

		    for j=0,map.height-1 do
		    	for i=0,map.width-1 do
		    		local closeCollider = false
		    		if(l.data[curTile] ~= 0) then
			    		local tsID = getTileSet(l.data[curTile])
			    		if not batchs[tsID] then 	--Só cria um batch pro tileset se ele for usado
			    			batchs[tsID] = love.graphics.newSpriteBatch(map.tilesets[tsID].texture, map.width * map.height, "static")
			    		end
			    		batchs[tsID]:add(map.tiles[l.data[curTile]].quad, i*map.tilewidth, j*map.tileheight)

			    		--Trata da criação do boxCollider

			    		if(l.properties.collision) then
			    			if(map.tiles[l.data[curTile]].isSlope) then
			    				local colliderGO = GameObject("col"..colCount, {BoxCollider(map.tilewidth, map.tileheight)})
				    			colliderGO.transform:moveTo(i*map.tilewidth, j*map.tileheight)
				    			
				    			colliderGO.collider.isSlope = true	
				    			colliderGO.collider.rightY = map.tiles[l.data[curTile]].rightY
				    			colliderGO.collider.leftY = map.tiles[l.data[curTile]].leftY

				    			layerGO:addChild(colliderGO)
				    			colCount = colCount + 1

				    			closeCollider = true
			    			else
					    		if(colW==0)then
					    			colX = i*map.tilewidth
					    			colY = j*map.tileheight
					    		end
					    		colW = colW + 1
					    	end

				    	end
			    	end


			    	--Se tiver um tile vazio ou acabou o mapa, e os tiles anteriores tinham colisão, fecha um collider
			    	nextTile = math.min(curTile+1, map.width*map.height-1)

			    	if ((l.data[curTile] == 0 or i == (map.width-1) or closeCollider) and l.properties.collision and colW>0) then
		    			colCount = colCount + 1
		    			local colliderGO = GameObject("col"..colCount, {BoxCollider(colW*map.tilewidth, map.tileheight)})
		    			colliderGO.transform:moveTo(colX, colY)

		    			colliderGO.tileID = l.data[curTile]
		    			if(l.data[curTile] == 21)then
		    				colliderGO.isSlope = true	
		    			end
		    			layerGO:addChild(colliderGO)

		    			colW = 0
		    		
			    	end
			    	curTile = curTile + 1
		    	end
		    end

		    for i,b in ipairs(batchs) do
		    	local tsGO = GameObject("tileset "..i, {Renderer(b)})
		    	layerGO:addChild(tsGO)
		    end

		    self:addGO(layerGO:newInstance())

		end
	end
	if(map.backgroundcolor) then
		love.graphics.setBackgroundColor(map.backgroundcolor)
	end
	love.window.setMode(map.width*map.tilewidth, map.height*map.tileheight)
end

setmetatable(Scene, {__call = function(_, ...) return new(...) end})