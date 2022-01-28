local borderSize = 10 -- For seeing the final layer of interference patterns on the walls TODO: on-the-fly
local canvasWidth, canvasHeight =
	(love.graphics.getWidth() - borderSize * 2) * 0.5,
	(love.graphics.getHeight() - borderSize * 2) * 0.5
local falloffChangeRate = 0.25
local minimumFalloff = -5 -- As in (-inf, inf) space, not (0, inf)
local maximumFalloff = 5 -- Ditto
-- local dampingChangeRate = 0.5

local paused
local falloff, radius
local greyscale
-- local damping

local pressureCanvas, outflowCanvas, spaceCanvas
local pressureShader, outflowShader, viewShader, paintShader
local dummy

local function paint(type, x, y, radius, amount, falloff)
	love.graphics.push("all")
	if type == "pressure" then
		love.graphics.setCanvas(pressureCanvas)
		paintShader:send("current", pressureCanvas)
	elseif type == "space" then
		love.graphics.setCanvas(spaceCanvas)
		paintShader:send("current", spaceCanvas)
	else
		error("Painting type \"" .. type .. "\" is invalid")
	end
	paintShader:send("toAdd", amount)
	paintShader:send("falloff", falloff)
	love.graphics.setShader(paintShader)
	love.graphics.draw(dummy, x, y, 0, radius, radius, 0.5, 0.5)
	love.graphics.pop()
end

function love.load(args)
	-- Painting
	falloff = 0
	radius = 10
	greyscale = true
	
	-- Simulating
	paused = false
	-- damping = 0.01
	
	-- Drawing
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setBlendMode("replace", "premultiplied")
	
	dummy = love.graphics.newImage(love.image.newImageData(1, 1))
	
	love.graphics.push("all")
	
	local start
	if args[1] then
		start = love.graphics.newImage(args[1])
	end
	
	outflowCanvas = love.graphics.newCanvas(canvasWidth, canvasHeight, {format = "rgba16f"})
	
	pressureCanvas = love.graphics.newCanvas(canvasWidth, canvasHeight, {format = "r16f"})
	pressureCanvas:setWrap("clamp")
	if start then
		love.graphics.setCanvas(pressureCanvas)
		love.graphics.setShader(love.graphics.newShader([[
			vec4 effect(vec4 colour, sampler2D image, vec2 imageCoords, vec2 windowCoords) {
				vec4 texel = Texel(image, imageCoords);
				return vec4(texel.r - texel.g, 0.0, 0.0, 0.0);
			}
		]]))
		love.graphics.setCanvas(pressureCanvas)
		love.graphics.draw(start)
		love.graphics.setCanvas()
	end
	
	spaceCanvas = love.graphics.newCanvas(canvasWidth, canvasHeight, {format = "r8"})
	spaceCanvas:setWrap("clampzero")
	love.graphics.setCanvas(spaceCanvas)
	love.graphics.clear(1, 0, 0)
	if start then
		love.graphics.setShader(love.graphics.newShader([[
			vec4 effect(vec4 colour, sampler2D image, vec2 imageCoords, vec2 windowCoords) {
				return vec4(1.0 - Texel(image, imageCoords).b, 0.0, 0.0, 0.0);
			}
		]]))
		love.graphics.setCanvas(spaceCanvas)
		love.graphics.draw(start)
		love.graphics.setCanvas()
	end
	
	love.graphics.pop()
	
	viewShader = love.graphics.newShader("view.glsl")
	viewShader:send("windowSize", {love.graphics.getDimensions()})
	viewShader:send("borderSize", borderSize)
	pressureShader = love.graphics.newShader("pressure.glsl")
	outflowShader = love.graphics.newShader("outflow.glsl")
	outflowShader:send("windowSize", {canvasWidth, canvasHeight})
	paintShader = love.graphics.newShader("paint.glsl")
	paintShader:send("windowSize", {canvasWidth, canvasHeight})
end

