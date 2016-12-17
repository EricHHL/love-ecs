--[[
	Componente Renderer
	->  Desenha a textura na posição do objeto
]]

Renderer = Component("renderer")

function Renderer:new(texture, color)
	
	if (type(texture)== "userdata") then
 		self.texture = texture
 	else
 		if (type(texture) == "string") then
 			self.texture = ResourceMgr.get("texture", texture)
 		end
 	end

	self.offsetX = 0
	self.offsetY = 0
	self.mirror = false

	self.color = color or Color(255)

	return self
end

function Renderer:init()
	assert(self.go, self.name.." component has no GameObject")
end

function Renderer:draw()
	love.graphics.setColor(self.color:value())
	local posX = self.go.transform.x + self.offsetX
	local scaleX = self.go.transform.sx
	if self.mirror then
		scaleX = scaleX * -1
		if (self.quad) then
			local a, b, quadW = self.quad:getViewport()
			posX = self.go.transform.x + quadW + self.offsetX
		else
			posX = self.go.transform.x + self.texture:getWidth() + self.offsetX			
		end
	end
	if(self.quad) then
		love.graphics.draw(self.texture, self.quad, math.floor(posX), math.floor(self.go.transform.y + self.offsetY), self.go.transform.o, scaleX, self.go.transform.sy)
	else
		love.graphics.draw(self.texture, posX, self.go.transform.y, self.go.transform.o, scaleX, self.go.transform.sy)
	end
end
