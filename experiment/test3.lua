--增强版视图编辑器
local lumenGui = require("lumenGui")
local debugGraph = lumenGui.debugGraph
local CustomPrint = lumenGui.CustomPrint
local gui = lumenGui:new()

-- 编辑器状态管理
local EditorState = {
    current_file = nil,
    selected_view = nil,
    clipboard = nil,
    history = {},
    history_index = 0,
    grid_size = 10,
    grid_enabled = true,
    scene_gui = nil
}

-- 保存编辑器状态到历史记录
function EditorState:save_history()
    if self.scene_gui then
        table.insert(self.history, self.scene_gui:views_out_to_layout())
        self.history_index = #self.history
    end
end

-- 撤销操作
function EditorState:undo()
    if self.history_index > 1 then
        self.history_index = self.history_index - 1
        -- 重新加载布局
        self.scene_gui:clear_views()
        local layout = loadstring(self.history[self.history_index])()
        self.scene_gui:add_view(gui:load_layout(layout))
    end
end

-- 重做操作
function EditorState:redo()
    if self.history_index < #self.history then
        self.history_index = self.history_index + 1
        self.scene_gui:clear_views()
        local layout = loadstring(self.history[self.history_index])()
        self.scene_gui:add_view(gui:load_layout(layout))
    end
end

