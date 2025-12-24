# snowGui 实践示例 (Practical Examples)

本文档通过实际代码示例展示 snowGui 的设计理念和使用方法。

---

## 目录 (Table of Contents)

1. [基础示例](#基础示例)
2. [布局系统示例](#布局系统示例)
3. [事件系统示例](#事件系统示例)
4. [自定义组件示例](#自定义组件示例)
5. [完整应用示例](#完整应用示例)

---

## 基础示例

### 示例 1: 创建简单按钮

```lua
local lumenGui = require("lumenGui")
local gui = lumenGui:new()

-- 方式 1: 声明式创建（推荐）
local button1 = gui:load_layout({
    type = "button",
    x = 50,
    y = 50,
    width = 150,
    height = 40,
    text = "点击我",
    backgroundColor = "#3498DB",
    textColor = "#FFFFFF",
    on_click = function(self)
        print("按钮被点击了！")
    end
})

-- 方式 2: 面向对象创建
local button2 = lumenGui.button:new({
    x = 50,
    y = 100,
    width = 150,
    height = 40,
    text = "另一个按钮",
    on_click = function(self)
        self.text = "已点击"
    end
})

function love.load()
    gui:add_view(button1)
    gui:add_view(button2)
end

function love.update(dt)
    gui:update(dt)
end

function love.draw()
    gui:draw()
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
```

**设计理念体现**:
- 支持声明式和面向对象两种创建方式
- 事件回调直接在配置中定义
- 跨平台输入抽象

---

## 布局系统示例

### 示例 2: 线性布局

```lua
-- 垂直线性布局
local vertical_layout = {
    type = "line_layout",
    orientation = "vertical",
    width = 200,
    height = 400,
    x = 50,
    y = 50,
    padding = 10,  -- 内边距
    
    -- 子视图
    {
        type = "text",
        text = "标题",
        textSize = 20,
        height = 40,
        layout_margin = 5  -- 外边距
    },
    {
        type = "button",
        text = "按钮 1",
        height = 50,
        layout_weight = 0  -- 固定高度
    },
    {
        type = "button",
        text = "按钮 2",
        layout_weight = 1  -- 权重分配剩余空间
    },
    {
        type = "button",
        text = "按钮 3",
        layout_weight = 2  -- 获得 2 倍权重的空间
    }
}

-- 水平线性布局
local horizontal_layout = {
    type = "line_layout",
    orientation = "horizontal",
    width = 400,
    height = 100,
    x = 50,
    y = 500,
    
    {
        type = "button",
        text = "左",
        width = 100
    },
    {
        type = "button",
        text = "中",
        layout_weight = 1  -- 填充剩余空间
    },
    {
        type = "button",
        text = "右",
        width = 100
    }
}

function love.load()
    local gui = lumenGui:new()
    gui:add_view(gui:load_layout(vertical_layout))
    gui:add_view(gui:load_layout(horizontal_layout))
end
```

**设计理念体现**:
- 灵活的权重系统
- 内边距和外边距支持
- 嵌套布局

### 示例 3: 网格布局

```lua
local grid = {
    type = "grid_layout",
    columns = 3,
    rows = 3,
    width = 300,
    height = 300,
    x = 50,
    y = 50,
    padding = 5,
    
    -- 自动按行列排列
    { type = "button", text = "1" },
    { type = "button", text = "2" },
    { type = "button", text = "3" },
    { type = "button", text = "4" },
    { type = "button", text = "5" },
    { type = "button", text = "6" },
    { type = "button", text = "7" },
    { type = "button", text = "8" },
    { type = "button", text = "9" },
}
```

### 示例 4: 重力布局

```lua
local gravity_demo = {
    type = "gravity_layout",
    width = 400,
    height = 400,
    
    {
        type = "button",
        text = "中心",
        width = 100,
        height = 50,
        gravity = "center"
    },
    {
        type = "button",
        text = "左上",
        width = 80,
        height = 40,
        gravity = "top|left"
    },
    {
        type = "button",
        text = "右下",
        width = 80,
        height = 40,
        gravity = "bottom|right"
    }
}
```

**设计理念体现**:
- 多种布局策略
- 组合重力定位
- 响应式设计

---

## 事件系统示例

### 示例 5: 发布-订阅模式

```lua
local lumenGui = require("lumenGui")
local gui = lumenGui:new()

-- 创建数据显示组件
local display = gui:load_layout({
    type = "text",
    id = "data_display",
    text = "数据: 0",
    x = 50,
    y = 150,
    textSize = 18
})

-- 创建控制按钮
local controls = gui:load_layout({
    type = "line_layout",
    orientation = "horizontal",
    x = 50,
    y = 50,
    width = 300,
    height = 50,
    
    {
        type = "button",
        text = "增加",
        width = 90,
        on_click = function(self)
            -- 发布事件
            gui:publish_event("数据改变", { action = "增加" })
        end
    },
    {
        type = "button",
        text = "减少",
        width = 90,
        on_click = function(self)
            gui:publish_event("数据改变", { action = "减少" })
        end
    },
    {
        type = "button",
        text = "重置",
        width = 90,
        on_click = function(self)
            gui:publish_event("数据改变", { action = "重置" })
        end
    }
})

-- 数据模型
local data = { value = 0 }

-- 订阅事件
local sub_id = gui:on_event("数据改变", function(event_data)
    if event_data.action == "增加" then
        data.value = data.value + 1
    elseif event_data.action == "减少" then
        data.value = data.value - 1
    elseif event_data.action == "重置" then
        data.value = 0
    end
    
    -- 更新显示
    display.text = "数据: " .. data.value
end)

function love.load()
    gui:add_view(controls)
    gui:add_view(display)
end

-- 清理时取消订阅
function love.quit()
    gui:unsubscribeById("数据改变", sub_id)
end
```

**设计理念体现**:
- 解耦组件间通信
- 事件驱动更新
- 订阅生命周期管理

---

## 自定义组件示例

### 示例 6: 创建自定义进度条

```lua
-- progress_bar.lua
local view = require("lumenGui.view.view")
local progress_bar = view:new()
progress_bar.__index = progress_bar

function progress_bar:new(config)
    local obj = {
        type = "progress_bar",
        width = 200,
        height = 30,
        progress = 0.5,  -- 0 到 1
        backgroundColor = {0.2, 0.2, 0.2, 1},
        fillColor = {0.2, 0.8, 0.2, 1},
        borderColor = {0.5, 0.5, 0.5, 1}
    }
    
    for k, v in pairs(config or {}) do
        obj[k] = v
    end
    
    obj.__index = obj
    setmetatable(obj, self)
    obj:_init()
    return obj
end

function progress_bar:draw()
    -- 绘制背景
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    
    -- 绘制进度
    local fill_width = self.width * self.progress
    love.graphics.setColor(self.fillColor)
    love.graphics.rectangle("fill", 0, 0, fill_width, self.height)
    
    -- 绘制边框
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", 0, 0, self.width, self.height)
    
    -- 绘制文本
    local percent = math.floor(self.progress * 100)
    love.graphics.setColor(1, 1, 1)
    local text = percent .. "%"
    local font = love.graphics.getFont()
    local text_width = font:getWidth(text)
    local text_height = font:getHeight()
    love.graphics.print(text, 
        (self.width - text_width) / 2,
        (self.height - text_height) / 2)
end

function progress_bar:set_progress(value)
    self.progress = math.max(0, math.min(1, value))
end

return progress_bar
```

使用自定义组件：

```lua
-- main.lua
local lumenGui = require("lumenGui")
local progress_bar = require("progress_bar")

-- 注册到 API
lumenGui.progress_bar = progress_bar

local gui = lumenGui:new()

local layout = {
    type = "line_layout",
    orientation = "vertical",
    width = 400,
    height = 200,
    padding = 20,
    
    {
        type = "progress_bar",
        id = "my_progress",
        width = "fill",
        height = 40,
        progress = 0.3
    },
    {
        type = "button",
        text = "增加进度",
        height = 40,
        on_click = function(self)
            local bar = gui:get_id_view("my_progress")
            bar:set_progress(bar.progress + 0.1)
        end
    }
}

function love.load()
    gui:add_view(gui:load_layout(layout))
end
```

**设计理念体现**:
- 继承基础视图类
- 自定义绘制逻辑
- 封装业务逻辑
- 注册到框架 API

---

## 完整应用示例

### 示例 7: 简单的任务管理器

```lua
local lumenGui = require("lumenGui")
local gui = lumenGui:new()

-- 任务数据模型
local TaskManager = {
    tasks = {},
    next_id = 1
}

function TaskManager:add_task(text)
    local task = {
        id = self.next_id,
        text = text,
        completed = false
    }
    table.insert(self.tasks, task)
    self.next_id = self.next_id + 1
    gui:publish_event("任务列表更新")
    return task
end

function TaskManager:toggle_task(id)
    for _, task in ipairs(self.tasks) do
        if task.id == id then
            task.completed = not task.completed
            gui:publish_event("任务列表更新")
            break
        end
    end
end

function TaskManager:remove_task(id)
    for i, task in ipairs(self.tasks) do
        if task.id == id then
            table.remove(self.tasks, i)
            gui:publish_event("任务列表更新")
            break
        end
    end
end

-- 创建任务项视图
function create_task_item(task)
    return {
        type = "line_layout",
        orientation = "horizontal",
        width = "fill",
        height = 40,
        padding = 5,
        backgroundColor = task.completed and "#E8F5E9" or "#FFFFFF",
        
        -- 完成复选框
        {
            type = "switch_button",
            width = 60,
            height = 30,
            is_on = task.completed,
            on_toggle = function(self, is_on)
                TaskManager:toggle_task(task.id)
            end
        },
        
        -- 任务文本
        {
            type = "text",
            text = task.text,
            textColor = task.completed and "#888888" or "#000000",
            textSize = 14,
            layout_weight = 1
        },
        
        -- 删除按钮
        {
            type = "button",
            text = "删除",
            width = 60,
            height = 30,
            backgroundColor = "#F44336",
            textColor = "#FFFFFF",
            on_click = function(self)
                TaskManager:remove_task(task.id)
            end
        }
    }
end

-- 主界面
local main_layout = {
    type = "line_layout",
    orientation = "vertical",
    width = "fill",
    height = "fill",
    
    -- 标题栏
    {
        type = "line_layout",
        orientation = "vertical",
        width = "fill",
        height = 100,
        backgroundColor = "#2196F3",
        padding = 20,
        
        {
            type = "text",
            text = "任务管理器",
            textSize = 24,
            textColor = "#FFFFFF",
            height = 40
        },
        {
            type = "text",
            id = "task_count",
            text = "总任务: 0",
            textSize = 14,
            textColor = "#E3F2FD",
            height = 30
        }
    },
    
    -- 添加任务区域
    {
        type = "line_layout",
        orientation = "horizontal",
        width = "fill",
        height = 60,
        padding = 10,
        backgroundColor = "#F5F5F5",
        
        {
            type = "edit_text",
            id = "task_input",
            text = "",
            width = "fill",
            height = 40,
            placeholder = "输入新任务..."
        },
        {
            type = "button",
            text = "添加",
            width = 80,
            height = 40,
            backgroundColor = "#4CAF50",
            textColor = "#FFFFFF",
            on_click = function(self)
                local input = gui:get_id_view("task_input")
                if input.text and input.text ~= "" then
                    TaskManager:add_task(input.text)
                    input.text = ""
                end
            end
        }
    },
    
    -- 任务列表容器
    {
        type = "slider_container",
        width = "fill",
        height = "fill",
        
        {
            type = "line_layout",
            id = "task_list",
            orientation = "vertical",
            width = "fill",
            -- height 会自动计算
        }
    }
}

-- 更新任务列表显示
function update_task_list()
    local task_list = gui:get_id_view("task_list")
    local task_count = gui:get_id_view("task_count")
    
    if not task_list then return end
    
    -- 清空现有任务
    task_list:remove_all_children()
    
    -- 添加所有任务
    for _, task in ipairs(TaskManager.tasks) do
        local item = gui:load_layout(create_task_item(task))
        task_list:add_view(item)
    end
    
    -- 更新计数
    if task_count then
        local completed = 0
        for _, task in ipairs(TaskManager.tasks) do
            if task.completed then
                completed = completed + 1
            end
        end
        task_count.text = string.format("总任务: %d | 已完成: %d", 
            #TaskManager.tasks, completed)
    end
end

function love.load()
    -- 创建主界面
    gui:add_view(gui:load_layout(main_layout))
    
    -- 订阅任务列表更新事件
    gui:on_event("任务列表更新", function()
        update_task_list()
    end)
    
    -- 初始化示例任务
    TaskManager:add_task("学习 snowGui 框架")
    TaskManager:add_task("阅读设计文档")
    TaskManager:add_task("创建第一个应用")
end

function love.update(dt)
    gui:update(dt)
end

function love.draw()
    love.graphics.clear(1, 1, 1)
    gui:draw()
end

-- 输入处理
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

function love.keypressed(key)
    gui:keypressed(key)
    
    -- Enter 键快速添加任务
    if key == "return" then
        local input = gui:get_id_view("task_input")
        if input and input.text ~= "" then
            TaskManager:add_task(input.text)
            input.text = ""
        end
    end
end

function love.textinput(text)
    gui:textinput(text)
end

function love.resize(width, height)
    gui:resize(width, height)
end
```

**设计理念体现**:
- 完整的应用架构
- MVC 模式 (Model-View-Controller)
- 事件驱动的数据更新
- 声明式 UI 定义
- 模块化组件设计
- 响应式布局

---

## 高级技巧

### 动态主题切换

```lua
local themes = {
    light = {
        background = "#FFFFFF",
        text = "#000000",
        primary = "#2196F3"
    },
    dark = {
        background = "#212121",
        text = "#FFFFFF",
        primary = "#BB86FC"
    }
}

function apply_theme(theme_name)
    local theme = themes[theme_name]
    for _, view in pairs(gui.views) do
        if view.backgroundColor then
            view.backgroundColor = theme.background
        end
        if view.textColor then
            view.textColor = theme.text
        end
    end
end
```

### 视图动画

```lua
-- 简单的淡入动画
local view = gui:get_id_view("my_view")
view.alpha = 0

function love.update(dt)
    gui:update(dt)
    
    if view.alpha < 1 then
        view.alpha = view.alpha + dt
        -- 更新背景色的 alpha 通道
        view.backgroundColor[4] = view.alpha
    end
end
```

### 视图池复用

```lua
local ViewPool = {
    pool = {},
    max_size = 20
}

function ViewPool:get(type)
    if #self.pool > 0 then
        local view = table.remove(self.pool)
        view.visible = true
        return view
    else
        return gui:load_layout({ type = type })
    end
end

function ViewPool:recycle(view)
    if #self.pool < self.max_size then
        view.visible = false
        table.insert(self.pool, view)
    end
end
```

---

## 总结

这些示例展示了 snowGui 框架的核心设计理念：

1. **组件化** - 一切皆组件，易于组合和复用
2. **声明式** - UI 结构清晰，易于理解和维护
3. **事件驱动** - 解耦组件，灵活响应变化
4. **响应式** - 自适应布局，适配不同屏幕
5. **可扩展** - 易于创建自定义组件
6. **跨平台** - 统一的 API，无缝支持多平台

通过这些示例，您可以快速上手 snowGui，并理解其设计思想。更多详细信息请参阅：

- [设计思路文档](./DESIGN.md)
- [架构文档](./ARCHITECTURE.md)
- [README](./README.md)
