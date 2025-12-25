# snowGui 动画系统指南 (Animation System Guide)

本文档详细介绍如何为 snowGui 框架的 view 组件添加动画功能。

---

## 目录

1. [基础概念](#基础概念)
2. [简单动画实现](#简单动画实现)
3. [动画系统设计](#动画系统设计)
4. [完整动画库](#完整动画库)
5. [缓动函数](#缓动函数)
6. [实战示例](#实战示例)

---

## 基础概念

### View 的 update 方法

每个 view 都有一个 `update(dt)` 方法，在每帧被调用：

```lua
function view:update(dt)
    -- dt: delta time，上一帧到当前帧的时间间隔（秒）
    -- 在这里实现动画逻辑
end
```

### 动画的本质

动画就是在每一帧中逐渐改变视图的属性值：

```
初始状态 → 渐变过程 → 目标状态
   ↓          ↓          ↓
  x=0    →  x=50   →   x=100
```

---

## 简单动画实现

### 示例 1: 淡入效果

```lua
local lumenGui = require("lumenGui")
local gui = lumenGui:new()

-- 创建一个按钮
local button = gui:load_layout({
    type = "button",
    x = 100,
    y = 100,
    width = 150,
    height = 40,
    text = "淡入按钮",
    backgroundColor = {0.2, 0.6, 1, 0},  -- 初始透明度为 0
})

-- 添加淡入动画
button.fade_alpha = 0  -- 当前透明度
button.fade_speed = 1  -- 淡入速度

function button:update(dt)
    -- 如果还没完全显示
    if self.fade_alpha < 1 then
        self.fade_alpha = self.fade_alpha + self.fade_speed * dt
        
        -- 限制在 0-1 范围内
        if self.fade_alpha > 1 then
            self.fade_alpha = 1
        end
        
        -- 更新背景色的 alpha 通道
        self.backgroundColor[4] = self.fade_alpha
    end
end

function love.load()
    gui:add_view(button)
end
```

### 示例 2: 移动动画

```lua
-- 创建一个会移动的文本
local text = gui:load_layout({
    type = "text",
    x = 0,
    y = 100,
    text = "移动文本",
    textSize = 20
})

-- 动画参数
text.target_x = 300      -- 目标位置
text.move_speed = 100    -- 移动速度（像素/秒）

function text:update(dt)
    -- 如果还没到达目标位置
    if self.x < self.target_x then
        self.x = self.x + self.move_speed * dt
        
        -- 到达目标位置就停止
        if self.x >= self.target_x then
            self.x = self.target_x
        end
    end
end
```

### 示例 3: 缩放动画

```lua
local button = gui:load_layout({
    type = "button",
    x = 100,
    y = 100,
    width = 100,
    height = 40,
    text = "点击缩放"
})

-- 缩放动画状态
button.scale = 1.0
button.target_scale = 1.0
button.scale_speed = 2.0

function button:update(dt)
    -- 平滑过渡到目标缩放
    if math.abs(self.scale - self.target_scale) > 0.01 then
        local diff = self.target_scale - self.scale
        self.scale = self.scale + diff * self.scale_speed * dt
    end
end

function button:draw()
    -- 保存原始尺寸
    local orig_w, orig_h = self.width, self.height
    
    -- 应用缩放
    local scale_w = orig_w * self.scale
    local scale_h = orig_h * self.scale
    local offset_x = (orig_w - scale_w) / 2
    local offset_y = (orig_h - scale_h) / 2
    
    -- 绘制缩放后的按钮
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", offset_x, offset_y, scale_w, scale_h)
    
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", offset_x, offset_y, scale_w, scale_h)
    
    -- 绘制文本
    love.graphics.setColor(self.textColor)
    local font = love.graphics.getFont()
    local text_w = font:getWidth(self.text)
    local text_h = font:getHeight()
    love.graphics.print(self.text, 
        (orig_w - text_w) / 2, 
        (orig_h - text_h) / 2)
end

function button:on_click()
    -- 点击时放大
    self.target_scale = 1.2
end

function button:off_hover()
    -- 失去焦点时恢复
    self.target_scale = 1.0
end

function button:on_hover()
    -- 悬停时稍微放大
    self.target_scale = 1.1
end
```

---

## 动画系统设计

为了更方便地管理动画，我们可以创建一个通用的动画系统。

### 动画管理器

```lua
-- Animation.lua
local Animation = {}
Animation.__index = Animation

-- 创建新动画
function Animation:new(config)
    local anim = {
        target = config.target,           -- 要动画的对象
        property = config.property,       -- 要动画的属性名
        from = config.from,               -- 起始值
        to = config.to,                   -- 目标值
        duration = config.duration or 1,  -- 持续时间（秒）
        elapsed = 0,                      -- 已经过时间
        easing = config.easing or "linear", -- 缓动函数
        on_complete = config.on_complete, -- 完成回调
        is_complete = false,
    }
    setmetatable(anim, self)
    return anim
end

-- 更新动画
function Animation:update(dt)
    if self.is_complete then return end
    
    self.elapsed = self.elapsed + dt
    
    -- 计算进度 (0 到 1)
    local progress = math.min(self.elapsed / self.duration, 1)
    
    -- 应用缓动函数
    local eased = self:ease(progress)
    
    -- 计算当前值
    local current = self.from + (self.to - self.from) * eased
    
    -- 更新目标对象的属性
    self.target[self.property] = current
    
    -- 检查是否完成
    if progress >= 1 then
        self.is_complete = true
        if self.on_complete then
            self.on_complete(self.target)
        end
    end
end

-- 缓动函数
function Animation:ease(t)
    if self.easing == "linear" then
        return t
    elseif self.easing == "ease-in" then
        return t * t
    elseif self.easing == "ease-out" then
        return t * (2 - t)
    elseif self.easing == "ease-in-out" then
        return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
    elseif self.easing == "bounce" then
        if t < 0.5 then
            return 8 * t * t * t * t
        else
            local f = t - 1
            return 1 + 8 * f * f * f * f
        end
    end
    return t
end

return Animation
```

### 使用动画管理器

```lua
local Animation = require("Animation")
local lumenGui = require("lumenGui")
local gui = lumenGui:new()

-- 存储所有活动的动画
local animations = {}

local button = gui:load_layout({
    type = "button",
    x = 50,
    y = 100,
    width = 150,
    height = 40,
    text = "点击移动",
    on_click = function(self)
        -- 创建移动动画
        local anim = Animation:new({
            target = self,
            property = "x",
            from = self.x,
            to = 400,
            duration = 1.0,
            easing = "ease-in-out",
            on_complete = function(obj)
                print("动画完成！")
            end
        })
        table.insert(animations, anim)
    end
})

function love.load()
    gui:add_view(button)
end

function love.update(dt)
    gui:update(dt)
    
    -- 更新所有动画
    for i = #animations, 1, -1 do
        local anim = animations[i]
        anim:update(dt)
        
        -- 移除已完成的动画
        if anim.is_complete then
            table.remove(animations, i)
        end
    end
end

function love.draw()
    gui:draw()
end
```

---

## 完整动画库

### 高级动画系统

```lua
-- AnimationSystem.lua
local AnimationSystem = {
    animations = {}
}

-- 缓动函数库
local Easing = {
    linear = function(t) return t end,
    
    easeInQuad = function(t) return t * t end,
    easeOutQuad = function(t) return t * (2 - t) end,
    easeInOutQuad = function(t)
        return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
    end,
    
    easeInCubic = function(t) return t * t * t end,
    easeOutCubic = function(t)
        local f = t - 1
        return f * f * f + 1
    end,
    easeInOutCubic = function(t)
        return t < 0.5 and 4 * t * t * t or (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
    end,
    
    easeInBack = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return c3 * t * t * t - c1 * t * t
    end,
    easeOutBack = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
    end,
    
    easeInElastic = function(t)
        local c4 = (2 * math.pi) / 3
        return t == 0 and 0 or t == 1 and 1 or
            -math.pow(2, 10 * t - 10) * math.sin((t * 10 - 10.75) * c4)
    end,
    easeOutElastic = function(t)
        local c4 = (2 * math.pi) / 3
        return t == 0 and 0 or t == 1 and 1 or
            math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
    end,
    
    easeInBounce = function(t)
        return 1 - Easing.easeOutBounce(1 - t)
    end,
    easeOutBounce = function(t)
        local n1 = 7.5625
        local d1 = 2.75
        
        if t < 1 / d1 then
            return n1 * t * t
        elseif t < 2 / d1 then
            t = t - 1.5 / d1
            return n1 * t * t + 0.75
        elseif t < 2.5 / d1 then
            t = t - 2.25 / d1
            return n1 * t * t + 0.9375
        else
            t = t - 2.625 / d1
            return n1 * t * t + 0.984375
        end
    end,
}

-- 创建动画
function AnimationSystem.animate(target, properties)
    local anim = {
        target = target,
        properties = {},
        duration = properties.duration or 1,
        elapsed = 0,
        easing = Easing[properties.easing] or Easing.linear,
        on_update = properties.on_update,
        on_complete = properties.on_complete,
        delay = properties.delay or 0,
        loop = properties.loop or false,
        yoyo = properties.yoyo or false,
        is_complete = false,
    }
    
    -- 设置属性动画
    for key, value in pairs(properties) do
        if type(value) == "number" then
            anim.properties[key] = {
                from = target[key],
                to = value,
            }
        elseif type(value) == "table" and value.from and value.to then
            anim.properties[key] = value
        end
    end
    
    table.insert(AnimationSystem.animations, anim)
    return anim
end

-- 更新所有动画
function AnimationSystem.update(dt)
    for i = #AnimationSystem.animations, 1, -1 do
        local anim = AnimationSystem.animations[i]
        
        -- 处理延迟
        if anim.delay > 0 then
            anim.delay = anim.delay - dt
            goto continue
        end
        
        anim.elapsed = anim.elapsed + dt
        local progress = math.min(anim.elapsed / anim.duration, 1)
        local eased = anim.easing(progress)
        
        -- 更新所有属性
        for key, prop in pairs(anim.properties) do
            local current = prop.from + (prop.to - prop.from) * eased
            anim.target[key] = current
        end
        
        -- 调用更新回调
        if anim.on_update then
            anim.on_update(anim.target, progress)
        end
        
        -- 检查完成
        if progress >= 1 then
            if anim.yoyo then
                -- 往返动画
                for key, prop in pairs(anim.properties) do
                    prop.from, prop.to = prop.to, prop.from
                end
                anim.elapsed = 0
            elseif anim.loop then
                -- 循环动画
                anim.elapsed = 0
            else
                -- 完成动画
                if anim.on_complete then
                    anim.on_complete(anim.target)
                end
                table.remove(AnimationSystem.animations, i)
            end
        end
        
        ::continue::
    end
end

-- 停止所有针对目标的动画
function AnimationSystem.stop(target)
    for i = #AnimationSystem.animations, 1, -1 do
        if AnimationSystem.animations[i].target == target then
            table.remove(AnimationSystem.animations, i)
        end
    end
end

-- 清除所有动画
function AnimationSystem.clear()
    AnimationSystem.animations = {}
end

return AnimationSystem
```

---

## 缓动函数

缓动函数控制动画的速度变化：

| 缓动类型 | 效果 |
|---------|------|
| `linear` | 匀速运动 |
| `easeInQuad` | 加速进入 |
| `easeOutQuad` | 减速退出 |
| `easeInOutQuad` | 先加速后减速 |
| `easeInCubic` | 快速加速 |
| `easeOutCubic` | 快速减速 |
| `easeInBack` | 回弹进入 |
| `easeOutBack` | 回弹退出 |
| `easeInElastic` | 弹性进入 |
| `easeOutElastic` | 弹性退出 |
| `easeInBounce` | 弹跳进入 |
| `easeOutBounce` | 弹跳退出 |

### 缓动函数可视化

```
linear:          ----/
easeInQuad:      ___/
easeOutQuad:     /---
easeInOutQuad:   _/-_
easeOutBounce:   /\/\-
easeOutElastic:  ~~~~-
```

---

## 实战示例

### 示例 1: 完整的动画按钮

```lua
local lumenGui = require("lumenGui")
local AnimationSystem = require("AnimationSystem")
local gui = lumenGui:new()

local button = gui:load_layout({
    type = "button",
    x = 200,
    y = 200,
    width = 150,
    height = 50,
    text = "动画按钮",
    backgroundColor = {0.2, 0.6, 1, 1}
})

-- 添加动画属性
button.scale = 1.0
button.rotation = 0

-- 悬停时放大
function button:on_hover()
    AnimationSystem.animate(self, {
        scale = 1.1,
        duration = 0.2,
        easing = "easeOutBack"
    })
end

-- 失去焦点时恢复
function button:off_hover()
    AnimationSystem.animate(self, {
        scale = 1.0,
        duration = 0.2,
        easing = "easeOutQuad"
    })
end

-- 点击时旋转并移动
function button:on_click()
    -- 旋转动画
    AnimationSystem.animate(self, {
        rotation = self.rotation + math.pi * 2,
        duration = 0.5,
        easing = "easeOutBack"
    })
    
    -- 跳跃动画
    local original_y = self.y
    AnimationSystem.animate(self, {
        y = self.y - 50,
        duration = 0.3,
        easing = "easeOutQuad",
        on_complete = function(target)
            AnimationSystem.animate(target, {
                y = original_y,
                duration = 0.3,
                easing = "easeInQuad"
            })
        end
    })
end

-- 自定义绘制以支持缩放和旋转
function button:draw()
    love.graphics.push()
    
    -- 移动到中心点
    love.graphics.translate(self.width / 2, self.height / 2)
    
    -- 应用旋转和缩放
    love.graphics.rotate(self.rotation or 0)
    love.graphics.scale(self.scale or 1.0)
    
    -- 绘制按钮（相对于中心）
    local w, h = self.width / 2, self.height / 2
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", -w, -h, self.width, self.height, 5, 5)
    
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", -w, -h, self.width, self.height, 5, 5)
    
    -- 绘制文本
    love.graphics.setColor(self.textColor or {1, 1, 1})
    local font = love.graphics.getFont()
    local text_w = font:getWidth(self.text)
    local text_h = font:getHeight()
    love.graphics.print(self.text, -text_w / 2, -text_h / 2)
    
    love.graphics.pop()
end

function love.load()
    gui:add_view(button)
end

function love.update(dt)
    gui:update(dt)
    AnimationSystem.update(dt)
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    gui:draw()
end

-- Windows 输入
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
```

### 示例 2: 列表项淡入动画

```lua
local lumenGui = require("lumenGui")
local AnimationSystem = require("AnimationSystem")
local gui = lumenGui:new()

-- 创建列表容器
local list_container = gui:load_layout({
    type = "slider_container",
    x = 50,
    y = 50,
    width = 300,
    height = 400,
    {
        type = "line_layout",
        orientation = "vertical",
        width = "fill",
        id = "item_list"
    }
})

-- 添加列表项的函数
function add_list_item(text, index)
    local item = gui:load_layout({
        type = "line_layout",
        orientation = "horizontal",
        width = "fill",
        height = 50,
        padding = 10,
        backgroundColor = {0.2, 0.2, 0.3, 0},  -- 初始透明
        
        {
            type = "text",
            text = text,
            textSize = 16,
            textColor = {1, 1, 1},
            layout_weight = 1
        }
    })
    
    local list = gui:get_id_view("item_list")
    list:add_view(item)
    
    -- 延迟淡入动画
    item.alpha = 0
    AnimationSystem.animate(item.backgroundColor, {
        [4] = {from = 0, to = 1},  -- 动画化 alpha 通道
        duration = 0.5,
        delay = index * 0.1,  -- 每个项目延迟 0.1 秒
        easing = "easeOutQuad"
    })
    
    -- 同时从左侧滑入
    item.offset_x = -50
    AnimationSystem.animate(item, {
        offset_x = 0,
        duration = 0.5,
        delay = index * 0.1,
        easing = "easeOutBack"
    })
end

-- 重写绘制以支持偏移
local original_draw = list_container.children[1].children[1].draw
function custom_draw(self)
    if self.offset_x then
        love.graphics.push()
        love.graphics.translate(self.offset_x, 0)
        original_draw(self)
        love.graphics.pop()
    else
        original_draw(self)
    end
end

function love.load()
    gui:add_view(list_container)
    
    -- 添加一些列表项
    local items = {
        "第一个项目",
        "第二个项目",
        "第三个项目",
        "第四个项目",
        "第五个项目",
    }
    
    for i, text in ipairs(items) do
        add_list_item(text, i)
    end
end

function love.update(dt)
    gui:update(dt)
    AnimationSystem.update(dt)
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    gui:draw()
end
```

### 示例 3: 脉冲动画（循环）

```lua
local button = gui:load_layout({
    type = "button",
    x = 200,
    y = 200,
    width = 150,
    height = 50,
    text = "脉冲按钮"
})

-- 添加脉冲属性
button.pulse_scale = 1.0

-- 创建无限循环的脉冲动画
AnimationSystem.animate(button, {
    pulse_scale = 1.1,
    duration = 0.8,
    easing = "easeInOutQuad",
    yoyo = true,  -- 往返动画
    loop = true   -- 无限循环
})

-- 在绘制时应用脉冲缩放
function button:draw()
    love.graphics.push()
    love.graphics.translate(self.width / 2, self.height / 2)
    love.graphics.scale(self.pulse_scale)
    love.graphics.translate(-self.width / 2, -self.height / 2)
    
    -- 绘制按钮
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    
    love.graphics.pop()
end
```

---

## 性能优化建议

### 1. 避免创建过多动画

```lua
-- ❌ 不好：每帧都创建新动画
function button:update(dt)
    AnimationSystem.animate(self, {x = target_x})
end

-- ✅ 好：只在需要时创建
function button:on_click()
    AnimationSystem.animate(self, {x = target_x})
end
```

### 2. 及时清理完成的动画

动画系统已经自动清理完成的动画，但如果需要手动停止：

```lua
-- 停止针对某个对象的所有动画
AnimationSystem.stop(button)
```

### 3. 使用对象池

对于频繁创建/销毁的动画对象，考虑使用对象池。

### 4. 限制同时运行的动画数量

```lua
-- 限制最大动画数量
local MAX_ANIMATIONS = 50

function safe_animate(target, properties)
    if #AnimationSystem.animations < MAX_ANIMATIONS then
        return AnimationSystem.animate(target, properties)
    end
end
```

---

## 总结

为 snowGui 的 view 添加动画功能的关键步骤：

1. **利用 update(dt) 方法** - 在每帧更新动画状态
2. **创建动画系统** - 统一管理所有动画
3. **使用缓动函数** - 让动画更自然
4. **自定义绘制** - 在 draw() 方法中应用动画效果
5. **性能优化** - 避免过多动画，及时清理

通过这些技术，您可以为 snowGui 框架创建丰富的动画效果，提升用户体验！

---

**相关文档**:
- [设计思路文档](./DESIGN.md)
- [架构文档](./ARCHITECTURE.md)
- [实践示例](./EXAMPLES.md)

**作者**: 北极企鹅  
**文档维护**: 2025
