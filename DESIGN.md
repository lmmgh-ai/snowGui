# snowGui 设计思路文档 (Design Philosophy)

## 概述 (Overview)

snowGui（也称为 lumenGui 或 lmGui）是一个基于 LÖVE2D 框架开发的轻量级 GUI 框架，提供跨平台支持。本文档详细介绍了框架的核心设计理念和架构思想。

**作者**: 北极企鹅  
**年份**: 2025  
**框架版本**: 3.1

---

## 核心设计理念 (Core Design Philosophy)

### 1. 组件化与继承 (Component-Based & Inheritance)

snowGui 采用面向对象的设计模式，所有 UI 组件都继承自基础 `view` 类：

```
view (基类)
├── button (按钮)
├── text (文本)
├── slider (滑块)
├── line_layout (线性布局)
├── grid_layout (网格布局)
└── ... (其他组件)
```

**设计优势**:
- 代码复用：共享基础功能（如事件处理、绘制逻辑）
- 易于扩展：新组件只需继承并重写特定方法
- 统一接口：所有组件具有一致的 API

### 2. 分层架构 (Layered Architecture)

框架采用三层架构设计：

```
┌─────────────────────────────────────┐
│   应用层 (Application Layer)        │
│   - 用户界面逻辑                    │
│   - 事件回调处理                    │
└─────────────────────────────────────┘
          ↓
┌─────────────────────────────────────┐
│   GUI 管理层 (GUI Manager Layer)    │
│   - 视图生命周期管理                │
│   - 事件分发系统                    │
│   - 输入状态管理                    │
└─────────────────────────────────────┘
          ↓
┌─────────────────────────────────────┐
│   组件层 (Component Layer)          │
│   - 基础视图 (view)                 │
│   - 布局容器 (layouts)              │
│   - UI 控件 (widgets)               │
└─────────────────────────────────────┘
```

### 3. 事件驱动架构 (Event-Driven Architecture)

框架使用发布-订阅模式 (Pub-Sub) 管理事件：

```lua
-- 订阅事件
gui:on_event("事件名称", function(data)
    -- 处理事件
end)

-- 发布事件
gui:publish_event("事件名称", data)
```

**核心事件类型**:
- 输入事件：鼠标、触摸、键盘
- 视图事件：创建、销毁、焦点变化
- 自定义事件：用户定义的业务逻辑

### 4. 图层系统 (Layer System)

snowGui 使用多图层管理来组织视图的渲染顺序：

```
图层 1 (Layer 1) - 顶层窗口、对话框
图层 2 (Layer 2) - 主界面元素
图层 3 (Layer 3) - 背景元素
...
图层 11 (Layer 11) - 最底层
```

**特点**:
- 每个视图都有 `_layer` 和 `_draw_order` 属性
- 图层数值越小，渲染优先级越高
- 同一图层内按 `_draw_order` 排序

### 5. 响应式布局 (Responsive Layout)

框架支持多种布局策略：

#### a) 线性布局 (Line Layout)
```lua
{
    type = "line_layout",
    orientation = "vertical",  -- 或 "horizontal"
    children = { ... }
}
```

#### b) 网格布局 (Grid Layout)
```lua
{
    type = "grid_layout",
    columns = 3,
    rows = 3,
    children = { ... }
}
```

#### c) 重力布局 (Gravity Layout)
```lua
{
    type = "gravity_layout",
    gravity = "center",  -- top, bottom, left, right, center
    children = { ... }
}
```

#### d) 帧布局 (Frame Layout)
```lua
{
    type = "frame_layout",
    children = { ... }  -- 子视图重叠显示
}
```

### 6. 灵活的尺寸系统 (Flexible Sizing System)

支持多种尺寸定义方式：

```lua
-- 固定像素
width = 200

-- 填充父容器
width = "fill"

-- 自适应内容
width = "wrap"

-- 权重分配 (在 line_layout 中)
layout_weight = 1  -- 按权重分配剩余空间
```

### 7. 声明式 UI (Declarative UI)

支持通过 Lua 表声明式创建界面：

```lua
local layout = {
    type = "line_layout",
    orientation = "vertical",
    width = "fill",
    height = "fill",
    
    {
        type = "text",
        text = "标题",
        textSize = 20,
        height = 40
    },
    
    {
        type = "button",
        text = "点击我",
        on_click = function(self)
            print("按钮被点击")
        end
    }
}

gui:add_view(gui:load_layout(layout))
```

**优势**:
- 易于理解和维护
- 可以从文件加载布局
- 支持热重载

