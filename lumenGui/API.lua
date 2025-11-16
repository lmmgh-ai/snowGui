--font
local callerPath         = debug.getinfo(1, "S").source:sub(2)
local callerDir          = callerPath:match("(.*[/\\])") or "./"
ChineseFont              = (callerDir .. "font/YeZiGongChangTangYingHei-2.ttf")
--字体文件路径全局索引方便加载
--view
local view               = require("view.view")
local button             = require("view.button")
local switch_button      = require("view.switch_button")
local slider             = require("view.slider")
local list               = require("view.list")
local text               = require("view.text")
local edit_text          = require("view.edit_text")
local input_text         = require("view.input_text")
local image              = require("view.image")
local select_button      = require("view.select_button")
local select_menu        = require("view.select_menu")
local dialog             = require("container.dialog")
--layout
local line_layout        = require("layout.line_layout")
local gravity_layout     = require("layout.gravity_layout")
local grid_layout        = require("layout.grid_layout")
local frame_layout       = require("layout.frame_layout")
--container
local title_menu         = require("container.title_menu")
local tab_control        = require("container.tab_control")
local border_container   = require("container.border_container")
local fold_container     = require("container.fold_container")
local slider_container   = require("container.slider_container")
local window             = require("container.window")
local tree_manager       = require("container.tree_manager")
--function_widget
local scene_2D_guiEditor = require("function_widget.scene_2D_guiEditor")
local scene_2D           = require("function_widget.scene_2D")
local sandbox            = require("function_widget.sandbox")
local file_select_dialog = require("function_widget.file_select_dialog")
--libs
local Camera             = import "libs.Camera.Camera"
local Color              = import "libs.Color.Color"
local events_system      = import("libs.events_system")
local font_manger        = import "libs.font_manger" --单例模式
local CustomPrint        = import "libs.CustomPrint"
local debugGraph         = import "libs.debugGraph"
local nativefs           = import "libs.nativefs"
local fun                = import "fun"
--
local API                = {
    view = view,
    button = button,
    switch_button = switch_button,
    text = text,
    edit_text = edit_text,
    input_text = input_text,
    select_button = select_button,
    select_menu = select_menu,
    list = list,
    slider = slider,
    image = image,
    --
    line_layout = line_layout,
    gravity_layout = gravity_layout,
    grid_layout = grid_layout,
    frame_layout = frame_layout,
    --
    border_container = border_container,
    tab_control = tab_control,
    window = window,
    title_menu = title_menu,
    fold_container = fold_container,
    slider_container = slider_container,
    tree_manager = tree_manager,
    dialog = dialog,
    --
    scene_2D = scene_2D,
    scene_2D_guiEditor = scene_2D_guiEditor,
    sandbox = sandbox,
    file_select_dialog = file_select_dialog,
    --
    Camera = Camera,
    Color = Color,
    events_system = events_system,
    font_manger = font_manger,
    CustomPrint = CustomPrint,
    fun = fun,
    nativefs = nativefs,
    debugGraph = debugGraph
}


return API;
