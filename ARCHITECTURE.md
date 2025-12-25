# snowGui Architecture Documentation

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Core Components](#core-components)
4. [Data Flow](#data-flow)
5. [Module Structure](#module-structure)
6. [Event System](#event-system)
7. [Rendering Pipeline](#rendering-pipeline)
8. [Input Processing](#input-processing)

---

## Overview

snowGui (lumenGui/lmGui) is a lightweight GUI framework built on LÖVE2D, providing a comprehensive solution for creating cross-platform graphical user interfaces in Lua.

**Key Characteristics:**
- Object-oriented design with prototype-based inheritance
- Event-driven architecture
- Layer-based rendering system
- Declarative UI support
- Cross-platform input abstraction

---

## System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     Application Layer                         │
│  (User Code - Game/App Logic, Event Handlers, UI Definitions)│
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│                    GUI Manager (gui.lua)                      │
│  ┌────────────┬──────────────┬───────────────┬─────────────┐ │
│  │ View Tree  │ Event System │ Input State   │ Font Manager│ │
│  │ Management │              │ Management    │             │ │
│  └────────────┴──────────────┴───────────────┴─────────────┘ │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│                      Component Layer                          │
│  ┌──────────┬────────────┬────────────────┬────────────────┐ │
│  │ Views    │ Layouts    │ Containers     │ Func Widgets   │ │
│  │ (button, │ (line,     │ (window,       │ (editor,       │ │
│  │  text,   │  grid,     │  dialog,       │  scene,        │ │
│  │  slider) │  gravity)  │  border)       │  sandbox)      │ │
│  └──────────┴────────────┴────────────────┴────────────────┘ │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│                      Library Layer                            │
│  ┌────────────┬──────────────┬─────────────┬──────────────┐  │
│  │ Color      │ Events       │ Camera      │ Native FS    │  │
│  │ Utils      │ System       │ System      │              │  │
│  └────────────┴──────────────┴─────────────┴──────────────┘  │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│                    LÖVE2D Framework                           │
│              (Graphics, Input, Window, Audio)                 │
└──────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. GUI Manager (`gui.lua`)

The central orchestrator responsible for:

**Properties:**
- `views` - Hash table of all views (with weak references)
- `tree_views` - Array of view arrays organized by layer (1-11)
- `input_state` - Current input state tracking
- `events_system` - Event pub-sub system instance
- `font_manger` - Global font management

**Key Methods:**
```lua
gui:new(config)              -- Create new GUI instance
gui:add_view(view)           -- Add view to management
gui:get_id_view(id)          -- Retrieve view by ID
gui:update(dt)               -- Update all views
gui:draw()                   -- Render all visible views
gui:load_layout(table)       -- Parse declarative layout
gui:on_event(name, callback) -- Subscribe to events
```

### 2. Base View (`view/view.lua`)

The foundation for all UI components:

**Core Properties:**
```lua
{
    type = "view",
    x, y, width, height,         -- Position and size
    visible = true,              -- Visibility flag
    parent = nil,                -- Parent view reference
    children = {},               -- Child views array
    _layer = 1,                  -- Rendering layer
    _draw_order = 1,             -- Drawing order in layer
    backgroundColor,             -- Background color
    textColor,                   -- Text color
    font,                        -- Font reference
    gui,                         -- GUI manager reference
}
```

**Lifecycle Methods:**
```lua
view:_init()                 -- Initialize instance
view:_on_create()            -- Called when added to GUI
view:_change_from_self()     -- Self-size changed
view:change_from_parent()    -- Parent-size changed
view:update(dt)              -- Frame update
view:draw()                  -- Custom drawing
view:_draw()                 -- System drawing (calls draw)
```

**Event Handlers:**
```lua
view:_on_hover()             -- Mouse/touch enters
view:off_hover()             -- Mouse/touch leaves
view:_mousepressed(id, x, y) -- Press event
view:_mousemoved(id, x, y)   -- Move event
view:_mousereleased(id, x, y)-- Release event
view:_on_click(id, x, y)     -- Click event
view:keypressed(key)         -- Keyboard press
view:textinput(text)         -- Text input
```

### 3. Layout System

Layouts manage child view positioning:

#### Line Layout (`layout/line_layout.lua`)
- Arranges children in a line (horizontal or vertical)
- Properties: `orientation`, `gravity`, `padding`
- Child properties: `layout_weight`, `layout_margin`

#### Grid Layout (`layout/grid_layout.lua`)
- Arranges children in a grid
- Properties: `columns`, `rows`

#### Gravity Layout (`layout/gravity_layout.lua`)
- Positions children based on gravity
- Properties: `gravity` (top, bottom, left, right, center)

#### Frame Layout (`layout/frame_layout.lua`)
- Overlapping children (z-order based)
- Simple stacking container

### 4. Container Components

Specialized containers with additional functionality:

- **Window** - Draggable, resizable window
- **Dialog** - Modal dialog box
- **Border Container** - Container with border decoration
- **Fold Container** - Collapsible container
- **Slider Container** - Scrollable container
- **Tab Control** - Tabbed interface
- **Title Menu** - Menu bar with dropdowns
- **Tree Manager** - Hierarchical tree view

### 5. Widget Components

Interactive UI elements:

- **Button** - Clickable button
- **Text** - Static text label
- **Edit Text** - Single-line text input
- **Input Text** - Multi-line text input
- **Slider** - Value slider
- **Switch Button** - Toggle switch
- **Select Button** - Radio button
- **Select Menu** - Dropdown menu
- **List** - Scrollable list
- **Image** - Image display

---

## Data Flow

### View Addition Flow

```
User Code
    ↓
gui:add_view(view)
    ↓
1. Parse layout if nested table
    ↓
2. Initialize view properties
    ↓
3. Set event system reference
    ↓
4. Insert into layer tree (tree_views[layer])
    ↓
5. Sort by draw order
    ↓
6. Add to views hash table
    ↓
7. Call view:_on_create()
    ↓
8. Process children recursively
    ↓
9. Call view:_change_from_self()
    ↓
View ready for rendering
```

### Input Event Flow

```
LÖVE2D Input Event
    ↓
Platform-specific handler
(mousepressed/touchpressed)
    ↓
gui:mousepressed(id, x, y)
    ↓
1. Check hover_view
    ↓
2. Validate containsPoint(x, y)
    ↓
3. Update input_state
    ↓
4. Update keypressed_view (focus)
    ↓
5. Call view:_mousepressed(id, x, y)
    ↓
View processes event
    ↓
Event may bubble to parent
or be intercepted
```

### Rendering Flow

```
love.draw()
    ↓
gui:draw()
    ↓
Iterate tree_views[1] (top layer)
    ↓
For each view in layer
    ↓
1. Check visibility
    ↓
2. Call view:_draw()
    ↓
3. Push graphics state
    ↓
4. Translate to view position
    ↓
5. Call view:draw() (custom)
    ↓
6. Recursively draw children
    ↓
7. Pop graphics state
    ↓
Next view
```

---

## Module Structure

```
lumenGui/
├── init.lua                 # Package entry point
├── gui.lua                  # GUI manager core
├── API.lua                  # Component registry
│
├── view/                    # Basic view components
│   ├── view.lua            # Base view class
│   ├── button.lua
│   ├── text.lua
│   ├── slider.lua
│   ├── edit_text.lua
│   └── ...
│
├── layout/                  # Layout containers
│   ├── line_layout.lua
│   ├── grid_layout.lua
│   ├── gravity_layout.lua
│   └── frame_layout.lua
│
├── container/               # Specialized containers
│   ├── window.lua
│   ├── dialog.lua
│   ├── border_container.lua
│   ├── tab_control.lua
│   └── ...
│
├── function_widget/         # Complex functional widgets
│   ├── scene_2D_guiEditor.lua
│   ├── scene_2D.lua
│   ├── sandbox.lua
│   └── file_select_dialog.lua
│
└── libs/                    # Utility libraries
    ├── events_system.lua   # Pub-sub system
    ├── font_manger.lua     # Font management
    ├── Color/              # Color utilities
    ├── Camera/             # Camera system
    ├── CustomPrint.lua     # Debug printing
    ├── debugGraph.lua      # Performance graphs
    └── nativefs/           # Native filesystem access
```

---

## Event System

### Architecture

The event system uses the Observer (Pub-Sub) pattern:

```lua
events_system = {
    subscribers = {
        ["event_name"] = {
            [sub_id] = {
                callback = function,
                once = boolean,
                subscriber = object
            }
        }
    }
}
```

### Event Registration

```lua
-- Subscribe to event
local sub_id = gui:on_event("custom_event", function(data)
    print("Event received:", data)
end, self)

-- One-time subscription
gui:once_event("init_complete", function()
    print("Initialization done")
end)

-- Publish event
gui:publish_event("custom_event", { value = 42 })

-- Unsubscribe
gui:unsubscribeById("custom_event", sub_id)
```

### Built-in Events

- View lifecycle events (creation, destruction)
- Focus change events
- Selection change events
- Custom user-defined events

---

## Rendering Pipeline

### Layer System

Views are organized into 11 layers (1-11):

```lua
tree_views = {
    [1] = { view1, view2, ... },  -- Top layer (dialogs)
    [2] = { view3, view4, ... },  -- Main UI
    [3] = { view5, view6, ... },  -- Secondary UI
    ...
    [11] = { ... }                 -- Bottom layer (background)
}
```

**Drawing Rules:**
1. Lower layer numbers draw on top
2. Within a layer, higher `_draw_order` draws on top
3. Children always draw after their parent

### Graphics State Management

```lua
function view:_draw()
    love.graphics.push()              -- Save state
    love.graphics.translate(x, y)     -- Transform
    
    -- Clip to bounds if needed
    love.graphics.setScissor(x, y, width, height)
    
    self:draw()                        -- Custom drawing
    
    for _, child in ipairs(children) do
        child:_draw()                  -- Recursive
    end
    
    love.graphics.setScissor()         -- Remove clip
    love.graphics.pop()                -- Restore state
end
```

---

## Input Processing

### Hit Testing

```lua
function view:containsPoint(x, y)
    return x >= self.x 
       and x <= self.x + self.width
       and y >= self.y 
       and y <= self.y + self.height
end
```

### Event Interception

Views can intercept events to prevent propagation:

```lua
function view:_event_intercept(x, y, child)
    -- Return false to block event to child
    -- Return true to allow propagation
    return true
end
```

### Focus Management

```lua
input_state = {
    layer = nil,              -- Focused layer
    hover_view = nil,         -- View under cursor/touch
    pressed_views = {},       -- Currently pressed views
    keypressed_view = nil,    -- View with keyboard focus
}
```

### Multi-touch Support (Android)

```lua
-- Up to 10 simultaneous touches
pressed_views[1] = view1  -- First touch
pressed_views[2] = view2  -- Second touch
-- ...
```

Touch IDs are mapped from userdata to numeric indices.

---

## Memory Management

### Weak References

```lua
views = setmetatable({}, { __mode = 'kv' })
```

Views use weak references to prevent memory leaks from circular references.

### View Lifecycle

```
Creation → Addition → Active → Removal → Garbage Collection
```

Views are automatically garbage collected when no strong references remain.

---

## Performance Considerations

### Optimization Techniques

1. **Visibility Culling**: Don't update/draw invisible views
2. **Event Bubbling**: Stop at first matching view
3. **Layer Organization**: Minimize overlapping layers
4. **Lazy Font Loading**: Load fonts on-demand
5. **Weak References**: Automatic memory cleanup

### Profiling Tools

```lua
local debugGraph = require("lumenGui.libs.debugGraph")
debugGraph:update(dt)  -- In love.update
debugGraph:draw()      -- In love.draw
```

---

## Extension Points

### Creating Custom Views

```lua
local view = require("lumenGui.view.view")
local custom = view:new()

function custom:new(config)
    -- Initialize with defaults
    local obj = view.new(self, config)
    obj.type = "custom"
    return obj
end

function custom:draw()
    -- Custom rendering
end

return custom
```

### Adding to API

```lua
-- In API.lua
local custom = require(lumenGui_path .. ".view.custom")
API.custom = custom
```

### Layout Algorithms

Layouts implement `change_from_self()` to calculate child positions:

```lua
function layout:change_from_self()
    -- Calculate available space
    -- Position each child
    -- Call child:change_from_parent()
end
```

---

## Thread Safety

**Note**: LÖVE2D and Lua are single-threaded for graphics operations. snowGui is designed for single-threaded use. If using `love.thread`, ensure GUI operations only occur on the main thread.

---

## Debugging Tips

1. **Visual Debug Mode**: Draw view boundaries
2. **Event Logging**: Print event flow
3. **Layer Visualization**: Color-code layers
4. **Performance Monitoring**: Use debugGraph
5. **Layout Export**: Export current UI to Lua file

---

## Best Practices

1. Keep view trees shallow (< 5 levels)
2. Use appropriate layout types
3. Set meaningful IDs for important views
4. Unsubscribe from events when views are destroyed
5. Use weak references for custom caches
6. Profile performance regularly
7. Test on target platforms early

---

**Author**: 北极企鹅 (Arctic Penguin)  
**Framework Version**: 3.1  
**Year**: 2025
