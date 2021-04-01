map = {
    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    { 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    { 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    { 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    { 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    { 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    { 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    { 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

map_width = #map
map_height = #map[1]
fov = 60
tile_size = 64
proj_width = 320
proj_height = 200
dist_to_proj = 277 -- proj_width / 2 / math.tan(math.rad(fov / 2))
fov_side_length = 320  -- dist_to_proj / math.cos(math.rad(fov / 2))

player_x = 4 * 64 + 30
player_y = 1 * 64 + 32
player_height = 32
player_viewing_angle = 198

brick_texture = nil

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest', 1)
    love.window.setMode(1280, 800, {resizable = false, vsync = true, highdpi = true})

    minimap = love.graphics.newCanvas(1280, 800)
    minimap:setFilter("nearest", "nearest")

    world = love.graphics.newCanvas(320, 200)
    world:setFilter("nearest", "nearest")

    brick_texture = love.graphics.newImage('bricksx64.png')
end

function draw_minimap()
    love.graphics.setCanvas(minimap)
    love.graphics.clear()

    for i, v in ipairs(map) do
        for j, v2 in ipairs(v) do
            love.graphics.setColor(1, 1, 1, 0.1)
            love.graphics.line(0, (j - 1) * 64, (map_width - 1) * 64, (j - 1) * 64)

            if map[i][j] == 1 then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.rectangle('fill', (i - 1) * 64, (j - 1) * 64, 64, 64)
            end
        end
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.line((i - 1) * 64, 0, (i - 1) * 64, (map_height - 1) * 64)
    end

    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.rectangle('fill', player_x - 5, player_y - 5, 10, 10);
    love.graphics.line(player_x, player_y,
                       player_x + dist_to_proj * math.cos(math.rad(player_viewing_angle)),
                       player_y - dist_to_proj * math.sin(math.rad(player_viewing_angle)))
    love.graphics.line(player_x, player_y,
                       player_x + fov_side_length * math.cos(math.rad(player_viewing_angle + fov / 2)),
                       player_y - fov_side_length * math.sin(math.rad(player_viewing_angle + fov / 2)))
    love.graphics.line(player_x, player_y,
                       player_x + fov_side_length * math.cos(math.rad(player_viewing_angle - fov / 2)),
                       player_y - fov_side_length * math.sin(math.rad(player_viewing_angle - fov / 2)))
    love.graphics.line(player_x + fov_side_length * math.cos(math.rad(player_viewing_angle + fov / 2)),
                       player_y - fov_side_length * math.sin(math.rad(player_viewing_angle + fov / 2)),
                       player_x + fov_side_length * math.cos(math.rad(player_viewing_angle - fov / 2)),
                       player_y - fov_side_length * math.sin(math.rad(player_viewing_angle - fov / 2)))

    love.graphics.setCanvas()
end

function love.update(dt)
    -- player_viewing_angle = player_viewing_angle + 90 * dt
    if love.keyboard.isDown("a") then
        player_viewing_angle = player_viewing_angle + 60 * dt
    elseif love.keyboard.isDown("d") then
        player_viewing_angle = player_viewing_angle - 60 * dt
    end

    if love.keyboard.isDown("w") then
        player_x = player_x + 128 * math.cos(math.rad(player_viewing_angle)) * dt
        player_y = player_y - 128 * math.sin(math.rad(player_viewing_angle)) * dt
    elseif love.keyboard.isDown("s") then
        player_x = player_x - 128 * math.cos(math.rad(player_viewing_angle)) * dt
        player_y = player_y + 128 * math.sin(math.rad(player_viewing_angle)) * dt
    end
end

function draw_world()
    love.graphics.setCanvas(world)
    love.graphics.clear()

    for i = 0, 100 do
        love.graphics.setColor(0.01 * i / 2, 0.005 * i / 2, 0.005 * i / 2);
        love.graphics.line(0, 100 - i, 320, 100 - i)
        love.graphics.line(0, 100 + i, 320, 100 + i)
    end

    for i = 0, 320 do
        local angle = fov / 2 - i * fov / 320

        local x, y, dist, horizontal_boundary = raycast(angle)

        if dist < math.huge then
            correct_dist = dist * math.cos(math.rad(angle))
            projected_wall_height = math.floor(64 / correct_dist * dist_to_proj + 0.5)

            local texture_offset = math.fmod(y, 64)
            if horizontal_boundary then
                texture_offset = math.fmod(x, 64)
            end

            -- Add very basic shading
            local color = 1 - dist / 400
            if color < 0.1 then
                color = 0.1
            end
            if color > 1 then
                color = 1
            end
            love.graphics.setColor(color, color, color, 1)
            -- love.graphics.setColor(0, 1, 1, 1)
            -- love.graphics.line(i, 100 - projected_wall_height * 0.5, i, 100 + projected_wall_height * 0.5)
            local quad = love.graphics.newQuad(texture_offset, 0, 1, 64, brick_texture)
            local transfrom = love.math.newTransform(i, 100 - projected_wall_height / 2, 0,
                                                     1, projected_wall_height / 64)
            love.graphics.draw(brick_texture, quad, transfrom)
        end
    end
    love.graphics.setCanvas()
end

function raycast(angle)
    love.graphics.setCanvas(minimap)
    local alpha = wrap_angle(player_viewing_angle + angle)

    local ray_going_up = true
    if alpha > 180 and alpha < 360 then
        ray_going_up = false
    end
    local ray_going_right = true
    if alpha > 90 and alpha < 270 then
        ray_going_right = false
    end

    local tile_x = math.floor(player_x / tile_size)
    local tile_y = math.floor(player_y / tile_size)

    -- Detect intersection with vertical grid lines
    local vertical_x = tile_x * tile_size
    local vertical_y = 0
    local vertical_offset_x = -tile_size
    local vertical_offset_y = 0
    local vertical_dist = 0
    if ray_going_right then
        vertical_x = vertical_x + tile_size
        vertical_offset_x = tile_size
    end
    vertical_offset_y = -vertical_offset_x * math.tan(math.rad(alpha))
    vertical_y = player_y - (vertical_x - player_x) * math.tan(math.rad(alpha))
    vertical_dist = math.abs((vertical_y - player_y) / math.sin(math.rad(alpha)))
    if not ray_going_right then
        vertical_x = vertical_x - 1
    end

    for i = 1, 10 do
        local tile_x_vert = math.floor(vertical_x / tile_size) + 1
        local tile_y_vert = math.floor(vertical_y / tile_size) + 1

        if tile_x_vert > map_width or tile_y_vert > map_height or tile_x_vert < 1 or tile_y_vert < 1 then
            vertical_dist = math.huge
            break
        end

        if map[tile_x_vert][tile_y_vert] == 1 then
            love.graphics.setColor(0.1, 0.8, 0.1)
            love.graphics.rectangle('fill', vertical_x - 3, vertical_y - 3, 6, 6)
            break
        end

        love.graphics.setColor(0.8, 0.8, 0)
        love.graphics.rectangle('fill', vertical_x - 2, vertical_y - 2, 4, 4)

        vertical_x = vertical_x + vertical_offset_x
        vertical_y = vertical_y + vertical_offset_y
        vertical_dist = math.abs((vertical_y - player_y) / math.sin(math.rad(alpha)))
    end

    -- Detect intersection with horizontal grid lines
    local horizontal_x = 0
    local horizontal_y = (tile_y + 1) * tile_size
    local horizontal_offset_x = 0
    local horizontal_offset_y = tile_size
    local horizontal_dist = 0
    if ray_going_up then
        horizontal_y = horizontal_y - tile_size
        horizontal_offset_y = -tile_size
    end
    horizontal_offset_x = -horizontal_offset_y / math.tan(math.rad(alpha))
    horizontal_x = player_x - (horizontal_y - player_y) / math.tan(math.rad(alpha))
    horizontal_dist = math.abs((horizontal_x - player_x) / math.cos(math.rad(alpha)))
    if ray_going_up then
        horizontal_y = horizontal_y - 1
    end

    for i = 1, 10 do
        local tile_x_horiz = math.floor(horizontal_x / tile_size) + 1
        local tile_y_horiz = math.floor(horizontal_y / tile_size) + 1

        if tile_x_horiz > map_width or tile_y_horiz > map_height or tile_x_horiz < 1 or tile_y_horiz < 1 then
            horizontal_dist = math.huge
            break
        end

        if map[tile_x_horiz][tile_y_horiz] == 1 then
            love.graphics.setColor(0.1, 0.1, 0.8)
            love.graphics.rectangle('fill', horizontal_x - 3, horizontal_y - 3, 6, 6)
            break
        end

        love.graphics.setColor(0.0, 0.8, 0.8)
        love.graphics.rectangle('fill', horizontal_x - 2, horizontal_y - 2, 4, 4)

        horizontal_x = horizontal_x + horizontal_offset_x
        horizontal_y = horizontal_y + horizontal_offset_y
        horizontal_dist = math.abs((horizontal_x - player_x) / math.cos(math.rad(alpha)))
    end

    local horizontal_boundary = true
    local x, y, dist = horizontal_x, horizontal_y, horizontal_dist
    if dist > vertical_dist then
        x, y, dist = vertical_x, vertical_y, vertical_dist
        horizontal_boundary = false
    end

    love.graphics.setColor(1, 1, 0.5)
    love.graphics.rectangle('fill', x - 4, y - 4, 8, 8)

    love.graphics.setCanvas(world)
    love.graphics.setColor(1, 1, 1, 1)

    return math.floor(x), math.floor(y), math.floor(dist), horizontal_boundary
end

function wrap_angle(angle)
    local angle_rad = math.rad(angle)
    return angle - 360 * math.floor(angle / 360)
end

function love.draw()
    draw_minimap()
    draw_world()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(world, 0, 0, 0, 4, 4)
    -- love.graphics.setBlendMode("alpha", "premultiplied")
    -- love.graphics.draw(minimap, 0, 0, 0, 0.25, 0.25)
end