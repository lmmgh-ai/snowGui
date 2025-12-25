-- 动画演示示例
local lumenGui = require("lumenGui")
local AnimationSystem = require("experiment.AnimationSystem")
local gui = lumenGui:new()

-- 演示 1: 淡入按钮
local fade_button = gui:load_layout({
    type = "button",
    x = 50,
    y = 50,
    width = 150,
    height = 40,
    text = "淡入效果",
    backgroundColor = {0.2, 0.6, 1, 0}  -- 初始透明
})

-- 淡入动画
AnimationSystem.animate(fade_button.backgroundColor, {
    [4] = {from = 0, to = 1},  -- alpha 通道
    duration = 2,
    easing = "easeInOutQuad"
})

-- 演示 2: 移动按钮
local move_button = gui:load_layout({
    type = "button",
    x = 50,
    y = 110,
    width = 150,
    height = 40,
    text = "点击移动",
    on_click = function(self)
        AnimationSystem.animate(self, {
            x = self.x == 50 and 300 or 50,
            duration = 1,
            easing = "easeInOutBack"
        })
    end
})

-- 演示 3: 缩放按钮
local scale_button = gui:load_layout({
    type = "button",
    x = 50,
    y = 170,
    width = 150,
    height = 40,
    text = "悬停缩放"
})

scale_button.scale = 1.0
scale_button.rotation = 0

function scale_button:on_hover()
    AnimationSystem.animate(self, {
        scale = 1.15,
        duration = 0.2,
        easing = "easeOutBack"
    })
end

function scale_button:off_hover()
    AnimationSystem.animate(self, {
        scale = 1.0,
        duration = 0.2,
        easing = "easeOutQuad"
    })
end

function scale_button:on_click()
    -- 旋转动画
    AnimationSystem.animate(self, {
        rotation = (self.rotation or 0) + math.pi * 2,
        duration = 0.8,
        easing = "easeOutElastic"
    })
end

-- 自定义绘制以支持缩放和旋转
function scale_button:draw()
    love.graphics.push()
    
    -- 移动到中心点
    love.graphics.translate(self.width / 2, self.height / 2)
    
    -- 应用旋转和缩放
    if self.rotation then
        love.graphics.rotate(self.rotation)
    end
    if self.scale then
        love.graphics.scale(self.scale, self.scale)
    end
    
    -- 绘制按钮（相对于中心）
    local w, h = self.width / 2, self.height / 2
    love.graphics.setColor(self.isPressed and self.pressedColor or 
                           self.isHover and self.hoverColor or 
                           self.backgroundColor)
    love.graphics.rectangle("fill", -w, -h, self.width, self.height, 5, 5)
    
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", -w, -h, self.width, self.height, 5, 5)
    
    -- 绘制文本
    love.graphics.setColor(self.textColor or {1, 1, 1})
    local font = self.gui:get_font(self.font, self.textSize)
    love.graphics.setFont(font)
    local text_w = font:getWidth(self.text)
    local text_h = font:getHeight()
    love.graphics.print(self.text, -text_w / 2, -text_h / 2)
    
    love.graphics.pop()
end

-- 演示 4: 脉冲按钮（循环动画）
local pulse_button = gui:load_layout({
    type = "button",
    x = 50,
    y = 230,
    width = 150,
    height = 40,
    text = "脉冲动画"
})

pulse_button.pulse_scale = 1.0

-- 无限循环的脉冲动画
AnimationSystem.animate(pulse_button, {
    pulse_scale = 1.1,
    duration = 0.8,
    easing = "easeInOutQuad",
    yoyo = true,
    loop = true
})

function pulse_button:draw()
    love.graphics.push()
    
    love.graphics.translate(self.width / 2, self.height / 2)
    love.graphics.scale(self.pulse_scale or 1.0)
    love.graphics.translate(-self.width / 2, -self.height / 2)
    
    love.graphics.setColor(self.isPressed and self.pressedColor or 
                           self.isHover and self.hoverColor or 
                           self.backgroundColor)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height, 5, 5)
    
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", 0, 0, self.width, self.height, 5, 5)
    
    love.graphics.setColor(self.textColor or {0, 0, 0})
    local font = self.gui:get_font(self.font, self.textSize)
    love.graphics.setFont(font)
    local text_w = font:getWidth(self.text)
    local text_h = font:getHeight()
    love.graphics.print(self.text, (self.width - text_w) / 2, (self.height - text_h) / 2)
    
    love.graphics.pop()
end

-- 演示 5: 弹跳按钮
local bounce_button = gui:load_layout({
    type = "button",
    x = 50,
    y = 290,
    width = 150,
    height = 40,
    text = "点击弹跳",
    on_click = function(self)
        local original_y = self.y
        AnimationSystem.animate(self, {
            y = self.y - 50,
            duration = 0.3,
            easing = "easeOutQuad",
            on_complete = function(target)
                AnimationSystem.animate(target, {
                    y = original_y,
                    duration = 0.4,
                    easing = "easeOutBounce"
                })
            end
        })
    end
})

-- 演示 6: 颜色动画
local color_button = gui:load_layout({
    type = "button",
    x = 50,
    y = 350,
    width = 150,
    height = 40,
    text = "颜色变化"
})

color_button.hue = 0

function color_button:update(dt)
    -- 连续变化色相
    self.hue = (self.hue + dt * 0.5) % 1
    
    -- HSV 转 RGB
    local function hsv_to_rgb(h, s, v)
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
    
    local r, g, b = hsv_to_rgb(self.hue, 0.7, 0.9)
    self.backgroundColor = {r, g, b, 1}
end

-- 说明文本
local info_text = gui:load_layout({
    type = "text",
    x = 250,
    y = 50,
    width = 300,
    textSize = 14,
    textColor = {0.8, 0.8, 0.8},
    text = [[动画演示说明:

1. 淡入效果 - 自动淡入
2. 点击移动 - 点击后移动
3. 悬停缩放 - 鼠标悬停放大，点击旋转
4. 脉冲动画 - 持续缩放循环
5. 点击弹跳 - 点击后上下弹跳
6. 颜色变化 - 自动变化颜色

支持的缓动函数:
• linear (线性)
• easeInQuad/Out/InOut (二次)
• easeInCubic/Out/InOut (三次)
• easeInBack/Out (回弹)
• easeInElastic/Out (弹性)
• easeInBounce/Out (弹跳)]]
})

--初始化
function love.load(...)
    gui:add_view(fade_button)
    gui:add_view(move_button)
    gui:add_view(scale_button)
    gui:add_view(pulse_button)
    gui:add_view(bounce_button)
    gui:add_view(color_button)
    gui:add_view(info_text)
end

-- 更新
function love.update(dt)
    gui:update(dt)
    AnimationSystem.update(dt)
end

-- 绘制
function love.draw()
    love.graphics.clear(0.15, 0.15, 0.15)
    gui:draw()
    
    -- 显示动画数量
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("活动动画数量: " .. #AnimationSystem.animations, 10, love.graphics.getHeight() - 25)
end

-- 平台适配
if love.system.getOS() == "Windows" then
    function love.mousemoved(x, y, dx, dy, istouch)
        gui:mousemoved(nil, x, y, dx, dy, istouch, nil)
    end
    function love.mousepressed(x, y, id, istouch, pressure)
        gui:mousepressed(id, x, y, nil, nil, istouch, pressure)
    end
    function love.mousereleased(x, y, id, istouch, pressure)
        gui:mousereleased(id, x, y, nil, nil, istouch, pressure)
    end
end

function love.resize(width, height)
    gui:resize(width, height)
end
