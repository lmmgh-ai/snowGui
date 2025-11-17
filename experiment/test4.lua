--视图属性编辑器
local lumenGui = require("lumenGui")
local debugGraph = lumenGui.debugGraph
local CustomPrint = lumenGui.CustomPrint
local gui = lumenGui:new()

-- 属性编辑器状态
local PropertyEditor = {
    selected_view = nil,
    property_panel = nil,
    scene_editor = nil
}

-- 支持编辑的属性列表（按类型分组）
local EditableProperties = {
    -- 位置和尺寸
    transform = {
        { key = "x", name = "X坐标", type = "number", min = 0, max = 2000 },
        { key = "y", name = "Y坐标", type = "number", min = 0, max = 2000 },
        { key = "width", name = "宽度", type = "number", min = 0, max = 2000 },
        { key = "height", name = "高度", type = "number", min = 0, max = 2000 },
    },
    -- 文本属性
    text_props = {
        { key = "text", name = "文本", type = "string" },
        { key = "textSize", name = "字体大小", type = "number", min = 8, max = 100 },
    },
    -- 颜色属性
    colors = {
        { key = "backgroundColor", name = "背景色", type = "color" },
        { key = "textColor", name = "文字色", type = "color" },
        { key = "borderColor", name = "边框色", type = "color" },
        { key = "hoverColor", name = "悬停色", type = "color" },
        { key = "pressedColor", name = "按下色", type = "color" },
    },
    -- 状态属性
    state = {
        { key = "visible", name = "可见", type = "boolean" },
        { key = "id", name = "ID", type = "string" },
        { key = "type", name = "类型", type = "readonly" },
    }
}

-- 创建属性编辑控件
function PropertyEditor:create_property_widget(prop, view, property_panel)
    local widget_layout = {
        type = "line_layout",
        orientation = "horizontal",
        width = "fill",
        height = 35,
        padding = 5,
    }

    -- 属性名称标签
    table.insert(widget_layout, {
        type = "text",
        text = prop.name .. ":",
        width = 80,
        textColor = "#333333"
    })

    -- 根据属性类型创建不同的编辑控件
    if prop.type == "number" then
        -- 数字滑块
        table.insert(widget_layout, {
            type = "slider",
            width = "fill",
            height = 25,
            min = prop.min or 0,
            max = prop.max or 1000,
            value = view[prop.key] or 0,
            on_value_change = function(self, value)
                if PropertyEditor.selected_view then
                    PropertyEditor.selected_view[prop.key] = math.floor(value)
                    PropertyEditor.selected_view:_change_from_self()
                    PropertyEditor:refresh_property_display(prop.key, value)
                end
            end
        })
        
        -- 数值显示
        table.insert(widget_layout, {
            type = "text",
            text = tostring(math.floor(view[prop.key] or 0)),
            width = 50,
            id = "prop_display_" .. prop.key,
            textColor = "#0066cc"
        })

    elseif prop.type == "string" then
        -- 文本输入框
        table.insert(widget_layout, {
            type = "edit_text",
            width = "fill",
            height = 25,
            text = view[prop.key] or "",
            on_text_change = function(self, text)
                if PropertyEditor.selected_view then
                    PropertyEditor.selected_view[prop.key] = text
                    PropertyEditor.selected_view:_change_from_self()
                end
            end
        })

    elseif prop.type == "boolean" then
        -- 开关按钮
        table.insert(widget_layout, {
            type = "switch_button",
            width = 60,
            height = 25,
            is_on = view[prop.key] or false,
            on_toggle = function(self, is_on)
                if PropertyEditor.selected_view then
                    PropertyEditor.selected_view[prop.key] = is_on
                    PropertyEditor.selected_view:_change_from_self()
                end
            end
        })

    elseif prop.type == "color" then
        -- 颜色编辑器（简化版）
        local color_value = view[prop.key] or {1, 1, 1, 1}
        
        -- R通道
        table.insert(widget_layout, {
            type = "slider",
            width = 50,
            height = 20,
            min = 0,
            max = 1,
            value = color_value[1] or 1,
            on_value_change = function(self, value)
                if PropertyEditor.selected_view and PropertyEditor.selected_view[prop.key] then
                    PropertyEditor.selected_view[prop.key][1] = value
                end
            end
        })
        
        -- G通道
        table.insert(widget_layout, {
            type = "slider",
            width = 50,
            height = 20,
            min = 0,
            max = 1,
            value = color_value[2] or 1,
            on_value_change = function(self, value)
                if PropertyEditor.selected_view and PropertyEditor.selected_view[prop.key] then
                    PropertyEditor.selected_view[prop.key][2] = value
                end
            end
        })
        
        -- B通道
        table.insert(widget_layout, {
            type = "slider",
            width = 50,
            height = 20,
            min = 0,
            max = 1,
            value = color_value[3] or 1,
            on_value_change = function(self, value)
                if PropertyEditor.selected_view and PropertyEditor.selected_view[prop.key] then
                    PropertyEditor.selected_view[prop.key][3] = value
                end
            end
        })

    elseif prop.type == "readonly" then
        -- 只读文本
        table.insert(widget_layout, {
            type = "text",
            text = tostring(view[prop.key] or ""),
            width = "fill",
            textColor = "#666666"
        })
    end

    return widget_layout
