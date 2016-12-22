--[[
	Componente PlayerInput
	-> Controla o CharacterMotor com a entrada do jogador
	-> Requer um CharacterMotor pra funcionar
]]

PlayerInput = Component("input")
PlayerInput:require("characterMotor")

function PlayerInput:init()
	self.motor = self.go.characterMotor
end

function PlayerInput:update(dt)
	local changeX = 0
	if (love.keyboard.isDown("left")) then
		changeX = -1
	end
	if (love.keyboard.isDown("right")) then
		changeX = 1
	end
	self.motor:move(changeX)

	if (love.keyboard.isDown("up") and self.motor.isGrounded) then
		self.motor:jump()
	end
	if (love.keyboard.isDown("z")) then
		self.motor:die()
	end
end