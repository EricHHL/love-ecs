local function newDefaultTextBox()
	return {
		--Basico
		text = "",
		panelType = "textBox",
		w = 150,
		h = 30,
		callback = function() end,
		hasFocus = false,

		--Cores
		color = Color(220),
		focusColor = Color(240),
		textColor = Color(0),
		
		--Texto
		font = font,
		textAlign = "left",

		--Caret
		caret = false,
		caretTimer = love.timer.getTime(),
		caretPos = 0,

		--Layout 
		halign = "parent",
		valign = "parent",
		weight = 1,

		wType = widgetType.textBox,

		drawSelf = function(self)
			if (self.hasFocus) then
				love.graphics.setColor(self.focusColor:value())
				if (love.timer.getTime() - self.caretTimer > 0.5) then
					self.caretTimer = love.timer.getTime()
					self.caret = not self.caret
				end
				
			else
				love.graphics.setColor(self.color:value())
			end
			love.graphics.draw(self.batch, self.realX, self.realY, 0, 1, 1)
			love.graphics.setColor(self.textColor:value())
			love.graphics.setFont(self.font)
			if (self.caret) then
				love.graphics.printf("|", self.realX+self.fontX+panelTypes[self.panelType].borderSize + self.font:getWidth(string.sub(self.text, 1, self.caretPos)) - self.font:getWidth("|")/2, self.realY + self.fontY + panelTypes[self.panelType].borderSize, self.w-panelTypes[self.panelType].borderSize*2, self.textAlign)
			end

			love.graphics.printf(self.text, self.realX+self.fontX+panelTypes[self.panelType].borderSize, self.realY + self.fontY + panelTypes[self.panelType].borderSize, self.w-panelTypes[self.panelType].borderSize*2, self.textAlign)
		end,

		refresh = function(self)
			self.batch = self.gui:newPanel(self.panelType, self.realW, self.realH)
			local border = panelTypes[self.panelType] and panelTypes[self.panelType].borderSize or 0
			self.fontY = (self.realH - border*2-self.font:getHeight()) / 2
			self.fontX = 5
		end
	}
end

return Widget(newDefaultTextBox)