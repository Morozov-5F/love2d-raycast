map = {
    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    { 1, 0, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1},
    { 1, 0, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1},
    { 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    { 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    { 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    { 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1},
    { 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1},
    { 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1},
    { 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1},
    { 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1},
    { 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1},
    { 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 1, 1},
    { 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1},
    { 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1},
    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

map_width = #map
map_height = #map[1]
fov = 70
tile_size = 64
proj_width = 320
proj_height = 200
dist_to_proj = 277 -- proj_width / 2 / math.tan(math.rad(fov / 2))
fov_side_length = 320  -- dist_to_proj / math.cos(math.rad(fov / 2))

player_tile_x = 4
player_tile_y = 1

max_player_speed = 20 * tile_size

player_vx = 0
player_vy = 0

player_x = player_tile_x * tile_size + tile_size / 2
player_y = player_tile_y * tile_size + tile_size / 2

mouse_look_sensitivity = 0.25

player_height = tile_size / 2
player_viewing_angle = 0

brick_texture = nil
floor_texture = nil
arm_texture = nil

function love.load()
    love.mouse.setRelativeMode(true)
    love.graphics.setDefaultFilter('nearest', 'nearest', 1)
    love.window.setMode(1280, 800, {resizable = false, vsync = true, highdpi = true})

    minimap = love.graphics.newCanvas(1280, 800)
    minimap:setFilter("nearest", "nearest")

    world = love.graphics.newCanvas(proj_width, proj_height)
    world:setFilter("nearest", "nearest")

    brick_texture = love.graphics.newImage('bricksx64.png')
    floor_texture = love.image.newImageData('walkstone.png')
    arm_texture = love.graphics.newImage('colt.png')
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
    local player_forward_x = math.cos(math.rad(player_viewing_angle))
    local player_forward_y = -math.sin(math.rad(player_viewing_angle))

    local player_strafe_x = math.cos(math.rad(player_viewing_angle + 90))
    local player_strafe_y = -math.sin(math.rad(player_viewing_angle + 90))

    local forward = 0
    if love.keyboard.isDown("w") then
        forward = 1
    elseif love.keyboard.isDown("s") then
        forward = -1
    end

    local strafe = 0
    if love.keyboard.isDown("a") then
        strafe = 1
    elseif love.keyboard.isDown("d") then
        strafe = -1
    end

    -- Add forward movement
    player_vx = player_vx + player_forward_x * forward * max_player_speed * dt
    player_vy = player_vy + player_forward_y * forward * max_player_speed * dt

    -- Add strafe movement
    player_vx = player_vx + player_strafe_x * strafe * max_player_speed * dt
    player_vy = player_vy + player_strafe_y * strafe * max_player_speed * dt

    -- Limit movement
    if player_vx > max_player_speed then
        player_vx = max_player_speed
    elseif player_vx < -max_player_speed then
        player_vx = -max_player_speed
    end

    if player_vy > max_player_speed then
        player_vy = max_player_speed
    elseif player_vy < -max_player_speed then
        player_vy = -max_player_speed
    end

    -- Apply friction if necessary
    if forward == 0 and strafe == 0 and (math.abs(player_vx) < 1 and math.abs(player_vy) < 1) then 
        player_vx = 0
        player_vy = 0
    else
        player_vx = 0.9 * player_vx
        player_vy = 0.9 * player_vy
    end

    -- collision detection part
    local try_x = player_x + player_vx * dt
    local try_y = player_y + player_vy * dt

    local try_player_tile_x = math.floor(try_x / tile_size) + 1
    local try_player_tile_y = math.floor(try_y / tile_size) + 1

    if try_player_tile_x < 1 or try_player_tile_x > map_width or try_player_tile_y < 1 or try_player_tile_y > map_height or map[try_player_tile_x][try_player_tile_y] ~= 0 then 
        player_vx = 0 
        player_vy = 0
    end

    player_x = player_x + player_vx * dt
    player_y = player_y + player_vy * dt
end

function love.mousemoved(x, y, dx, dy, isTouch)
    player_viewing_angle = player_viewing_angle - mouse_look_sensitivity * dx
end

function draw_world()
    love.graphics.setCanvas(world)
    love.graphics.clear()

    for i = 0, proj_height / 2 do
        love.graphics.setColor(0.01 * i / 2, 0.005 * i / 2, 0.005 * i / 2);
        love.graphics.line(0, proj_height / 2 - i, proj_width, proj_height / 2 - i)
        love.graphics.line(0, proj_height / 2 + i, proj_width, proj_height / 2 + i)
    end

    for i = 0, proj_width do
        local angle = fov / 2 - i * fov / proj_width
        local x, y, dist, horizontal_boundary = raycast(angle)

        local projected_wall_height = 0
        if dist < math.huge then

            local correct_dist = dist * math.cos(math.rad(angle))
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
            -- love.graphics.line(i, proj_height / 2 - projected_wall_height * 0.5, i, proj_height / 2 + projected_wall_height * 0.5)
            local quad = love.graphics.newQuad(texture_offset, 0, 1, 64, brick_texture)
            local transfrom = love.math.newTransform(i, proj_height / 2 - projected_wall_height / 2, 0,
                                                     1, projected_wall_height / tile_size)
            love.graphics.draw(brick_texture, quad, transfrom)
        end

        -- Floor casting
        for j = proj_height / 2 + projected_wall_height / 2,  proj_height do
            local flat_distance = player_height / (j - proj_height / 2) * dist_to_proj
            local diag_distance = math.floor(flat_distance / math.cos(math.rad(angle)))

            local alpha = wrap_angle(player_viewing_angle + angle)
            local floor_x = player_x + math.floor(diag_distance * math.cos(math.rad(alpha)))
            local floor_y = player_y - math.floor(diag_distance * math.sin(math.rad(alpha)))

            local floor_tile_x = math.floor(floor_x / tile_size) + 1
            local floor_tile_y = math.floor(floor_y / tile_size) + 1

            -- print(j, alpha, math.floor(diag_distance), floor_x, floor_y, floor_tile_x, floor_tile_y)

            if floor_tile_x >= 1 and floor_tile_y >= 1 and floor_tile_x <= map_width and floor_tile_y <= map_height then
                local texture_x = math.floor(math.fmod(floor_x, tile_size))
                local texture_y = math.floor(math.fmod(floor_y, tile_size))
                local r,g,b = floor_texture:getPixel(texture_x, texture_y)

                local brightness = 1 / (0.02 * diag_distance)
                love.graphics.setColor(r * brightness, g * brightness, b * brightness)
                love.graphics.rectangle('fill', i, j, 1, 1)
            end
        end
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(arm_texture, proj_width / 2 - arm_texture:getWidth() / 2, proj_height - 64)
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
    vertical_dist = math.sqrt((vertical_x - player_x) * (vertical_x - player_x) + (vertical_y - player_y) * (vertical_y - player_y))
    if not ray_going_right then
        vertical_x = vertical_x - 1
    end

    for i = 1, 30 do
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
        vertical_dist = math.sqrt((vertical_x - player_x) * (vertical_x - player_x) + (vertical_y - player_y) * (vertical_y - player_y))
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
    horizontal_dist = math.sqrt((horizontal_x - player_x) * (horizontal_x - player_x) + (horizontal_y - player_y) * (horizontal_y - player_y))
    if ray_going_up then
        horizontal_y = horizontal_y - 1
    end

    for i = 1, 30 do
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
        horizontal_dist = math.sqrt((horizontal_x - player_x) * (horizontal_x - player_x) + (horizontal_y - player_y) * (horizontal_y - player_y))
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
    -- love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(world, 0, 0, 0, 4, 4)
    -- love.graphics.setBlendMode("alpha", "premultiplied")
    -- love.graphics.draw(minimap, 0, 0, 0, 1, 1)
    love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
end