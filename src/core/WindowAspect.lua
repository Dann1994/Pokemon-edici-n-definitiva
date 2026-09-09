-- Force the running GAME (not the launcher) to a fixed display aspect.
--
-- Windowed: the window itself is snapped to the ratio and kept there through
-- every resize -- drag any edge and the other axis follows, so the window can
-- never sit at a non-16:9 shape.
-- Borderless fullscreen (or a window the OS refused to resize exactly):
-- Playfield.forceAspect makes Renderer letterbox the whole render into a
-- centred rect of the ratio, with the surround filled per UI LETTERBOX.
--
-- Desktop only.  Mobile / NX have a fixed display the game already letterboxes
-- into, and their windows are not user-resizable, so this is a no-op there.

local Playfield = require("src.render.Playfield")

local WindowAspect = {}

WindowAspect.DEFAULT_RATIO = 16 / 9
WindowAspect.ratio = WindowAspect.DEFAULT_RATIO
WindowAspect.active = false

local function isDesktop()
  if not (love and love.system and love.system.getOS) then return false end
  local os = love.system.getOS()
  return os == "Windows" or os == "OS X" or os == "Linux"
end

local function isWindowed()
  if not (love.window and love.window.getFullscreen) then return true end
  return not love.window.getFullscreen()
end

-- Snap the windowed window to WindowAspect.ratio by SHRINKING the axis that is
-- over-long: a too-wide (21:9) window loses width, a too-tall (4:3) one loses
-- height.  Never grows an axis, so the result always still fits the display
-- the over-sized window already fit.  A no-op once the window matches within
-- rounding, so the setMode it issues cannot loop.
function WindowAspect.snap()
  if not WindowAspect.active or not isDesktop() then return end
  if not (love.window and love.window.getMode and love.window.setMode) then return end
  if not isWindowed() then return end
  local w, h, flags = love.window.getMode()
  if not (w and h and w > 0 and h > 0) then return end
  local r = WindowAspect.ratio
  if math.abs(w / h - r) < 0.02 then return end
  local nw, nh = w, h
  if w / h > r then
    nw = math.max(1, math.floor(h * r + 0.5))
  else
    nh = math.max(1, math.floor(w / r + 0.5))
  end
  if nw == w and nh == h then return end
  love.window.setMode(nw, nh, flags)
end

function WindowAspect.enable(ratio)
  WindowAspect.ratio = (type(ratio) == "number" and ratio > 0)
    and ratio or WindowAspect.DEFAULT_RATIO
  WindowAspect.active = true
  Playfield.forceAspect = WindowAspect.ratio
  -- On the switch from the launcher (1024x768) a plain snap would leave a
  -- small 1024x576 window.  Open at a comfortable 16:9 that still fits the
  -- desktop, then let snap() take over from there.
  if isDesktop() and isWindowed()
     and love.window and love.window.getMode and love.window.setMode then
    local w, h, flags = love.window.getMode()
    local dw, dh = 1920, 1080
    if love.window.getDesktopDimensions then
      local gw, gh = love.window.getDesktopDimensions()
      if gw and gh and gw > 0 and gh > 0 then dw, dh = gw, gh end
    end
    local r = WindowAspect.ratio
    local tw = math.floor(math.min(dw * 0.9, (dh * 0.9) * r) + 0.5)
    local th = math.floor(tw / r + 0.5)
    if tw > (w or 0) and th > (h or 0) and tw >= 640 and th >= 360 then
      love.window.setMode(tw, th, flags)
      return
    end
  end
  WindowAspect.snap()
end

function WindowAspect.disable()
  WindowAspect.active = false
  Playfield.forceAspect = nil
end

-- love.resize hook (main.lua): keep the window locked to the ratio.
function WindowAspect.onResize()
  WindowAspect.snap()
end

return WindowAspect
