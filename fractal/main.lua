-- Recursive Evolving Fractal with LÖVE2D
-- Creates the effect of continuously descending into an endless fractal
-- New shapes constantly emerge from the center and grow outward
-- Shapes rotate around the center as they expand
-- Enhanced with animated Bezier curves that follow the shapes

-- Configuration
local maxDepth = 7           -- Maximum recursion depth
local zoomSpeed = 0.4        -- Speed of zooming effect
local evolutionSpeed = 0.3   -- Speed of shape evolution
local rotationSpeed = 0.15   -- Speed of shape self-rotation
local orbitalSpeed = 0.3     -- Speed of shapes orbiting around center
local maxShapes = 30         -- Maximum number of growing shapes to track
local bezierCurveCount = 3   -- Number of Bezier curves per shape
local bezierAmplitude = 1.2  -- How much the Bezier curves extend outward
local bezierComplexity = 0.7 -- How complex/wavy the Bezier curves are (0-1)
local bezierPoints = 20      -- Number of points to use when drawing Bezier curves

-- State variables
local time = 0
local centerX, centerY = 0, 0
local growingShapes = {}     -- Table to store shapes as they grow from center

function love.load()
    love.window.setTitle("Infinite Fractal Descent with Bezier Curves")
    love.window.setMode(800, 600, {resizable=true, vsync=true})
    
    -- Set line drawing mode to smooth
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineWidth(1.5)
    
    -- Seed the random number generator
    math.randomseed(os.time())
    
    -- Initialize center coordinates
    centerX = love.graphics.getWidth() / 2
    centerY = love.graphics.getHeight() / 2
    
    -- Initialize first shape
    addNewShape()
end

function love.update(dt)
    -- Update time for animations
    time = time + dt
    
    -- Update center coordinates if window resizes
    centerX = love.graphics.getWidth() / 2
    centerY = love.graphics.getHeight() / 2
    
    -- Add new shapes at a rate determined by zoom speed
    local shapeAddInterval = 0.8 / zoomSpeed
    if time % shapeAddInterval < dt then
        addNewShape()
    end
    
    -- Update all growing shapes
    for i = #growingShapes, 1, -1 do
        local shape = growingShapes[i]
        shape.age = shape.age + dt
        
        -- Scale grows exponentially over time
        shape.scale = math.exp(shape.age * zoomSpeed) * shape.initialScale
        
        -- Update orbital position
        shape.orbitalAngle = shape.orbitalAngle + dt * orbitalSpeed * (1.0 / (shape.scale + 0.1))
        
        -- Remove shapes that have grown too large
        if shape.scale > 15 then
            table.remove(growingShapes, i)
        end
    end
end

function love.draw()
    -- Clear the screen with a dark background
    love.graphics.setBackgroundColor(0.02, 0.02, 0.06)
    
    -- Draw all growing shapes from oldest (largest) to newest (smallest)
    for i = 1, #growingShapes do
        local shape = growingShapes[i]
        drawEvolvingFractal(shape)
    end
    
    -- Display instructions
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print("Up/Down: Change depth (" .. maxDepth .. ")", 10, 10)
    love.graphics.print("Left/Right: Change zoom speed (" .. string.format("%.1f", zoomSpeed) .. ")", 10, 30)
    love.graphics.print("Z/X: Evolution speed (" .. string.format("%.1f", evolutionSpeed) .. ")", 10, 50)
    love.graphics.print("A/S: Orbital speed (" .. string.format("%.1f", orbitalSpeed) .. ")", 10, 70)
    love.graphics.print("B/N: Bezier complexity (" .. string.format("%.1f", bezierComplexity) .. ")", 10, 90)
    love.graphics.print("J/K: Bezier amplitude (" .. string.format("%.1f", bezierAmplitude) .. ")", 10, 110)
end