--初始化
function love.load(...)
    debugGraph:load(...)
    CustomPrint:load()

    -- 创建2D GUI编辑器
    local s2g = lumenGui.scene_2D_guiEditor:new({
        width = "fill",
        height = "fill",
        background_color = { 0.95, 0.95, 0.95, 1 }
    })
    EditorState.scene_gui = s2g.scene_gui

    -- 主布局
    local main_lay = {
        type = "line_layout",
        width = "fill",
        height = "fill",
        orientation = "vertical",

        -- 顶部菜单栏
        {
            type = "title_menu",
            items = {
                {
                    text = "文件",
                    items = {
                        {
                            text = "新建项目",
                            on_click = function(self, gui)
                                EditorState.scene_gui:clear_views()
                                EditorState.current_file = nil
                                EditorState:save_history()
                            end
                        },
                        {
                            text = "打开项目",
                            on_click = function(self, gui)
                                -- 调用文件选择对话框
                                gui:add_view(gui:load_layout({
                                    type = "file_select_dialog",
                                    on_select = function(path)
                                        EditorState.current_file = path
                                        -- 加载项目文件
                                    end
                                }))
                            end
                        },
                        {
                            text = "保存项目",
                            on_click = function(self, gui)
                                if EditorState.current_file then
                                    local layout = s2g.scene_gui:views_out_to_layout()
                                    -- 保存到文件
                                    love.filesystem.write(EditorState.current_file, layout)
                                    print("项目已保存到: " .. EditorState.current_file)
                                end
                            end
                        },
                        {
                            text = "另存为...",
                            on_click = function(self, gui)
                                -- 打开保存对话框
                                gui:add_view(gui:load_layout({
                                    type = "window",
                                    title = "另存为",
                                    {
                                        type = "line_layout",
                                        {
                                            type = "edit_text",
                                            hint = "输入文件名",
                                            id = "save_filename"
                                        },
                                        {
                                            type = "button",
                                            text = "保存",
                                            on_click = function()
                                                local filename = gui:get_id_view("save_filename").text
                                                local layout = s2g.scene_gui:views_out_to_layout()
                                                love.filesystem.write(filename, layout)
                                                EditorState.current_file = filename
                                            end
                                        }
                                    }
                                }))
                            end
                        },
                        {
                            text = "导出为Lua",
                            on_click = function(self, gui)
                                local layout = "return " .. s2g.scene_gui:views_out_to_layout()
                                local filename = "exported_layout_" .. os.time() .. ".lua"
                                love.filesystem.write(filename, layout)
                                print("已导出到: " .. filename)
                            end
                        }
                    },
                },
                {
                    text = "编辑",
                    items = {
                        {
                            text = "撤销 (Ctrl+Z)",
                            on_click = function(self, gui)
                                EditorState:undo()
                            end
                        },
                        {
                            text = "重做 (Ctrl+Y)",
                            on_click = function(self, gui)
                                EditorState:redo()
                            end
                        },
                        {
                            text = "复制 (Ctrl+C)",
                            on_click = function(self, gui)
                                if EditorState.selected_view then
                                    EditorState.clipboard = EditorState.selected_view:out_to_table()
                                end
                            end
                        },
                        {
                            text = "粘贴 (Ctrl+V)",
                            on_click = function(self, gui)
                                if EditorState.clipboard then
                                    s2g.scene_gui:add_view(gui:load_layout(EditorState.clipboard))
                                    EditorState:save_history()
                                end
                            end
                        },
                        {
                            text = "删除 (Del)",
                            on_click = function(self, gui)
                                if EditorState.selected_view then
                                    EditorState.selected_view:remove()
                                    EditorState.selected_view = nil
                                    EditorState:save_history()
                                end
                            end
                        }
                    }
                },
                {
                    text = "视图",
                    items = {
                        {
                            text = "网格: " .. (EditorState.grid_enabled and "开启" or "关闭"),
                            on_click = function(self, gui)
                                EditorState.grid_enabled = not EditorState.grid_enabled
                                self.text = "网格: " .. (EditorState.grid_enabled and "开启" or "关闭")
                            end
                        },
                        {
                            text = "网格大小",
                            items = {
                                { text = "5px",  on_click = function() EditorState.grid_size = 5 end },
                                { text = "10px", on_click = function() EditorState.grid_size = 10 end },
                                { text = "20px", on_click = function() EditorState.grid_size = 20 end },
                            }
                        }
                    }
                },
                {
                    text = "运行",
                    items = {
                        {
                            text = "窗口预览",
                            on_click = function(self, gui)
                                local lay_data = "return" .. (s2g.scene_gui:views_out_to_layout())
                                gui:add_view(gui:load_layout({
                                    type = "window",
                                    title = "预览",
                                    width = 600,
                                    height = 400,
                                    {
                                        type = "sandbox",
                                        env = {
                                            layout = lay_data
                                        }
                                    }
                                }))
                            end
                        },
                        {
                            text = "新窗口运行",
                            on_click = function(self, gui)
                                os.execute("start lovec ./")
                            end
                        },
                        {
                            text = "调试模式",
                            on_click = function(self, gui)
                                debugGraph.enabled = not debugGraph.enabled
                            end
                        }
                    }
                },
                {
                    text = "帮助",
                    items = {
                        {
                            text = "关于编辑器",
                            on_click = function(self, gui)
                                gui:add_view(gui:load_layout({
                                    type = "dialog",
                                    title = "关于",
                                    text = "snowGui 视图编辑器 v2.0\n用于纪念2025年的冬天\n作者: 北极企鹅"
                                }))
                            end
                        },
                        {
                            text = "快捷键",
                            on_click = function(self, gui)
                                gui:add_view(gui:load_layout({
                                    type = "window",
                                    title = "快捷键列表",
                                    {
                                        type = "text",
                                        text = [[
快捷键列表:
Ctrl+Z - 撤销
Ctrl+Y - 重做
Ctrl+C - 复制
Ctrl+V - 粘贴
Del - 删除
Ctrl+S - 保存
Ctrl+N - 新建
                                        ]]
                                    }
                                }))
                            end
                        }
                    }
                },
                {
                    text = "退出",
                    on_click = function(self, gui)
                        love.event.quit()
                    end
                }
            }
        }
    }

    -- 创建主布局
    local lin = gui:add_view(gui:load_layout(main_lay))

    -- 中间工作区 - 三分栏布局
    local workspace = gui:load_layout({
        type = "line_layout",
        width = "fill",
        height = "fill",
        orientation = "horizontal",
    })
    lin:add_view(workspace)

    -- 左侧：组件面板
    workspace:add_view(gui:load_layout({
        type = "border_container",
        width = 250,
        height = "fill",
        border_color = { 0.7, 0.7, 0.7, 1 },
        {
            type = "line_layout",
            orientation = "vertical",
            width = "fill",

            -- 基础视图
            {
                type = "fold_container",
                text = "📦 基础视图",
                is_fold = false,
                {
                    type = "list",
                    items = {
                        { text = "🔘 Button" },
                        { text = "📝 EditText" },
                        { text = "🖼️ Image" },
                        { text = "📋 List" },
                        { text = "☑️ SelectButton" },
                        { text = "🎚️ Slider" },
                        { text = "📑 SelectMenu" },
                        { text = "📄 Text" },
                        { text = "🔀 SwitchButton" },
                    },
                    item_on_click = function(self, count, text)
                        local type_name = text:match("%s(.+)"):lower():gsub(" ", "_")
                        s2g.scene_gui:add_view(gui:load_layout({
                            type = type_name,
                            text = type_name
                        }))
                        EditorState:save_history()
                    end
                }
            },

            -- 布局容器
            {
                type = "fold_container",
                text = "📐 布局容器",
                {
                    type = "list",
                    items = {
                        { text = "➖ LineLayout" },
                        { text = "📦 FrameLayout" },
                        { text = "⊞ GridLayout" },
                        { text = "⚖️ GravityLayout" },
                    },
                    item_on_click = function(self, count, text)
                        local type_name = text:match("%s(.+)"):lower():gsub(" ", "_")
                        s2g.scene_gui:add_view(gui:load_layout({
                            type = type_name,
                            width = 200,
                            height = 100
                        }))
                        EditorState:save_history()
                    end
                }
            },

            -- 容器组件
            {
                type = "fold_container",
                text = "🗂️ 容器组件",
                {
                    type = "list",
                    items = {
                        { text = "🖼️ BorderContainer" },
                        { text = "📁 FoldContainer" },
                        { text = "📜 SliderContainer" },
                        { text = "📑 TabControl" },
                        { text = "📋 TitleMenu" },
                        { text = "🌳 TreeManager" },
                        { text = "🪟 Window" },
                    },
                    item_on_click = function(self, count, text)
                        local type_name = text:match("%s(.+)"):lower():gsub(" ", "_")
                        s2g.scene_gui:add_view(gui:load_layout({ type = type_name }))
                        EditorState:save_history()
                    end
                }
            }
        }
    }))

    -- 中间：画布编辑区
    workspace:add_view(gui:load_layout({
        type = "border_container",
        width = "fill",
        height = "fill",
        border_color = { 0.5, 0.5, 0.5, 1 },
        -- 将 s2g 添加到这里
    }))
    workspace.children[2]:add_view(s2g)

    -- 右侧：属性面板
    workspace:add_view(gui:load_layout({
        type = "border_container",
        width = 300,
        height = "fill",
        border_color = { 0.7, 0.7, 0.7, 1 },
        {
            type = "line_layout",
            orientation = "vertical",
            width = "fill",

            -- 层级树
            {
                type = "fold_container",
                text = "🌲 层级结构",
                height = 300,
                {
                    type = "tree_manager",
                    id = "hierarchy_tree",
                    width = "200",
                    height = "200"
                }
            },

            -- 属性编辑器
            {
                type = "fold_container",
                text = "⚙️ 属性",
                is_fold = false,
                {
                    type = "slider_container",
                    width = "fill",
                    height = "fill",
                    {
                        type = "line_layout",
                        orientation = "vertical",
                        id = "properties_panel",
                        {
                            type = "text",
                            text = "选择一个视图以编辑属性",
                            color = { 0.5, 0.5, 0.5, 1 }
                        }
                    }
                }
            }
        }
    }))

    -- 保存初始历史记录
    EditorState:save_history()