function love.keypressed(key)
	if key == "escape" then
		paused = not paused
	elseif key == "s" then
		love.graphics.setCanvas(spaceCanvas)
		if love.keyboard.isDown("lshift") then
			love.graphics.clear(0, 0, 0)
		else
			love.graphics.clear(1, 0, 0)
		end
		love.graphics.setCanvas()
	elseif key == "p" then
		love.graphics.setCanvas(pressureCanvas)
		if love.keyboard.isDown("lshift") then
			love.graphics.clear(-1, 0, 0)
		elseif love.keyboard.isDown("lalt") then
			love.graphics.clear(1, 0, 0)
		else
			love.graphics.clear(0, 0, 0)
		end
		love.graphics.setCanvas(outflowCanvas)
		love.graphics.clear(0, 0, 0, 0)
		love.graphics.setCanvas()
	elseif key == "rshift" then
		falloff = 0
	elseif key == "/" then
		radius = 10
	elseif key == "g" then
		greyscale = not greyscale
	end
end

function love.wheelmoved(x, y)
	if love.keyboard.isDown("lshift") then
		y = y * 3
	end
	radius = math.max(radius + y, 1)
end

function love.update(dt)
	-- if love.keyboard.isDown("left") then
	-- 	damping = math.max(damping - dampingChangeRate * dt, 0)
	-- end
	-- if love.keyboard.isDown("right") then
	-- 	damping = math.min(damping + dampingChangeRate * dt, 1)
	-- end
	if love.keyboard.isDown("up") then
		falloff = math.min(falloff + falloffChangeRate * dt, maximumFalloff)
	end
	if love.keyboard.isDown("down") then
		falloff = math.max(falloff - falloffChangeRate * dt, minimumFalloff)
	end
	
	love.window.setTitle(--[=["Damping: " .. math.floor(damping * 100 * 100) / 100 .. "%, ]=] "Wabes wave simulator. Please check the code for controls. Brush Falloff: " .. math.floor((falloff < 0 and 1/(-falloff + 1) or falloff + 1) * 100) / 100 .. ", Brush Radius: " .. math.floor(radius / math.min(canvasWidth, canvasHeight) * 100 * 100) / 100 .. "% of canvas " .. (canvasWidth == canvasHeight and "size" or canvasWidth < canvasHeight and "width" or canvasHeight < canvasWidth and "height"))
	
	love.graphics.push("all")
	
	if love.mouse.isDown(1) or love.mouse.isDown(2) then
		local x, y =
			(love.mouse.getX() - borderSize) / (love.graphics.getWidth() - borderSize * 2) * canvasWidth,
			(love.mouse.getY() - borderSize) / (love.graphics.getHeight() - borderSize * 2) * canvasHeight
		paint(love.keyboard.isDown("lctrl") and "space" or "pressure", x, y, radius, love.mouse.isDown(1) and -1 or love.mouse.isDown(2) and 1, falloff)
	end
	
	
	if not paused then
		outflowShader:send("previousOutflow", outflowCanvas)
		outflowShader:send("space", spaceCanvas)
		love.graphics.setShader(outflowShader)
		love.graphics.setCanvas(outflowCanvas)
		love.graphics.draw(pressureCanvas)
		
		-- pressureShader:send("damping", damping)
		pressureShader:send("previousPressure", pressureCanvas)
		pressureShader:send("space", spaceCanvas)
		love.graphics.setCanvas(pressureCanvas)
		love.graphics.setShader(pressureShader)
		love.graphics.draw(outflowCanvas)
	end
	
	love.graphics.pop()
end

function love.draw()
	love.graphics.setShader(viewShader)
	viewShader:send("greyscale", greyscale)
	viewShader:send("space", spaceCanvas)
	local scaleX = love.graphics.getWidth() / canvasWidth
	local scaleY = love.graphics.getHeight() / canvasHeight
	love.graphics.draw(pressureCanvas, 0, 0, 0, scaleX, scaleY)
	love.graphics.setCanvas()
	love.graphics.setShader()
	love.graphics.setColor(0, 0, 1)
	if borderSize > 0 then
		-- don't bother when it's zero. the blue border marker serves no purpose
		love.graphics.rectangle("line", borderSize, borderSize, love.graphics.getWidth() - borderSize * 2, love.graphics.getHeight() - borderSize * 2)
	end
	love.graphics.setColor(1, 1, 1)
end