end

-- 刷新属性显示
function PropertyEditor:refresh_property_display(prop_key, value)
    local display_id = "prop_display_" .. prop_key
    local display_view = gui:get_id_view(display_id)
    if display_view then
        display_view.text = tostring(math.floor(value))
    end
end

-- 更新属性面板
function PropertyEditor:update_property_panel(selected_view)
    self.selected_view = selected_view
    
    if not self.property_panel then
        return
    end
    
    -- 清空现有内容
    self.property_panel:remove_all_children()
    
    if not selected_view then
        -- 未选中视图，显示提示
        self.property_panel:add_view(gui:load_layout({
            type = "text",
            text = "请选择一个视图",
            textColor = "#999999",
            textSize = 14
        }))
        return
    end
    
    -- 显示视图信息标题
    self.property_panel:add_view(gui:load_layout({
        type = "line_layout",
        orientation = "vertical",
        width = "fill",
        {
            type = "text",
            text = "📋 " .. selected_view.type,
            textSize = 16,
            textColor = "#0066cc",
            height = 30
        },
        {
            type = "text",
            text = "ID: " .. (selected_view.id ~= "" and selected_view.id or "未设置"),
            textSize = 12,
            textColor = "#666666",
            height = 25
        }
    }))
    
    -- 创建各分组的属性编辑器
    -- 变换属性
    local transform_container = gui:load_layout({
        type = "fold_container",
        text = "🔧 变换",
        width = "fill",
        is_fold = false,
        {
            type = "line_layout",
            orientation = "vertical",
            width = "fill"
        }
    })
    self.property_panel:add_view(transform_container)
    
    for _, prop in ipairs(EditableProperties.transform) do
        if selected_view[prop.key] ~= nil then
            local widget = self:create_property_widget(prop, selected_view, self.property_panel)
            transform_container.children[1]:add_view(gui:load_layout(widget))
        end
    end
    
    -- 文本属性
    local has_text = selected_view.text or selected_view.textSize
    if has_text then
        local text_container = gui:load_layout({
            type = "fold_container",
            text = "📝 文本",
            width = "fill",
            {
                type = "line_layout",
                orientation = "vertical",
                width = "fill"
            }
        })
        self.property_panel:add_view(text_container)
        
        for _, prop in ipairs(EditableProperties.text_props) do
            if selected_view[prop.key] ~= nil then
                local widget = self:create_property_widget(prop, selected_view, self.property_panel)
                text_container.children[1]:add_view(gui:load_layout(widget))
            end
        end
    end
    
    -- 颜色属性
    local color_container = gui:load_layout({
        type = "fold_container",
        text = "🎨 颜色",
        width = "fill",
        is_fold = true,
        {
            type = "line_layout",
            orientation = "vertical",
            width = "fill"
        }
    })
    self.property_panel:add_view(color_container)
    
    for _, prop in ipairs(EditableProperties.colors) do
        if selected_view[prop.key] ~= nil then
            local widget = self:create_property_widget(prop, selected_view, self.property_panel)
            color_container.children[1]:add_view(gui:load_layout(widget))
        end
    end
    
    -- 状态属性
    local state_container = gui:load_layout({
        type = "fold_container",
        text = "⚙️ 状态",
        width = "fill",
        {
            type = "line_layout",
            orientation = "vertical",
            width = "fill"
        }
    })
    self.property_panel:add_view(state_container)
    
    for _, prop in ipairs(EditableProperties.state) do
        if selected_view[prop.key] ~= nil then
            local widget = self:create_property_widget(prop, selected_view, self.property_panel)
            state_container.children[1]:add_view(gui:load_layout(widget))
        end
    end
    
    -- 操作按钮
    self.property_panel:add_view(gui:load_layout({
        type = "line_layout",
        orientation = "vertical",
        width = "fill",
        padding = 10,
        {
            type = "button",
            text = "🗑️ 删除视图",
            width = "fill",
            height = 35,
            backgroundColor = "#ff4444",
            on_click = function(self)
                if PropertyEditor.selected_view then
                    PropertyEditor.selected_view:destroy()
                    PropertyEditor:update_property_panel(nil)
                end
            end
        },
        {
            type = "button",
            text = "📋 复制视图",
            width = "fill",
            height = 35,
            on_click = function(self)
                if PropertyEditor.selected_view then
                    local copied = PropertyEditor.selected_view:out_to_table()
                    -- 存储到剪贴板（简化版）
                    print("已复制视图配置")
                end
            end
        }
    }))
end

