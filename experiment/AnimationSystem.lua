-- AnimationSystem.lua
-- 通用动画系统，用于 snowGui 框架

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
        if key ~= "duration" and key ~= "easing" and key ~= "on_update" and 
           key ~= "on_complete" and key ~= "delay" and key ~= "loop" and key ~= "yoyo" then
            if type(value) == "number" then
                anim.properties[key] = {
                    from = target[key] or 0,
                    to = value,
                }
            elseif type(value) == "table" and value.from and value.to then
                anim.properties[key] = value
            end
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

-- 获取缓动函数列表
function AnimationSystem.getEasingList()
    local list = {}
    for name, _ in pairs(Easing) do
        table.insert(list, name)
    end
    return list
end

return AnimationSystem
