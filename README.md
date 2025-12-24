# snowGui 用于纪念2025年即将到来和终将逝去的冬天

snowGui (lumenGui/lmGui) 是基于 LÖVE2D 开发的轻量级 GUI 框架，提供跨平台支持。

## 📚 文档 (Documentation)

**🎓 新手入门**: 从 [学习指南 (Learning Guide)](./LEARNING_GUIDE.md) 开始，系统学习框架设计思路

**完整文档**:
- [学习指南 (Learning Guide)](./LEARNING_GUIDE.md) - 系统学习路径和设计思路总结 ⭐
- [设计思路文档 (Design Philosophy)](./DESIGN.md) - 详细介绍框架的核心设计理念
- [架构文档 (Architecture)](./ARCHITECTURE.md) - 系统架构和技术细节
- [实践示例 (Examples)](./EXAMPLES.md) - 完整的代码示例和最佳实践
- [可视化架构图 (Diagrams)](./DIAGRAMS.md) - ASCII 图表展示框架架构

## ✨ 特性 (Features)

- 🎨 组件化设计 - 基于继承的面向对象架构
- 📱 跨平台支持 - Windows、Android、Linux
- 🔄 事件驱动 - 发布-订阅模式的事件系统
- 🎯 多种布局 - 线性、网格、重力、帧布局
- 🎭 图层系统 - 灵活的渲染层级管理
- 📝 声明式 UI - 使用 Lua 表定义界面
- 🛠️ 可视化编辑器 - 实时预览和属性编辑
- ⚡ 性能优化 - 弱引用、懒加载、事件剪枝

## 🚀 快速开始 (Quick Start)

```lua
-- 引入框架
local lumenGui = require("lumenGui")
local gui = lumenGui:new()

-- 创建界面
local layout = {
    type = "line_layout",
    orientation = "vertical",
    width = "fill",
    height = "fill",
    
    {
        type = "text",
        text = "Hello snowGui!",
        textSize = 20
    },
    
    {
        type = "button",
        text = "点击我",
        on_click = function(self)
            print("按钮被点击了！")
        end
    }
}

function love.load()
    gui:add_view(gui:load_layout(layout))
end

function love.update(dt)
    gui:update(dt)
end

function love.draw()
    gui:draw()
end
```

## 📦 组件库 (Components)

### 视图组件 (Views)
- Button (按钮)
- Text (文本)
- Slider (滑块)
- Edit Text (输入框)
- Image (图片)
- Switch Button (开关)
- Select Menu (下拉菜单)

### 布局容器 (Layouts)
- Line Layout (线性布局)
- Grid Layout (网格布局)
- Gravity Layout (重力布局)
- Frame Layout (帧布局)

### 特殊容器 (Containers)
- Window (窗口)
- Dialog (对话框)
- Tab Control (标签页)
- Fold Container (折叠容器)
- Slider Container (滚动容器)
- Border Container (边框容器)
- Tree Manager (树形管理器)

## 🎓 示例 (Examples)

查看 `experiment/` 目录下的示例文件：

- `test.lua` - 基础框架演示
- `test1.lua` - 视图生成方式（解析式和面向对象）
- `test2.lua` - 简单的视图编辑器
- `test3.lua` - AI 编写的视图编辑器
- `test4.lua` - 视图属性编辑器（当前运行）

运行示例：在 `main.lua` 中取消注释对应的 require 语句。

## 🔧 开发工具 (Development Tools)

- **可视化编辑器** - 拖拽创建界面，实时预览
- **属性面板** - 动态编辑组件属性
- **布局导出** - 导出界面为 Lua 代码
- **调试图表** - 性能监控和 FPS 显示
- **自定义打印** - 增强的控制台输出

## 📖 核心概念 (Core Concepts)

详见 [设计思路文档](./DESIGN.md)，包括：

1. 组件化与继承
2. 分层架构
3. 事件驱动架构
4. 图层系统
5. 响应式布局
6. 灵活的尺寸系统
7. 声明式 UI
8. 输入抽象层
9. 视图生命周期

## 🤝 贡献 (Contributing)

欢迎提交 Issue 和 Pull Request！

## 📄 许可 (License)

请查看项目许可证文件。

## 👤 作者 (Author)

**北极企鹅** - 2025