end

-- 更新函数
function love.update(dt)
    gui:update(dt)
    debugGraph:update(dt)
    CustomPrint:update(dt)
end

-- 绘制函数
function love.draw()
    love.graphics.clear(1, 1, 1)

    -- 绘制网格（如果启用）
    if EditorState.grid_enabled then
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
        local w, h = love.graphics.getDimensions()
        for x = 0, w, EditorState.grid_size do
            love.graphics.line(x, 0, x, h)
        end
        for y = 0, h, EditorState.grid_size do
            love.graphics.line(0, y, w, y)
        end
    end

    gui:draw()
    love.graphics.setColor(0, 0, 0)
    debugGraph:draw()
    CustomPrint:draw()
end

-- 键盘输入
function love.keypressed(key)
    -- 快捷键处理
    if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
        if key == "z" then
            EditorState:undo()
        elseif key == "y" then
            EditorState:redo()
        elseif key == "c" then
            if EditorState.selected_view then
                EditorState.clipboard = EditorState.selected_view:out_to_table()
            end
        elseif key == "v" then
            if EditorState.clipboard then
                EditorState.scene_gui:add_view(gui:load_layout(EditorState.clipboard))
                EditorState:save_history()
            end
        elseif key == "s" then
            if EditorState.current_file then
                local layout = EditorState.scene_gui:views_out_to_layout()
                love.filesystem.write(EditorState.current_file, layout)
            end
        end
    elseif key == "delete" then
        if EditorState.selected_view then
            EditorState.selected_view:remove()
            EditorState.selected_view = nil
            EditorState:save_history()
        end
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

function love.directorydropped(path)
    gui:directorydropped(path)
end

function love.filedropped(file)
    gui:filedropped(file)
end

function love.visible(v)
    gui:visible(v)
end

function love.resize(width, height)
    gui:resize(width, height)
end
