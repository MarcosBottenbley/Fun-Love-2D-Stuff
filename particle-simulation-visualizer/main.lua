local QuadTree = require('QuadTree')

local particles = {}
local particleCount = 500
local particleRadius = 3
local width, height
local quadtree
local gravity = 0.1
local repulsionStrength = 5
local dragCoefficient = 0.98

-- Audio analysis variables
local audioSource
local audioData
local samplePoints = 256
local audioAmplitudes = {}
local bassEnergy = 0
local midEnergy = 0
local trebleEnergy = 0
local beatDetected = false
local beatTimer = 0
local beatCooldown = 0.1
local audioResponsive = true

-- Particle types
local PARTICLE_TYPES = {
    BASS = 1,
    MID = 2,
    TREBLE = 3
}

-- Initialize with some default values
for i = 1, samplePoints do
    audioAmplitudes[i] = 0
end

function love.load()
    width, height = love.graphics.getDimensions()
    
    -- Create a boundary for the quadtree (centered, full screen)
    local boundary = {
        x = width / 2,
        y = height / 2,
        w = width,
        h = height
    }
    
    -- Initialize the quadtree
    quadtree = QuadTree.new(boundary, 8)
    
    -- Create particles
    for i = 1, particleCount do
        -- Randomly assign particle type with equal probability
        local particleType = math.random(1, 3)
        
        -- Define base color based on type
        local color = {r = 0, g = 0, b = 0}
        if particleType == PARTICLE_TYPES.BASS then
            color = {r = 0.8, g = 0.2, b = 0.2} -- Red for bass
        elseif particleType == PARTICLE_TYPES.MID then
            color = {r = 0.2, g = 0.8, b = 0.2} -- Green for mid
        else -- TREBLE
            color = {r = 0.2, g = 0.2, b = 0.8} -- Blue for treble
        end
        
        local particle = {
            x = math.random(width),
            y = math.random(height),
            vx = (math.random() - 0.5) * 2,
            vy = (math.random() - 0.5) * 2,
            radius = particleRadius,
            mass = math.random(1, 4),
            color = color,
            originalColor = {r = color.r, g = color.g, b = color.b},
            type = particleType,
            originalRadius = particleRadius + (math.random(1, 4) - 1),
            floorY = height - 50 + math.random(50), -- Random floor level for each particle
            bounceEnergy = 0,
            bounceHeight = 0
        }
        table.insert(particles, particle)
    end
    
    -- Try to load a music file
    local success = false
    
    -- Try to load a sample music file if present
    local musicFiles = {"music.mp3", "music.ogg", "music.wav"}
    for _, file in ipairs(musicFiles) do
        if love.filesystem.getInfo(file) then
            audioSource = love.audio.newSource(file, "stream")
            audioSource:setLooping(true)
            audioSource:play()
            success = true
            print("Loaded music file: " .. file)
            break
        end
    end
    
    if not success then
        -- Since we can't directly capture system audio output in LÖVE without extra libraries,
        -- we'll use simulated audio data
        print("No music file found. Using simulated audio.")
        audioResponsive = true
    end
end