function addNewShape()
    -- Limit total number of shapes to prevent performance issues
    if #growingShapes >= maxShapes then
        table.remove(growingShapes, 1)  -- Remove oldest shape
    end
    
    -- Create a new shape at the center with a tiny initial scale
    local shape = {
        birthTime = time,
        age = 0,
        initialScale = 0.01,
        scale = 0.01,
        evolutionOffset = math.random() * 10,  -- Random starting point in evolution cycle
        rotationOffset = math.random() * math.pi * 2,  -- Random rotation
        orbitalAngle = math.random() * math.pi * 2,  -- Random initial orbital position
        orbitalRadius = 0,  -- Starts at center
        orbitalDirection = (math.random() > 0.5) and 1 or -1,  -- Random direction
        bezierOffsets = {}  -- Store random offsets for Bezier curves
    }
    
    -- Generate random offsets for Bezier curves
    for i = 1, bezierCurveCount do
        shape.bezierOffsets[i] = {
            angle = math.random() * math.pi * 2,
            phase = math.random() * math.pi * 2,
            speed = 0.5 + math.random() * 0.5
        }
    end
    
    table.insert(growingShapes, shape)
end

function drawEvolvingFractal(shape)
    -- Base size for the outermost shape
    local baseSize = 100 * shape.scale
    
    -- Calculate orbital radius based on scale
    -- Shapes start at center and orbit outward as they grow
    local orbitalRadius = shape.scale * 20
    
    -- Calculate position based on orbital angle and radius
    local posX = centerX + math.cos(shape.orbitalAngle * shape.orbitalDirection) * orbitalRadius
    local posY = centerY + math.sin(shape.orbitalAngle * shape.orbitalDirection) * orbitalRadius
    
    -- Calculate alpha based on scale (fade out as it gets very large)
    local alpha = math.min(1, math.max(0, 1.5 - shape.scale / 10))
    
    -- Draw the recursive fractal
    drawRecursiveFractal(posX, posY, baseSize, 0, shape.birthTime, shape.evolutionOffset, 
                         shape.rotationOffset, shape.orbitalAngle, alpha, shape)
end

function drawRecursiveFractal(x, y, size, depth, birthTime, evolutionOffset, rotationOffset, orbitalAngle, alpha, shape)
    -- Stop recursion if we've reached max depth
    if depth >= maxDepth then
        return
    end
    
    -- Calculate evolving time-based parameters
    local evolutionTime = time * evolutionSpeed + depth * 0.5 + evolutionOffset
    
    -- Calculate color based on depth and evolution
    local hue = (evolutionTime * 0.1 + depth * 0.15) % 1
    local saturation = 0.7 + 0.3 * math.sin(evolutionTime * 0.3)
    local brightness = 0.8 + 0.2 * math.sin(evolutionTime * 0.5)
    local r, g, b = HSVtoRGB(hue, saturation, brightness)
    
    -- Set color with depth-based fading
    local depthAlpha = alpha * (1 - depth/maxDepth * 0.5)
    love.graphics.setColor(r, g, b, depthAlpha)
    
    -- Calculate shape parameters
    local shapeEvolution = math.sin(evolutionTime) * 0.5 + 0.5  -- 0 to 1
    
    -- Combine self-rotation and orbital rotation for a more complex effect
    local rotationAngle = evolutionTime * rotationSpeed + rotationOffset + orbitalAngle * 0.5
    
    -- Draw evolving shape
    drawEvolvingShape(x, y, size, shapeEvolution, rotationAngle)
    
    -- Draw Bezier curves - only at the first few depth levels to avoid clutter
    if depth < 3 and shape then
        drawBezierCurves(x, y, size, rotationAngle, evolutionTime, depthAlpha, shape, depth)
    end
    
    -- Calculate number of branches (evolving between 3 and 6)
    local branchCount = math.floor(3 + 3 * (0.5 + 0.5 * math.sin(evolutionTime * 0.7)))
    
    -- Create branches
    for i = 1, branchCount do
        -- Calculate position for the next fractal element
        local branchAngle = rotationAngle + (i * (2 * math.pi / branchCount))
        
        -- Distance changes with evolution
        local distance = size * (0.55 + 0.15 * math.sin(evolutionTime * 0.4))
        
        -- Calculate new coordinates
        local newX = x + math.cos(branchAngle) * distance
        local newY = y + math.sin(branchAngle) * distance
        
        -- Scale factor also evolves
        local scaleFactor = 0.4 + 0.15 * math.sin(evolutionTime * 0.3)
        
        -- Recurse with smaller size
        drawRecursiveFractal(newX, newY, size * scaleFactor, depth + 1, birthTime, 
                            evolutionOffset + depth, rotationOffset, orbitalAngle, alpha, shape)
    end
