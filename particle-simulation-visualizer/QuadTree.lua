local QuadTree = {}
QuadTree.__index = QuadTree

function QuadTree.new(boundary, capacity)
    local self = setmetatable({}, QuadTree)
    self.boundary = boundary
    self.capacity = capacity or 4
    self.points = {}
    self.divided = false
    self.northwest = nil
    self.northeast = nil
    self.southwest = nil
    self.southeast = nil
    return self
end

function QuadTree:insert(point)
    if not self:contains(point) then
        return false
    end

    if #self.points < self.capacity and not self.divided then
        table.insert(self.points, point)
        return true
    end

    if not self.divided then
        self:subdivide()
    end

    if self.northwest:insert(point) then return true end
    if self.northeast:insert(point) then return true end
    if self.southwest:insert(point) then return true end
    if self.southeast:insert(point) then return true end

    return false
end

function QuadTree:contains(point)
    return point.x >= self.boundary.x - self.boundary.w/2 and
           point.x < self.boundary.x + self.boundary.w/2 and
           point.y >= self.boundary.y - self.boundary.h/2 and
           point.y < self.boundary.y + self.boundary.h/2
end

function QuadTree:subdivide()
    local x = self.boundary.x
    local y = self.boundary.y
    local w = self.boundary.w / 2
    local h = self.boundary.h / 2

    local nw = {x = x - w/2, y = y - h/2, w = w, h = h}
    local ne = {x = x + w/2, y = y - h/2, w = w, h = h}
    local sw = {x = x - w/2, y = y + h/2, w = w, h = h}
    local se = {x = x + w/2, y = y + h/2, w = w, h = h}

    self.northwest = QuadTree.new(nw, self.capacity)
    self.northeast = QuadTree.new(ne, self.capacity)
    self.southwest = QuadTree.new(sw, self.capacity)
    self.southeast = QuadTree.new(se, self.capacity)

    for _, p in ipairs(self.points) do
        self.northwest:insert(p)
        self.northeast:insert(p)
        self.southwest:insert(p)
        self.southeast:insert(p)
    end
    
    self.points = {}
    self.divided = true
end

function QuadTree:query(range, found)
    found = found or {}
    
    if not self:intersects(range) then
        return found
    end
    
    for _, p in ipairs(self.points) do
        if self:pointInRange(p, range) then
            table.insert(found, p)
        end
    end
    
    if self.divided then
        self.northwest:query(range, found)
        self.northeast:query(range, found)
        self.southwest:query(range, found)
        self.southeast:query(range, found)
    end
    
    return found
end

function QuadTree:intersects(range)
    return not (range.x - range.w/2 > self.boundary.x + self.boundary.w/2 or
                range.x + range.w/2 < self.boundary.x - self.boundary.w/2 or
                range.y - range.h/2 > self.boundary.y + self.boundary.h/2 or
                range.y + range.h/2 < self.boundary.y - self.boundary.h/2)
end

function QuadTree:pointInRange(point, range)
    return point.x >= range.x - range.w/2 and
           point.x < range.x + range.w/2 and
           point.y >= range.y - range.h/2 and
           point.y < range.y + range.h/2
end

function QuadTree:clear()
    self.points = {}
    self.divided = false
    self.northwest = nil
    self.northeast = nil
    self.southwest = nil
    self.southeast = nil
end

-- Draw the QuadTree (useful for debugging)
function QuadTree:draw()
    -- Draw boundary
    love.graphics.rectangle("line", 
        self.boundary.x - self.boundary.w/2,
        self.boundary.y - self.boundary.h/2,
        self.boundary.w, self.boundary.h)
    
    -- Draw points
    for _, p in ipairs(self.points) do
        love.graphics.circle("fill", p.x, p.y, 2)
    end
    
    -- Recursively draw subdivisions
    if self.divided then
        self.northwest:draw()
        self.northeast:draw()
        self.southwest:draw()
        self.southeast:draw()
    end
end

return QuadTree