-- Function to simulate audio analysis
function updateAudio(dt)
    if not audioResponsive then return end
    
    beatTimer = beatTimer + dt
    
    -- Check if we're using a music file
    if audioSource and audioSource:type() == "Source" then
        -- Get audio data from the currently playing music
        -- We're simulating frequency analysis by sampling at various points
        local sampleRate = 44100
        local currentPos = audioSource:tell("samples")
        
        -- Create temporary storage for our samples
        local tempBass = 0
        local tempMid = 0
        local tempTreble = 0
        local sampleCount = 0
        
        -- Sample 256 points from current playback position
        for i = 0, samplePoints-1 do
            local pos = currentPos - samplePoints + i
            if pos > 0 then
                -- Simulate different frequency bands based on the sample position
                local amplitude = math.abs(love.math.noise(pos/1000) * 2 - 1) * audioSource:getVolume()
                audioAmplitudes[i+1] = amplitude
                
                -- Assign different parts of our sample to "frequency bands"
                if i < samplePoints/3 then
                    tempBass = tempBass + amplitude
                elseif i < 2*samplePoints/3 then
                    tempMid = tempMid + amplitude
                else
                    tempTreble = tempTreble + amplitude
                end
                sampleCount = sampleCount + 1
            end
        end
        
        -- Calculate averages for each band
        if sampleCount > 0 then
            bassEnergy = tempBass / (samplePoints/3)
            midEnergy = tempMid / (samplePoints/3)
            trebleEnergy = tempTreble / (samplePoints/3)
        end
        
        -- Detect beats (primarily from bass)
        if bassEnergy > 0.5 and beatTimer > beatCooldown then
            beatDetected = true
            beatTimer = 0
        else
            beatDetected = false
        end
    else
        -- Simulate audio data based on time
        local time = love.timer.getTime()
        
        -- Generate some dynamic values for our "audio" data with enhanced bass variation
        -- Use a combination of sine waves for more dynamic bass patterns
        bassEnergy = (math.sin(time * 2) + 1) / 2
        -- Add a faster secondary oscillation for more variation
        bassEnergy = bassEnergy * 0.7 + ((math.sin(time * 4.5) + 1) / 2) * 0.3
        -- Add occasional stronger peaks for bass
        if math.sin(time * 0.8) > 0.7 then
            bassEnergy = math.min(1.0, bassEnergy * 1.3)
        end
        
        midEnergy = (math.sin(time * 3 + 1) + 1) / 2
        trebleEnergy = (math.sin(time * 5 + 2) + 1) / 2
        
        -- Generate waveform display
        for i = 1, samplePoints do
            audioAmplitudes[i] = math.abs(math.sin(time * 4 + i/20) * math.cos(time + i/10)) * 0.5
        end
        
        -- Generate beats
        if math.sin(time * 1.5) > 0.7 and beatTimer > beatCooldown then
            beatDetected = true
            beatTimer = 0
        else
            beatDetected = false
        end
    end
    
    -- Apply smoothing to our energy values
    bassEnergy = math.min(1, bassEnergy)
    midEnergy = math.min(1, midEnergy)
    trebleEnergy = math.min(1, trebleEnergy)
end