end

-- Function to get a point on a cubic Bezier curve at time t (0-1)
function cubicBezier(x1, y1, x2, y2, x3, y3, x4, y4, t)
    local t1 = 1 - t
    local t2 = t1 * t1
    local t3 = t2 * t1
    
    local mt = t * t
    local mt2 = mt * t
    
    local x = t3 * x1 + 3 * t2 * t * x2 + 3 * t1 * mt * x3 + mt2 * x4
    local y = t3 * y1 + 3 * t2 * t * y2 + 3 * t1 * mt * y3 + mt2 * y4
    
    return x, y
end

function drawBezierCurves(x, y, size, rotationAngle, evolutionTime, alpha, shape, depth)
    -- Draw flowing Bezier curves that move with the shape
    love.graphics.setLineWidth(1 + 0.5 * (1 - depth / 3))
    
    -- Adjust color for Bezier curves - slightly different from the shape color
    local hue = ((evolutionTime * 0.1 + depth * 0.15) + 0.5) % 1
    local saturation = 0.8 + 0.2 * math.sin(evolutionTime * 0.3)
    local brightness = 0.9 + 0.1 * math.sin(evolutionTime * 0.5)
    local r, g, b = HSVtoRGB(hue, saturation, brightness)
    love.graphics.setColor(r, g, b, alpha * 0.7)
    
    for i = 1, bezierCurveCount do
        -- Get stored offsets for this curve
        local offset = shape.bezierOffsets[i]
        
        -- Calculate a time-varying angle based on initial offset
        local curveAngle = rotationAngle + offset.angle + math.sin(evolutionTime * offset.speed + offset.phase) * math.pi
        
        -- Calculate radius based on size and make it vary slightly with time
        local radius = size * (1 + 0.2 * math.sin(evolutionTime * 0.7 + offset.phase))
        
        -- Calculate start and end points
        local startAngle = curveAngle
        local endAngle = curveAngle + math.pi * (1 + 0.3 * math.sin(evolutionTime * 0.4))
        
        local x1 = x + math.cos(startAngle) * radius * 0.7
        local y1 = y + math.sin(startAngle) * radius * 0.7
        local x4 = x + math.cos(endAngle) * radius * 0.7
        local y4 = y + math.sin(endAngle) * radius * 0.7
        
        -- Calculate control points with more dramatic curves
        local ctrlDistanceFactor = radius * bezierAmplitude * (1 + 0.3 * math.sin(evolutionTime * 0.6 + i))
        local complexity = bezierComplexity * (1 + 0.3 * math.sin(evolutionTime * 0.3 + i * 0.5))
        
        local ctrlAngle1 = startAngle + math.pi/2 * complexity
        local ctrlAngle2 = endAngle - math.pi/2 * complexity
        
        local x2 = x1 + math.cos(ctrlAngle1) * ctrlDistanceFactor
        local y2 = y1 + math.sin(ctrlAngle1) * ctrlDistanceFactor
        local x3 = x4 + math.cos(ctrlAngle2) * ctrlDistanceFactor
        local y3 = y4 + math.sin(ctrlAngle2) * ctrlDistanceFactor
        
        -- Draw the Bezier curve using points
        local points = {}
        for j = 0, bezierPoints do
            local t = j / bezierPoints
            local bx, by = cubicBezier(x1, y1, x2, y2, x3, y3, x4, y4, t)
            table.insert(points, bx)
            table.insert(points, by)
        end
        
        -- Draw the curve as a line
        love.graphics.line(points)
    end
    
    -- Reset line width
    love.graphics.setLineWidth(1.5)
end