--初始化
function love.load(...)
    debugGraph:load(...)
    CustomPrint:load()

    -- 创建2D GUI编辑器场景
    local s2g = lumenGui.scene_2D_guiEditor:new({ 
        width = "fill", 
        height = "fill"
    })
    PropertyEditor.scene_editor = s2g

    -- 主布局
    local main_lay = {
        type = "line_layout",
        width = "fill",
        height = "fill",
        orientation = "vertical",
        
        -- 顶部菜单
        {
            type = "title_menu",
            items = {
                {
                    text = "文件",
                    items = {
                        { 
                            text = "导出布局",
                            on_click = function(self, gui)
                                local layout = "return " .. s2g.scene_gui:views_out_to_layout()
                                love.filesystem.write("exported_layout.lua", layout)
                                print("✅ 布局已导出到 exported_layout.lua")
                            end
                        }
                    }
                },
                {
                    text = "视图",
                    items = {
                        { text = "添加按钮", on_click = function() 
                            s2g.scene_gui:add_view(gui:load_layout({ type = "button", x = 100, y = 100 }))
                        end },
                        { text = "添加文本", on_click = function() 
                            s2g.scene_gui:add_view(gui:load_layout({ type = "text", x = 100, y = 100 }))
                        end },
                        { text = "添加输入框", on_click = function() 
                            s2g.scene_gui:add_view(gui:load_layout({ type = "edit_text", x = 100, y = 100 }))
                        end },
                    }
                },
                {
                    text = "退出",
                    on_click = function() love.event.quit() end
                }
            }
        }
    }

    local root = gui:add_view(gui:load_layout(main_lay))

    -- 工作区布局：左侧画布 + 右侧属性面板
    local workspace = gui:load_layout({
        type = "line_layout",
        orientation = "horizontal",
        width = "fill",
        height = "fill"
    })
    root:add_view(workspace)

    -- 左侧：画布编辑区
    local canvas_container = gui:load_layout({
        type = "border_container",
        width = "fill",
        height = "fill",
        border_color = "#888888"
    })
    workspace:add_view(canvas_container)
    canvas_container:add_view(s2g)

    -- 右侧：属性面板
    local property_container = gui:load_layout({
        type = "border_container",
        width = 350,
        height = "fill",
        border_color = "89CCCCCC",
        {
            type = "line_layout",
            orientation = "vertical",
            width = "fill",
            height = "fill",
            {
                type = "text",
                text = "⚙️ 属性编辑器",
                textSize = 18,
                height = 40,
                textColor = "#0066cc"
            },
            {
                type = "slider_container",
                width = "fill",
                height = "fill",
                {
                    type = "line_layout",
                    orientation = "vertical",
                    width = "fill",
                    id = "property_panel_content"
                }
            }
        }
    })
    workspace:add_view(property_container)

    -- 获取属性面板内容区域
    PropertyEditor.property_panel = gui:get_id_view("property_panel_content")

    -- 监听视图选中事件
    s2g:on_event("选中视图改变", function(selected_view)
        print("✅ 选中视图:", selected_view.type)
        PropertyEditor:update_property_panel(selected_view)
    end)

    -- 显示初始提示
    PropertyEditor:update_property_panel(nil)
end

-- 更新
function love.update(dt)
    gui:update(dt)
    debugGraph:update(dt)
    CustomPrint:update(dt)
end

-- 绘制
function love.draw()
    love.graphics.clear(1, 1, 1)
    gui:draw()
    love.graphics.setColor(0, 0, 0)
    debugGraph:draw()
    CustomPrint:draw()
end

-- 键盘输入
function love.keypressed(key)
    -- Delete键删除选中视图
    if key == "delete" and PropertyEditor.selected_view then
        PropertyEditor.selected_view:destroy()
        PropertyEditor:update_property_panel(nil)
    end
    gui:keypressed(key)
end

function love.textinput(text)
    gui:textinput(text)
end

-- 平台适配
if love.system.getOS() == "Android" then
    function love.touchpressed(id, x, y, dx, dy, pressure)
        gui:touchpressed(id, x, y, dx, dy, true, pressure)
    end
    function love.touchmoved(id, x, y, dx, dy, pressure)
        gui:touchmoved(id, x, y, dx, dy, true, pressure)
    end
    function love.touchreleased(id, x, y, dx, dy, pressure)
        gui:touchreleased(id, x, y, dx, dy, true, pressure)
    end
elseif love.system.getOS() == "Windows" then
    function love.mousemoved(x, y, dx, dy, istouch)
        gui:mousemoved(nil, x, y, dx, dy, istouch, nil)
    end
    function love.mousepressed(x, y, id, istouch, pressure)
        gui:mousepressed(id, x, y, nil, nil, istouch, pressure)
    end
    function love.mousereleased(x, y, id, istouch, pressure)
        gui:mousereleased(id, x, y, nil, nil, istouch, pressure)
    end
    function love.wheelmoved(x, y)
        gui:wheelmoved(nil, x, y)
    end
end

function love.quit()
    gui:quit()
end

function love.resize(width, height)
    gui:resize(width, height)
end