function love.update(dt)
    -- Limit dt to prevent simulation explosion on lag
    dt = math.min(dt, 0.05)
    
    -- Update audio analysis
    updateAudio(dt)
    
    -- Clear the quadtree
    quadtree:clear()
    
    -- Insert all particles into the quadtree
    for _, particle in ipairs(particles) do
        quadtree:insert(particle)
    end
    
    -- Update each particle
    for i, particle in ipairs(particles) do
        -- Apply bounce based on audio energy
        if audioResponsive then
            -- Different particle types respond to different frequency bands
            local targetBounceEnergy = 0
            
            if particle.type == PARTICLE_TYPES.BASS then
                -- Bass particles bounce with bass (increased reactivity)
                targetBounceEnergy = bassEnergy * 25
                -- Make bass particles also slightly react to mid frequencies for more dynamics
                targetBounceEnergy = targetBounceEnergy + (midEnergy * 5)
            elseif particle.type == PARTICLE_TYPES.MID then
                -- Mid particles bounce with mid frequencies
                targetBounceEnergy = midEnergy * 10
            else -- TREBLE
                -- Treble particles bounce with treble frequencies
                targetBounceEnergy = trebleEnergy * 7
            end
            
            -- On beat, give an extra bounce impulse
            if beatDetected then
                if particle.type == PARTICLE_TYPES.BASS then
                    -- Significantly increase bass particle response to beats
                    targetBounceEnergy = targetBounceEnergy + 20
                elseif particle.type == PARTICLE_TYPES.MID then
                    targetBounceEnergy = targetBounceEnergy + 7
                else -- TREBLE
                    targetBounceEnergy = targetBounceEnergy + 5
                end
            end
            
            -- Adjust bounce energy smoothing based on particle type
            if particle.type == PARTICLE_TYPES.BASS then
                -- Make bass particles respond faster to changes
                particle.bounceEnergy = particle.bounceEnergy * 0.8 + targetBounceEnergy * 0.2
            else
                -- Keep original smoothing for other particles
                particle.bounceEnergy = particle.bounceEnergy * 0.95 + targetBounceEnergy * 0.05
            end
            
            -- Calculate bounce height based on energy (this will modify y position)
            particle.bounceHeight = particle.bounceEnergy * particle.mass
            
            -- If particle is at the floor and has bounce energy, give it upward velocity
            if particle.y >= particle.floorY - particle.radius and particle.vy >= 0 then
                if particle.bounceEnergy > 0.5 then
                    -- Apply an impulse proportional to the bounce energy
                    particle.vy = -particle.bounceEnergy * 0.5 * particle.mass
                end
            end
        end
        
        -- Apply gravity
        particle.vy = particle.vy + gravity * particle.mass * dt * 60
        
        -- Apply drag
        particle.vx = particle.vx * dragCoefficient
        particle.vy = particle.vy * dragCoefficient
        
        -- Update position
        particle.x = particle.x + particle.vx * dt * 60
        particle.y = particle.y + particle.vy * dt * 60
        
        -- Check for collisions using quadtree
        local range = {
            x = particle.x,
            y = particle.y,
            w = particle.radius * 4,
            h = particle.radius * 4
        }
        
        local neighbors = quadtree:query(range)
        
        -- Handle collisions with other particles
        for _, other in ipairs(neighbors) do
            if other ~= particle then
                local dx = other.x - particle.x
                local dy = other.y - particle.y
                local distance = math.sqrt(dx*dx + dy*dy)
                local minDist = particle.radius + other.radius
                
                if distance < minDist then
                    -- Calculate collision response
                    local angle = math.atan2(dy, dx)
                    local overlap = minDist - distance
                    
                    -- Separate particles
                    local moveX = math.cos(angle) * overlap * 0.5
                    local moveY = math.sin(angle) * overlap * 0.5
                    
                    -- Adjust positions to prevent overlap
                    other.x = other.x + moveX
                    other.y = other.y + moveY
                    particle.x = particle.x - moveX
                    particle.y = particle.y - moveY
                    
                    -- Calculate repulsion force
                    local repulsion = repulsionStrength / (distance + 1)
                    local repulsionX = math.cos(angle) * repulsion
                    local repulsionY = math.sin(angle) * repulsion
                    
                    -- Apply repulsion force based on mass
                    particle.vx = particle.vx - repulsionX / particle.mass
                    particle.vy = particle.vy - repulsionY / particle.mass
                    other.vx = other.vx + repulsionX / other.mass
                    other.vy = other.vy + repulsionY / other.mass
                end
            end
        end
        
        -- Handle wall collisions
        if particle.x - particle.radius < 0 then
            particle.x = particle.radius
            particle.vx = -particle.vx * 0.8
        elseif particle.x + particle.radius > width then
            particle.x = width - particle.radius
            particle.vx = -particle.vx * 0.8
        end
        
        -- Floor collision (different for each particle)
        if particle.y + particle.radius > particle.floorY then
            particle.y = particle.floorY - particle.radius
            particle.vy = -particle.vy * 0.5  -- Reduce bounce energy after collision
        end
        
        -- Ceiling collision
        if particle.y - particle.radius < 0 then
            particle.y = particle.radius
            particle.vy = -particle.vy * 0.8
        end
    end
end