### 8. 输入抽象层 (Input Abstraction)

统一处理不同平台的输入：

```
Windows/Linux:
- mousemoved → gui:mousemoved
- mousepressed → gui:mousepressed
- mousereleased → gui:mousereleased

Android:
- touchpressed → gui:touchpressed
- touchmoved → gui:touchmoved
- touchreleased → gui:touchreleased
```

内部统一处理为：
- `_mousemoved` - 移动事件
- `_mousepressed` - 按下事件
- `_mousereleased` - 释放事件
- `_on_click` - 点击事件

### 9. 视图生命周期 (View Lifecycle)

每个视图都经历以下生命周期：

```
创建 (Creation)
  ↓
初始化 (_init)
  ↓
添加到 GUI (_on_create)
  ↓
尺寸变化 (_change_from_self)
  ↓
更新循环 (update)
  ↓
绘制循环 (_draw)
  ↓
销毁 (destroy)
```

**关键回调函数**:
- `_init()` - 对象初始化
- `_on_create()` - 添加到管理器时调用
- `_change_from_self()` - 自身尺寸改变
- `change_from_parent()` - 父视图尺寸改变
- `update(dt)` - 每帧更新
- `draw()` - 绘制视图

---

## 关键设计模式 (Key Design Patterns)

### 1. 单例模式 (Singleton Pattern)

用于全局资源管理：

```lua
-- 字体管理器
local font_manger = require("lumenGui.libs.font_manger")
-- 所有 GUI 实例共享同一个字体管理器
```

### 2. 组合模式 (Composite Pattern)

视图树结构：

```lua
view = {
    children = {},  -- 子视图列表
    parent = nil,   -- 父视图引用
}
```

允许统一处理单个视图和视图组合。

### 3. 观察者模式 (Observer Pattern)

事件系统的核心：

```lua
events_system = {
    subscribers = {},  -- 订阅者列表
    
    subscribe = function(eventName, callback) end,
    publish = function(eventName, ...) end,
    unsubscribe = function(eventName, subId) end
}
```

### 4. 策略模式 (Strategy Pattern)

不同的布局算法：

```lua
-- 线性布局策略
line_layout:change_from_self()

-- 网格布局策略
grid_layout:change_from_self()

-- 重力布局策略
gravity_layout:change_from_self()
```

每种布局都实现自己的尺寸计算逻辑。

### 5. 模板方法模式 (Template Method Pattern)

视图基类定义算法骨架：

```lua
function view:_draw()
    if not self.visible then return end
    
    -- 1. 保存状态
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    
    -- 2. 调用子类实现 (模板方法)
    self:draw()
    
    -- 3. 绘制子视图
    for _, child in ipairs(self.children) do
        child:_draw()
    end
    
    -- 4. 恢复状态
    love.graphics.pop()
end
```

---

## 内存管理 (Memory Management)

### 弱引用表 (Weak Tables)

```lua
views = setmetatable({}, { __mode = 'kv' })
```

- 避免循环引用导致的内存泄漏
- 自动清理不再使用的视图

### 对象池 (Object Pooling)

虽然当前版本未实现，但设计上支持对象池模式来优化频繁创建/销毁的对象。

---

## 跨平台设计 (Cross-Platform Design)

### 平台检测

```lua
if love.system.getOS() == "Windows" then
    -- Windows 特定代码
elseif love.system.getOS() == "Android" then
    -- Android 特定代码
end
```

### 输入统一

框架内部将不同平台的输入事件统一为相同的接口，应用层无需关心平台差异。

### 触摸 ID 映射 (Android)

```lua
function gui.get_touch_id(id)
    -- 将 userdata 类型的触摸 ID 转换为数字索引
    if (tostring(id) == "userdata: NULL") then
        return 1
    elseif (tostring(id) == "userdata: 0x00000001") then
        return 2
    -- ...
end
```

支持最多 10 点触控。

---

## 扩展性设计 (Extensibility Design)

### 1. 自定义组件

创建新组件非常简单：

```lua
local view = require("lumenGui.view.view")
local my_widget = view:new()
my_widget.__index = my_widget

function my_widget:new(tab)
    local new_obj = {
        type = "my_widget",
        -- 自定义属性
    }
    for i, c in pairs(tab or {}) do
        new_obj[i] = c
    end
    new_obj.__index = new_obj
    setmetatable(new_obj, self)
    new_obj:_init()
    return new_obj
end

function my_widget:draw()
    -- 自定义绘制逻辑
end

return my_widget
```

### 2. 插件系统

通过事件系统实现插件机制：