function drawEvolvingShape(x, y, size, evolutionFactor, rotation)
    -- Evolution factor determines the shape type
    if evolutionFactor < 0.2 then
        -- Circle to Triangle
        local morph = evolutionFactor / 0.2  -- 0 to 1
        drawMorphedShape(x, y, size, 24, 3, morph, rotation)
    elseif evolutionFactor < 0.4 then
        -- Triangle to Square
        local morph = (evolutionFactor - 0.2) / 0.2  -- 0 to 1
        drawMorphedShape(x, y, size, 3, 4, morph, rotation)
    elseif evolutionFactor < 0.6 then
        -- Square to Pentagon
        local morph = (evolutionFactor - 0.4) / 0.2  -- 0 to 1
        drawMorphedShape(x, y, size, 4, 5, morph, rotation)
    elseif evolutionFactor < 0.8 then
        -- Pentagon to Hexagon
        local morph = (evolutionFactor - 0.6) / 0.2  -- 0 to 1
        drawMorphedShape(x, y, size, 5, 6, morph, rotation)
    else
        -- Hexagon to Star and back towards circle
        local morph = (evolutionFactor - 0.8) / 0.2  -- 0 to 1
        drawStar(x, y, size, 6, rotation, morph)
    end
end

function drawMorphedShape(x, y, radius, sides1, sides2, morphFactor, rotation)
    -- Draw a shape morphing between two different polygon types
    local vertices = {}
    local sides = math.max(sides1, sides2)
    
    for i = 1, sides do
        -- For additional sides during morphing, gradually fade them in
        local opacity = (i <= sides1) and 1 or morphFactor
        
        -- Calculate morphing radius for star-like effects
        local vertexRadius = radius
        if sides1 == 24 and sides2 == 3 and i % 3 ~= 0 then
            -- When morphing from circle to triangle, adjust non-triangle points
            vertexRadius = radius * (1 - 0.5 * morphFactor)
        end
        
        -- Calculate angle with rotation
        local angle = rotation + (i * 2 * math.pi / sides)
        
        -- Add vertex if it's visible
        if i <= sides and opacity > 0 then
            table.insert(vertices, x + vertexRadius * math.cos(angle))
            table.insert(vertices, y + vertexRadius * math.sin(angle))
        end
    end
    
    -- Draw the polygon
    love.graphics.polygon("line", vertices)
end

function drawStar(x, y, radius, points, rotation, intensity)
    -- Draw a star shape with adjustable pointiness
    local vertices = {}
    
    for i = 1, points * 2 do
        -- Alternate between outer and inner radius
        local r = (i % 2 == 0) and radius or radius * (0.5 - 0.3 * intensity)
        local angle = rotation + (i * math.pi / points)
        
        table.insert(vertices, x + r * math.cos(angle))
        table.insert(vertices, y + r * math.sin(angle))
    end
    
    love.graphics.polygon("line", vertices)
end

-- Convert HSV color to RGB
function HSVtoRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    
    return r, g, b
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "up" then
        maxDepth = math.min(maxDepth + 1, 10)
    elseif key == "down" then
        maxDepth = math.max(maxDepth - 1, 3)
    elseif key == "right" then
        zoomSpeed = math.min(zoomSpeed + 0.1, 2.0)
    elseif key == "left" then
        zoomSpeed = math.max(zoomSpeed - 0.1, 0.1)
    elseif key == "z" then
        evolutionSpeed = math.max(evolutionSpeed - 0.1, 0.1)
    elseif key == "x" then
        evolutionSpeed = math.min(evolutionSpeed + 0.1, 2.0)
    elseif key == "a" then
        orbitalSpeed = math.max(orbitalSpeed - 0.1, 0.1)
    elseif key == "s" then
        orbitalSpeed = math.min(orbitalSpeed + 0.1, 2.0)
    elseif key == "b" then
        bezierComplexity = math.max(bezierComplexity - 0.1, 0.1)
    elseif key == "n" then
        bezierComplexity = math.min(bezierComplexity + 0.1, 2.0)
    elseif key == "j" then
        bezierAmplitude = math.max(bezierAmplitude - 0.1, 0.1)
    elseif key == "k" then
        bezierAmplitude = math.min(bezierAmplitude + 0.2, 3.0)
    end
end