function love.draw()
    -- Background color pulse with beat
    local bgIntensity = 0.05
    if audioResponsive and beatDetected then
        bgIntensity = 0.15
    end
    love.graphics.setBackgroundColor(bgIntensity, bgIntensity, bgIntensity)
    
    -- Draw floor lines for each particle type
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", 0, height - 50, width, 50)
    
    -- Draw all particles
    for _, particle in ipairs(particles) do
        -- Adjust color intensity for bass particles based on bass energy
        local r, g, b = particle.color.r, particle.color.g, particle.color.b
        local particleSize = particle.radius
        
        if particle.type == PARTICLE_TYPES.BASS then
            -- Intensify red color based on bass energy and beats
            local intensityMultiplier = 1 + (bassEnergy * 0.5)
            if beatDetected then intensityMultiplier = intensityMultiplier + 0.5 end
            
            r = math.min(1.0, r * intensityMultiplier)
            
            -- Dynamic particle size for bass particles
            local sizeMultiplier = 1 + (particle.bounceEnergy * 0.05)
            particleSize = particle.radius * sizeMultiplier
        end
        
        -- Draw particle with potentially modified color and size
        love.graphics.setColor(r, g, b)
        love.graphics.circle("fill", particle.x, particle.y, particleSize)
        
        -- Draw a small border
        love.graphics.setColor(r * 0.7, g * 0.7, b * 0.7)
        love.graphics.circle("line", particle.x, particle.y, particleSize)
        
        -- Draw a small indicator line to show particle's floor level
        love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, 0.1)
        love.graphics.line(particle.x - particle.radius, particle.floorY, 
                          particle.x + particle.radius, particle.floorY)
    end
    
    -- Draw quadtree for visualization (optional)
    if love.keyboard.isDown("q") then
        love.graphics.setColor(1, 1, 1, 0.3)
        quadtree:draw()
    end
    
    -- Display audio visualization
    if audioResponsive then
        -- Draw audio spectrum
        love.graphics.setColor(0.8, 0.2, 0.2, 0.7) -- Red for bass
        love.graphics.rectangle("fill", 10, height - 120, 30, 100 * bassEnergy)
        
        love.graphics.setColor(0.2, 0.8, 0.2, 0.7) -- Green for mid
        love.graphics.rectangle("fill", 50, height - 120, 30, 100 * midEnergy)
        
        love.graphics.setColor(0.2, 0.2, 0.8, 0.7) -- Blue for treble
        love.graphics.rectangle("fill", 90, height - 120, 30, 100 * trebleEnergy)
        
        -- Draw audio waveform
        love.graphics.setColor(0.5, 0.8, 1, 0.5)
        for i = 1, #audioAmplitudes-1 do
            local x1 = 150 + i
            local y1 = height - 70 - audioAmplitudes[i] * 50
            local x2 = 150 + i + 1
            local y2 = height - 70 - audioAmplitudes[i+1] * 50
            love.graphics.line(x1, y1, x2, y2)
        end
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Bass", 10, height - 130)
        love.graphics.print("Mid", 50, height - 130)
        love.graphics.print("Treble", 90, height - 130)
        
        -- Beat indicator
        if beatDetected then
            love.graphics.setColor(1, 0.2, 0.2)
            love.graphics.circle("fill", 150, height - 80, 10)
        end
    end
    
    -- Display particle type legend
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.circle("fill", width - 100, 20, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Bass", width - 80, 15)
    
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.circle("fill", width - 100, 40, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Mid", width - 80, 35)
    
    love.graphics.setColor(0.2, 0.2, 0.8)
    love.graphics.circle("fill", width - 100, 60, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Treble", width - 80, 55)
    
    -- Display FPS and particle count
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
    love.graphics.print("Particles: " .. particleCount, 10, 30)
    love.graphics.print("Press 'q' to show/hide quadtree", 10, 50)
    love.graphics.print("Press space to add more particles", 10, 70)
    love.graphics.print("Press 'r' to reset simulation", 10, 90)
    love.graphics.print("Press 'a' to toggle audio response: " .. (audioResponsive and "ON" or "OFF"), 10, 110)
    love.graphics.print("Press '1/2/3' to add bass/mid/treble particles", 10, 130)
    
    if not audioSource then
        love.graphics.setColor(1, 0.5, 0.5)
        love.graphics.print("Place a music.mp3 file in the game directory for real audio response", 10, height - 50)
        love.graphics.print("Currently using simulated audio data", 10, height - 30)
    end
end

function love.keypressed(key)
    if key == "space" then
        -- Add mixed particles
        for i = 1, 50 do
            local particleType = math.random(1, 3)
            local color = {r = 0, g = 0, b = 0}
            
            if particleType == PARTICLE_TYPES.BASS then
                color = {r = 0.8, g = 0.2, b = 0.2}
            elseif particleType == PARTICLE_TYPES.MID then
                color = {r = 0.2, g = 0.8, b = 0.2}
            else -- TREBLE
                color = {r = 0.2, g = 0.2, b = 0.8}
            end
            
            local particle = {
                x = love.mouse.getX(),
                y = love.mouse.getY(),
                vx = (math.random() - 0.5) * 5,
                vy = (math.random() - 0.5) * 5,
                radius = particleRadius,
                mass = math.random(1, 4),
                color = color,
                originalColor = {r = color.r, g = color.g, b = color.b},
                type = particleType,
                originalRadius = particleRadius + (math.random(1, 4) - 1),
                floorY = height - 50 + math.random(50),
                bounceEnergy = 0,
                bounceHeight = 0
            }
            table.insert(particles, particle)
        end
        particleCount = particleCount + 50
    elseif key == "1" then
        -- Add bass particles
        for i = 1, 20 do
            local color = {r = 0.8, g = 0.2, b = 0.2}
            local particle = {
                x = love.mouse.getX() + (math.random() - 0.5) * 40,
                y = love.mouse.getY() + (math.random() - 0.5) * 40,
                vx = (math.random() - 0.5) * 5,
                vy = (math.random() - 0.5) * 5,
                radius = particleRadius,
                mass = math.random(2, 4), -- Bass particles are heavier
                color = color,
                originalColor = {r = color.r, g = color.g, b = color.b},
                type = PARTICLE_TYPES.BASS,
                originalRadius = particleRadius + 2,
                floorY = height - 50 + math.random(50),
                bounceEnergy = 0,
                bounceHeight = 0
            }
            table.insert(particles, particle)
        end
        particleCount = particleCount + 20
    elseif key == "2" then
        -- Add mid particles
        for i = 1, 20 do
            local color = {r = 0.2, g = 0.8, b = 0.2}
            local particle = {
                x = love.mouse.getX() + (math.random() - 0.5) * 40,
                y = love.mouse.getY() + (math.random() - 0.5) * 40,
                vx = (math.random() - 0.5) * 5,
                vy = (math.random() - 0.5) * 5,
                radius = particleRadius,
                mass = math.random(1, 3), -- Mid particles are average weight
                color = color,
                originalColor = {r = color.r, g = color.g, b = color.b},
                type = PARTICLE_TYPES.MID,
                originalRadius = particleRadius + 1,
                floorY = height - 50 + math.random(50),
                bounceEnergy = 0,
                bounceHeight = 0
            }
            table.insert(particles, particle)
        end
        particleCount = particleCount + 20
    elseif key == "3" then
        -- Add treble particles
        for i = 1, 20 do
            local color = {r = 0.2, g = 0.2, b = 0.8}
            local particle = {
                x = love.mouse.getX() + (math.random() - 0.5) * 40,
                y = love.mouse.getY() + (math.random() - 0.5) * 40,
                vx = (math.random() - 0.5) * 5,
                vy = (math.random() - 0.5) * 5,
                radius = particleRadius,
                mass = math.random(1, 2), -- Treble particles are lighter
                color = color,
                originalColor = {r = color.r, g = color.g, b = color.b},
                type = PARTICLE_TYPES.TREBLE,
                originalRadius = particleRadius,
                floorY = height - 50 + math.random(50),
                bounceEnergy = 0,
                bounceHeight = 0
            }
            table.insert(particles, particle)
        end
        particleCount = particleCount + 20
    elseif key == "r" then
        -- Reset simulation
        particles = {}
        particleCount = 0
        love.load()
    elseif key == "a" then
        -- Toggle audio responsiveness
        audioResponsive = not audioResponsive
    end
end

function love.quit()
    -- Cleanup when exiting
    if audioSource then
        audioSource:stop()
    end
end