```lua
-- 插件订阅框架事件
gui:on_event("视图创建", function(view)
    -- 插件逻辑
end)
```

### 3. 主题系统

通过颜色属性实现主题切换：

```lua
-- 定义主题
local theme = {
    backgroundColor = "#2C3E50",
    textColor = "#ECF0F1",
    primaryColor = "#3498DB"
}

-- 应用主题
for _, view in pairs(gui.views) do
    view.backgroundColor = theme.backgroundColor
    view.textColor = theme.textColor
end
```

---

## 性能优化 (Performance Optimization)

### 1. 懒加载 (Lazy Loading)

只在需要时加载资源：

```lua
-- 字体延迟加载
function view:get_font()
    if not self._font_cache then
        self._font_cache = self.gui:get_font(self.font, self.textSize)
    end
    return self._font_cache
end
```

### 2. 脏标记 (Dirty Flag)

只在必要时重新计算：

```lua
function view:_change_from_self()
    self._dirty = true
end

function view:update(dt)
    if self._dirty then
        self:recalculate()
        self._dirty = false
    end
end
```

### 3. 事件冒泡优化

从顶层向底层扫描，找到第一个匹配的视图后立即中断：

```lua
-- 从上到下扫描
for i = #tree_views, 1, -1 do
    if view:containsPoint(x, y) then
        -- 处理事件
        return  -- 中断后续扫描
    end
end
```

### 4. 可见性剪裁

不可见的视图不参与更新和绘制：

```lua
function view:draw()
    if not self.visible then return end
    -- 绘制逻辑
end
```

---

## 调试与开发工具 (Debugging & Development Tools)

### 1. 可视化编辑器

框架提供了可视化的 GUI 编辑器 (`scene_2D_guiEditor`)：

- 实时预览界面
- 拖拽创建组件
- 属性面板编辑
- 布局导出功能

### 2. 调试输出

```lua
local debugGraph = require("lumenGui.libs.debugGraph")
local CustomPrint = require("lumenGui.libs.CustomPrint")

-- 性能监控
debugGraph:draw()

-- 自定义打印
CustomPrint:draw()
```

### 3. 布局导出

将当前界面导出为 Lua 代码：

```lua
local layout_code = gui:views_out_to_layout()
love.filesystem.write("layout.lua", "return " .. layout_code)
```

---

## 最佳实践 (Best Practices)

### 1. 使用声明式布局

```lua
-- 推荐
local layout = gui:load_layout({
    type = "line_layout",
    { type = "button", text = "按钮" }
})

-- 不推荐
local layout = line_layout:new()
local button = button:new({ text = "按钮" })
layout:add_view(button)
```

### 2. 合理使用图层

- 图层 1：对话框、弹出窗口
- 图层 2-3：主界面
- 图层 4+：背景和装饰

### 3. 避免深层嵌套

限制视图树深度在 5 层以内，保持界面结构清晰。

### 4. 使用 ID 引用视图

```lua
{
    type = "button",
    id = "submit_button",  -- 设置 ID
    text = "提交"
}

-- 通过 ID 访问
local button = gui:get_id_view("submit_button")
```

### 5. 及时清理事件订阅

```lua
local sub_id = gui:on_event("事件", callback)

-- 不再需要时取消订阅
gui:unsubscribeById("事件", sub_id)
```

---

## 设计哲学总结 (Design Philosophy Summary)

1. **简洁性 (Simplicity)**: API 设计简洁直观，易于学习
2. **灵活性 (Flexibility)**: 支持多种布局和组件组合
3. **可扩展性 (Extensibility)**: 易于添加新组件和功能
4. **跨平台 (Cross-Platform)**: 统一的 API，无缝支持多平台
5. **性能优先 (Performance First)**: 优化渲染和事件处理
6. **开发者友好 (Developer Friendly)**: 提供调试工具和可视化编辑器

---

## 未来发展方向 (Future Directions)

1. **动画系统**: 支持补间动画和物理动画
2. **数据绑定**: 实现 MVVM 模式的数据绑定
3. **国际化**: 多语言支持
4. **无障碍访问**: 屏幕阅读器支持
5. **3D UI**: 支持 3D 空间中的 UI 渲染
6. **Web 导出**: 支持导出为 Web 应用

---

## 参考资源 (References)

- [LÖVE2D 官方文档](https://love2d.org/wiki/Main_Page)
- [Lua 编程指南](https://www.lua.org/manual/5.1/)
- 框架源码：`/lumenGui/`

---

**维护者**: 北极企鹅  
**最后更新**: 2025
