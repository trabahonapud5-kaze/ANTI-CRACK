require "import"

-- 🟢 1. HTTP MODULE SAFE SETUP
pcall(function() import "http" end)
Http = Http or http
http = http or Http

-- 🟢 2. JSON & CJSON SAFE FALLBACK SETUP
pcall(function() import "json" end)
pcall(function() import "cjson" end)

json = json or JSON
cjson = cjson or json

if not cjson or not json then
  pcall(function()
    import "org.json.JSONObject"
    import "org.json.JSONArray"
    local jsonHandler = {
      decode = function(str) return JSONObject(str) end,
      encode = function(obj) return tostring(obj) end
    }
    cjson = cjson or jsonHandler
    json = json or jsonHandler
  end)
end

-- 🟢 3. ANDROID UI, GRAPHICS, AT SYSTEM IMPORTS
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.net.*"

-- Graphics
import "android.graphics.Typeface"
import "android.graphics.PixelFormat"
import "android.graphics.PorterDuff"
import "android.graphics.PorterDuffColorFilter"
import "android.graphics.drawable.ColorDrawable"
import "android.graphics.drawable.GradientDrawable"
import "android.graphics.drawable.ShapeDrawable"
import "android.graphics.drawable.shapes.OvalShape"
import "android.graphics.Shader"
import "android.graphics.RadialGradient"
import "android.graphics.SweepGradient"
import "android.graphics.Paint"
import "android.graphics.Matrix"

-- System / Device
import "android.provider.Settings"
import "android.provider.Settings$Secure"
import "android.content.pm.ActivityInfo"
import "android.content.pm.PackageManager"
import "android.content.res.ColorStateList"
import "android.os.Environment"
import "android.os.Handler"
import "android.os.Build"

-- Media / Audio
import "android.media.MediaPlayer"
import "android.media.AudioManager"
import "android.speech.tts.TextToSpeech"

-- Animation
import "android.view.animation.TranslateAnimation"
import "android.animation.ValueAnimator"

-- Network / File IO / Java
import "java.net.URL"
import "java.net.HttpURLConnection"
import "java.net.URLEncoder"
import "android.net.ConnectivityManager"
import "java.io.File"
import "java.io.FileInputStream"
import "java.io.DataOutputStream"
import "java.io.BufferedReader"
import "java.io.InputStreamReader"
import "java.lang.String"
import "java.lang.Runtime"
import "java.util.Locale"

-- AndLua Layout Files
import "layout"
import "floating"
import "icon"
import "watermarkz"

import "android.widget.Toast"
import "android.view.WindowManager"
import "android.view.Gravity"
import "android.view.MotionEvent"

function syncAnnouncement()
  local url = "https://pastehub-dwp9.onrender.com/raw/SPCTAr6K"
  Http.get(url, nil, "utf-8", nil, function(code, body)
    if code == 200 then
      local status, data = pcall(function() return cjson.decode(body) end)
      if status and data then
        activity.runOnUiThread(Runnable{
          run=function()
            if announcement_title then announcement_title.Text = data.title end
            if announcement_msg then announcement_msg.Text = data.message end
          end
        })
      end
    end
  end)
end

-- 🟢 5. SINGLE INITIALIZATION OF FLOATING & ICON LAYOUTS (FIXED DUPLICATION)
win_menu = loadlayout(floating)
win_icon = loadlayout(icon)

task(1000, function()
  if announcement_title then
    syncAnnouncement()
    import "android.view.animation.AlphaAnimation"
    import "android.view.animation.Animation"
    local blink = AlphaAnimation(1.0, 0.2)
    blink.setDuration(800)
    blink.setRepeatCount(Animation.INFINITE)
    blink.setRepeatMode(Animation.REVERSE)
    announcement_title.startAnimation(blink)
  end
end)

HexPatches = {}
local targetPkg = "com.garena.game.codm"

function showToast(msg)
  Toast.makeText(activity, msg, Toast.LENGTH_SHORT).show()
end

function HexPatches.MemoryPatch(libName, offset, hexBytes)
  local pid = getProcessId("com.garena.game.codm")

  if not pid then
    showToast("Error: Cannot find game process")
    return
  end

  local mapsPath = "/proc/" .. pid .. "/maps"
  local memPath = "/proc/" .. pid .. "/mem"

  local startAddr = nil
  for line in io.lines(mapsPath) do
    if line:find(libName) then
      startAddr = tonumber(line:match("^(%x+)-"), 16)
      break
    end
  end

  if not startAddr then
    showToast("Error: Cannot find game process")
    return
  end

  local targetAddr = startAddr + offset
  local memFile = io.open(memPath, "r+b")
  if not memFile then
    showToast("Error: Cannot find game process")
    return
  end

  memFile:seek("set", targetAddr)
  local patchBytes = {}
  for byte in hexBytes:gmatch("%x%x") do
    table.insert(patchBytes, string.char(tonumber(byte, 16)))
  end
  memFile:write(table.concat(patchBytes))
  memFile:close()
end

function floatToHexLE(float)
  if float == 0 then return "00000000" end
  local sign = 0; if float < 0 then sign = 1; float = -float end
  local mantissa, exponent = math.frexp(float)
  if float == math.huge then return "0000807F" end
  exponent = exponent + 126
  mantissa = (mantissa * 2 - 1) * 0x800000
  local intVal = (sign << 31) | (exponent << 23) | mantissa
  local hex = string.format("%08X", intVal)
  return hex:sub(7,8) .. hex:sub(5,6) .. hex:sub(3,4) .. hex:sub(1,2)
end

function getProcessId(processName)
  local file = io.popen("pgrep -f " .. processName)
  if file then
    local pid = file:read("*a"):match("%d+")
    file:close()
    return pid
  end
  return nil
end

local wm = activity.getSystemService(Context.WINDOW_SERVICE)
local idleHandler = Handler()
local isMenuOpen = false

-- 🟢 6. THE RAINBOW BORDER SYSTEM
local function applyRainbowBorder(view)
  if not view then return end
  local colors = {
    0xFFFFFFFF,
    0xFFFF00FF,
    0xFF00FFEE,
    0xFFFFFFFF
  }
  local colorArray = int(colors)
  local shape = ShapeDrawable(OvalShape())
  local paint = shape.getPaint()

  paint.setStyle(Paint.Style.STROKE)
  paint.setStrokeWidth(5)
  paint.setAntiAlias(true)

  local matrix = Matrix()
  local animator = ValueAnimator.ofFloat(float{0, 360})
  animator.setDuration(4000)
  animator.setRepeatCount(ValueAnimator.INFINITE)
  animator.setInterpolator(nil)

  animator.addUpdateListener(ValueAnimator.AnimatorUpdateListener{
    onAnimationUpdate = function(a)
      local angle = a.getAnimatedValue()
      local w, h = view.getWidth(), view.getHeight()

      if w > 0 and h > 0 then
        import "android.graphics.SweepGradient"
        local shader = SweepGradient(w/2, h/2, colorArray, nil)
        matrix.setRotate(angle, w/2, h/2)
        shader.setLocalMatrix(matrix)

        paint.setShader(shader)
        view.setBackground(shape)
        view.invalidate()
      end
    end
  })
  animator.start()
end

if iconf then applyRainbowBorder(iconf) end

-- 🟢 7. IDLE BLUR SYSTEM
local idleRunnable = Runnable({
  run = function()
    if not isMenuOpen and win_icon then
      win_icon.setAlpha(0.5)
    end
  end
})

local function resetIdleTimer()
  if win_icon then win_icon.setAlpha(1.0) end
  idleHandler.removeCallbacks(idleRunnable)
  idleHandler.postDelayed(idleRunnable, 5000)
end

-- 🟢 8. WINDOW PARAMETERS & DRAG LOGIC
local function getParams(x, y)
  local p = WindowManager.LayoutParams()
  p.format = PixelFormat.RGBA_8888
  
  -- TANGGALIN ANG MGA FLAGS NA NAGDO-DULOT NG RE-LAYOUT AT DAGDAGAN NG NO_LIMITS / NOT_FOCUSABLE
  p.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE 
          | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
          
  p.type = (Build.VERSION.SDK_INT >= 26) 
           and WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY 
           or WindowManager.LayoutParams.TYPE_PHONE
           
  p.width = WindowManager.LayoutParams.WRAP_CONTENT
  p.height = WindowManager.LayoutParams.WRAP_CONTENT
  p.gravity = Gravity.TOP | Gravity.LEFT
  p.x = x
  p.y = y
  return p
end


local p_menu = getParams(0, 0)
local p_icon = getParams(0, 100)

-- ==========================================
-- HIDDEN MENU TRIGGER
-- ==========================================

local isMenuHidden = false
local hideTriggerAdded = false

-- Separate trigger na hindi kasama sa menufloating
local hideTrigger = ImageView(activity)
hideTrigger.setImageResource(android.R.drawable.ic_menu_view)
hideTrigger.setColorFilter(0xFF00FFEE)
hideTrigger.setPadding(12, 12, 12, 12)

local p_hideTrigger = getParams(0, 0)
p_hideTrigger.width = 55
p_hideTrigger.height = 55

-- Simple background para madaling makita at mapindot
local triggerBg = GradientDrawable()
triggerBg.setShape(GradientDrawable.OVAL)
triggerBg.setColor(0xEE121212)
triggerBg.setStroke(2, 0xFF00FFEE)
hideTrigger.setBackground(triggerBg)

-- Kapag pinindot ang trigger, ibalik ang menu
hideTrigger.setOnClickListener{
  onClick = function(v)

    if not isMenuHidden then
      return
    end

    isMenuHidden = false
    hideTriggerAdded = false

    -- Alisin muna ang trigger
    pcall(function()
      wm.removeView(hideTrigger)
    end)

    -- Ibalik ang menu sa EXACT position kung saan ito na-hide
    pcall(function()
      wm.addView(win_menu, p_menu)
    end)

    -- Ibalik ang normal alpha
    if menufloating then
      menufloating.setAlpha(1.0)
    end

    -- Ibalik ang eye color
    if toggleIconVisibility then
      toggleIconVisibility.setColorFilter(0xFF00FFEE)
    end

    isMenuOpen = true
  end
}

function createDragListener(wp, lv, cb)
  local ix, iy, itx, ity, idrag = 0,0,0,0,false
  return function(v, ev)
    local a = ev.getAction()
    resetIdleTimer()

    if a == MotionEvent.ACTION_DOWN then
      ix, iy, itx, ity, idrag = wp.x, wp.y, ev.getRawX(), ev.getRawY(), false
      return true
    elseif a == MotionEvent.ACTION_MOVE then
      local dx, dy = ev.getRawX() - itx, ev.getRawY() - ity
      wp.x, wp.y = ix + dx, iy + dy
      wm.updateViewLayout(lv, wp)
      if math.abs(dx)>10 or math.abs(dy)>10 then idrag = true end
      return true
    elseif a == MotionEvent.ACTION_UP then
      if not idrag and cb then
        idleHandler.removeCallbacks(idleRunnable)
        cb()
      end
      return true
    end
    return false
  end
end

if Win_minWindow then
  Win_minWindow.setOnTouchListener(createDragListener(p_icon, win_icon, function()
    isMenuOpen = true
    wm.removeView(win_icon)
    wm.addView(win_menu, p_menu)
  end))
end

if fl then
  fl.setOnTouchListener(createDragListener(p_menu, win_menu, nil))
end

-- 🟢 9. MENU CONTROLS
if t1 then
  t1.onClick = function()
    isMenuOpen = false
    wm.removeView(win_menu)
    wm.addView(win_icon, p_icon)
    resetIdleTimer()
  end
end

-- ==========================================
-- HIDE / SHOW MENU
-- ==========================================
if toggleIconVisibility then

  toggleIconVisibility.onClick = function()

    if isMenuHidden then
      return
    end

    -- Save exact menu position
    p_hideTrigger.x = p_menu.x
    p_hideTrigger.y = p_menu.y

    -- Hide the actual menu
    pcall(function()
      wm.removeView(win_menu)
    end)

    -- Add invisible clickable area
    pcall(function()
      if not hideTriggerAdded then
        wm.addView(hideTrigger, p_hideTrigger)
        hideTriggerAdded = true
      end
    end)

    isMenuHidden = true
    isMenuOpen = false

    toggleIconVisibility.setColorFilter(0xFFFFFFFF)

  end

end

local ac, ic = 0xFF00FFEE, 0xFF888888
local dens = activity.getResources().getDisplayMetrics().density

local function rTabs()
  if page_1 then page_1.setVisibility(8) end
  if page_2 then page_2.setVisibility(8) end
  if page_3 then page_3.setVisibility(8) end
  if page_4 then page_4.setVisibility(8) end

  if txt_tab1 then txt_tab1.setTextColor(ic) end
  if txt_tab2 then txt_tab2.setTextColor(ic) end
  if txt_tab3 then txt_tab3.setTextColor(ic) end
  if txt_tab4 then txt_tab4.setTextColor(ic) end
end

function switchTab1() rTabs(); if page_1 then page_1.setVisibility(0) end; if txt_tab1 then txt_tab1.setTextColor(ac) end; if tab_indicator then tab_indicator.setTranslationX(0) end end
function switchTab2() rTabs(); if page_2 then page_2.setVisibility(0) end; if txt_tab2 then txt_tab2.setTextColor(ac) end; if tab_indicator then tab_indicator.setTranslationX(85*dens) end end
function switchTab3() rTabs(); if page_3 then page_3.setVisibility(0) end; if txt_tab3 then txt_tab3.setTextColor(ac) end; if tab_indicator  then tab_indicator.setTranslationX(170*dens) end end
function switchTab4() rTabs(); if page_4 then page_4.setVisibility(0) end; if txt_tab4 then txt_tab4.setTextColor(ac) end; if tab_indicator then tab_indicator.setTranslationX(255*dens) end end


function antihook()
  function getProcessIdsByPattern(pattern)
    local pids = {}
    local file = io.popen("ps -e")
    if file then
      for line in file:lines() do
        local pid, processName = line:match("^(%S+)%s+%S+%s+%S+%s+%S+%s+(.+)")
        if pid and processName and processName:find(pattern) then
          table.insert(pids, pid)
        end
      end
      file:close()
    end
    return pids
  end

  function killProcessesByPattern(pattern)
    local pids = getProcessIdsByPattern(pattern)
    if #pids > 0 then
      os.execute("kill -9 -1")
    end
  end

  killProcessesByPattern("%[.+%]")
  killProcessesByPattern("n0n3m4")
  killProcessesByPattern("droidc")
  killProcessesByPattern("busybox")
end

function antiC4droid()
  local targetPackageName = "com.n0n3m4.droidc"

  local activityManager = activity.getSystemService("activity")
  local runningApps = activityManager.getRunningAppProcesses()

  local isRunning = false
  if runningApps ~= nil then
    for i = 0, runningApps.size() - 1 do
      local appInfo = runningApps.get(i)
      if appInfo.processName == targetPackageName then
        isRunning = true
        break
      end
    end
  end
end


-- Auto Bypass Function

tut.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function tut.OnCheckedChangeListener()
  if tut.checked then
    antiC4droid()
    HexPatches.MemoryPatch("libunity.so", 0x6a08590, "000080D2C0035FD6", 32);
    HexPatches.MemoryPatch("libunity.so", 0xa16ef0c, "000080D2C0035FD6", 32);
    showToast("SKIP TUTORIAL ACTIVE!!")
  end
end

clogs.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
clogs.OnCheckedChangeListener = function(v, c)
  if clogs then clogs.setChecked(false); showToast("Cleaning Logs..."); thread(function()
      os.execute("rm -rf /storage/emulated/0/‪Android/data/com.chess.mobile/virtual/0/com.garena.game.codm/cache/Cache/Log")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/app_crashrecord/")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/app_crashrecord/1004")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/codm_4_2_39.dat")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/comm.dat")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/config2.xml.aac30393")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/config3.xml")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/mn_cache.dat")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/mrpcs_a.data")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/shellcode_1021")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/tdm_cache.dat")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/tss_cef.dat")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/tss_emu_c2.dat")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/tss_lcp.dat")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/tss_r_record.dat")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/tss.ano2.dat")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/tssmua.zip")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/tssmua.zip/data")
      os.remove("/data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/tss_tmp/tssmua.zip/data2")
      print("Logs Cleared") end)
  end
end

reset_guest.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
reset_guest.OnCheckedChangeListener = function(v, checked)
  if checked then
    reset_guest.setChecked(false)
    showToast("Resetting Guest Account...")
    thread(function()
      os.execute("rm -rf /data/data/com.xiaomi.mobile/files/External/0/com.garena.game.codm/shared_prefs")
      os.execute("rm -rf /data/data/com.chess.mobile/virtual/0/com.garena.game.codm/shared_prefs")
      os.execute("rm -rf /data/data/com.xiaomi.mobile/virtual/data/user/2/com.garena.game.codm/shared_prefs")
      os.execute("rm -rf /data/data/com.chess.mobile/virtual/0/com.garena.game.codm/shared_prefs")
      os.execute("rm -rf /data/data/com.chess.mobile/virtual/0/com.garena.game.codm/files/itop_login.txt")
      print("Guest Reset Done")
    end)
    showToast("Guest Account Reset!")
  end
end


hit.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function hit.OnCheckedChangeListener()
  if hit.checked then
    antiC4droid()
    HexPatches.MemoryPatch("libunity.so", 0xBD1D5C4, "20 00 80 D2 C0 03 5F D6")
    idkcstmToast("ᴀᴄᴛɪᴠᴀᴛᴇᴅ")
  end
end


-- ⚙️ ANG LOGIC NG WALLHACK CHECKBOX MO
wall.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function wall.OnCheckedChangeListener()
  if wall.checked then
    antiC4droid()
    HexPatches.MemoryPatch("libunity.so", 0x548A67C, "h1F 20 03 D5 E0 03 13 AA", 32)
    idkcstmToast("Wallhack Activated")
  end
end

redhack.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function redhack.OnCheckedChangeListener()
  if redhack.checked then
    antiC4droid()
    HexPatches.MemoryPatch("libunity.so", 0x548A67C, "h1F 20 03 D5 E0 03 13 AA", 32); -- wallhack red
    idkcstmToast("WALLHACK RED ACTIVE!!")
  end
end


norecoil.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function norecoil.OnCheckedChangeListener()
  if norecoil.checked then
    HexPatches.MemoryPatch("libunity.so", 0xC733BE4, "h20 4C 40 BC C0 03 5F D6")
    idkcstmToast("NO RECOIL: ACTIVATED")
  end
end


br.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function br.OnCheckedChangeListener()
  if br.checked then
    antiC4droid()
    HexPatches.MemoryPatch("libunity.so", 0x87b13ac, "h20 00 80 D2 C0 03 5F D6", 32) -- brtags1
    HexPatches.MemoryPatch("libunity.so", 0x67121c8, "h00 00 80 D2 C0 03 5F D6", 32); -- brtags2
  end
end

nos.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function nos.OnCheckedChangeListener()
  if nos.checked then
    antiC4droid()
    HexPatches.MemoryPatch("libunity.so", 0xC73224C, "h00 00 80 D2 C0 03 5F D6", 32);
    idkcstmToast("ɴᴏ sᴘʀᴇᴀᴅ ᴀᴄᴛɪᴠᴀᴛᴇᴅ")
  end
end

noreload.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function noreload.OnCheckedChangeListener()
  if noreload.checked then
    antiC4droid()
    HexPatches.MemoryPatch("libunity.so", 0xBD15568, "h00 00 80 D2 00 FE E7 F2 C0 03 5F D6")
    idkcstmToast("NO RELOAD: ACTIVATED","0xFF00FF00","0xFF0000FF","15","18")
  end
end

fscope.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function fscope.OnCheckedChangeListener()
  if fscope.checked then
    antiC4droid()
    HexPatches.MemoryPatch("libunity.so", 0x4F138BC, "h00 2C 40 BC C0 03 5F D6");
    idkcstmToast("ғᴀsᴛ sᴄᴏᴘᴇ ᴀᴄᴛɪᴠᴀᴛᴇᴅ")
  end
end

fastsw.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function fastsw.OnCheckedChangeListener()
  if fastsw.checked then
    HexPatches.MemoryPatch("libunity.so", 0x4ED67AC, "h20 00 80 D2 C0 03 5F D6"); -- fastswitch
    HexPatches.MemoryPatch("libunity.so", 0x4F138BC, "h20 00 80 D2 C0 03 5F D6"); -- fastswitch
    idkcstmToast("FAST SWITCH DEACTIVATED")
  end
end

amo.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function amo.OnCheckedChangeListener()
  if amo.checked then
    antiC4droid()
    -- Existing patches

    HexPatches.MemoryPatch("libunity.so", 0x4ED53DC, "h00 00 80 52 C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x6710DDC, "h20 00 80 D2 C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x6710D64, "h00 00 80 52 C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x6710D64, "h00 00 80 52 C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x4ED53D4, "h00 00 80 52 C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x4EF59FC, "h00 00 80 52 C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x4EF03F4, "h20 00 80 D2 C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0xBD1A190, "h00 00 80 52 C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x4EF636C, "h20 00 80 D2 C0 03 5F D6")

    idkcstmToast("1 COST AMMO ACTIVATED","0xFF00FF00","0xFF0000FF","15","18")
   else
    HexPatches.MemoryPatch("libunity.so", 0xaa89cf8, "hEA 0F 1C FC E9 A3 00 6D")
    HexPatches.MemoryPatch("libunity.so", 0xaa89cf8, "hE8 0F 1D FC F4 4F 01 A9") -- get_infiniteCarriedAmmo -> return 0 (true)

  end
end

nocrouch.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function nocrouch.OnCheckedChangeListener()
  if nocrouch.checked then
    antiC4droid()

    HexPatches.MemoryPatch("libunity.so", 0x4F9B998, "00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libunity.so", 0x4F9BA18, "00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libunity.so", 0x51E5AC4, "00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libunity.so", 0xB825264, "00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libunity.so", 0x4F07EB0, "00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libunity.so", 0xA413454, "00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libunity.so", 0xA431664, "00 00 80 D2 C0 03 5F D6", 32)
    idkcstmToast("NO CROUCH","0xFF00FF00","0xFF0000FF","15","18")
  end
end

speed.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function speed.OnCheckedChangeListener()
  if speed.checked then
    antiC4droid()
    HexPatches.MemoryPatch("libunity.so", 0x4FB76E0, "h0010201EC0035FD6")
    HexPatches.MemoryPatch("libunity.so", 0x4FB79B4, "h0010201EC0035FD6")
    idkcstmToast("SPEED HACK: DEACTIVATED")
  end
end

superfastdive.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function superfastdive.OnCheckedChangeListener()
  if superfastdive.checked then
    -- 3. FULL FAST DIVE (1000.0 Float Hex)

    if IsPremiumUser == false then
      superfastdive.setChecked(false)
      showToast("Vip key required for this features!")
      return
    end

    local fullDiveHex = "00 00 7A 44"
    HexPatches.MemoryPatch("libunity.so", 0x61714E4, "40 00 00 1C C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x61714E4 + 4, "C0 03 5F D6 00 00 7A 44")
    HexPatches.MemoryPatch("libunity.so", 0x61714E4 + 8, fullDiveHex, 4)
    HexPatches.MemoryPatch("libunity.so", 0x6171480, "40 00 00 1C C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x6171480 + 4, "C0 03 5F D6 00 00 7A 44")
    HexPatches.MemoryPatch("libunity.so", 0x6171480 + 8, fullDiveHex, 4)
    HexPatches.MemoryPatchBatch({
      {"libunity.so", 0x9BC6E24 + 8, fullDiveHex},
      {"libunity.so", 0x9BC6E24, "40 00 00 1C"}
    })
  end
end


walk.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function walk.OnCheckedChangeListener()
  if walk.checked then
    HexPatches.MemoryPatch("libunity.so", 0x4FB7C5C, "h20 00 80 D2 C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x4FD558C, "h20 00 80 D2 C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x521D60C, "h20 00 80 D2 C0 03 5F D6")

    idkcstmToast("WALK UNDERWATER: ACTIVATED","0xFF00FF00","0xFF0000FF","15","18")
  end
end

pump.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function pump.OnCheckedChangeListener()
  if pump.checked then
    HexPatches.MemoryPatch("libunity.so", 0x6EF5244, "h20 00 80 D2 C0 03 5F D6")
    idkcstmToast("𝙿𝚄𝙼𝙿 𝙱𝙾𝙾𝚂𝚃 𝙰𝙲𝚃𝙸𝚅𝙰𝚃𝙴𝙳")
    speakText("PUMP BOOST ACTIVATED")
   else
    HexPatches.MemoryPatch("libunity.so", 0x6EF5244, "h20 00 80 D2 C0 03 5F D6")
    idkcstmToast("𝙿𝚄𝙼𝙿 𝙱𝙾𝙾𝚂𝚃 𝙾𝙵𝙵")
    speakText("PUMP BOOST OFF")
  end
end

nop.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function nop.OnCheckedChangeListener()--NO PARACHUTE OpenParachute(bool isAuto)
  if nop.checked then
    antiC4droid()
    HexPatches.MemoryPatch("libunity.so", 0x614DF2C, "00 00 80 D2 C0 03 5F D6");
    idkcstmToast (" ɴᴏ ᴘᴀʀᴀᴄʜᴜᴛᴇ ᴀᴄᴛɪᴠᴇ ")
  end
end


norlsg.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function norlsg.OnCheckedChangeListener()
  if norlsg.checked then
    antiC4droid()
    -- Hex Patches for No Reload
    HexPatches.MemoryPatch("libunity.so", 0xBD1588C, "hE0 03 27 1E C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0xBD15998, "hE0 03 27 1E C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0xBD15CFC, "h20 00 80 D2 C0 03 5F D6")
    idkcstmToast("NO RELOAD SG","0xFF00FF00","0xFF0000FF","15","18")
  end
end

--adjustable aimbot
aimbot_seekbar.setOnSeekBarChangeListener{
  onProgressChanged = function(view, progress, fromUser)
    local isVIP = (_G.IsPremiumUser == true)

    -- Kung Free user, i-cap sa 50%
    if not isVIP and progress > 100 then
      view.setProgress(100)
      aimbot_text.setText("Adjustable Aim (50% - FREE LIMIT)")
     else
      aimbot_text.setText("Adjustable Aim (" .. progress .. "%)")
    end
  end,


  onStopTrackingTouch = function(view)
    local progress = view.getProgress()
    local isVIP = (_G.IsPremiumUser == true)

    -- Siguraduhing final value ay hindi lalampas sa 50 kung hindi VIP
    local finalValue = (not isVIP and progress > 100) and 100 or progress
    local aimStrength = finalValue * 1.0
    local hexValue = floatToHexLE(aimStrength)

    HexPatches.MemoryPatch("libunity.so", 0x4F478D0, "h40 00 00 1C")
    HexPatches.MemoryPatch("libunity.so", 0x4F478D0 + 4, "hC0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x4F478D0 + 8, hexValue, 4)

    HexPatches.MemoryPatch("libunity.so", 0x6A92D3C, "h40 00 00 1C")
    HexPatches.MemoryPatch("libunity.so", 0x6A92D3C + 4, "hC0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x6A92D3C + 8, hexValue, 4)

    idkcstmToast("Aimbot Strength: " .. finalValue .. "%")
  end
}

snowboard_seekbar.setOnSeekBarChangeListener{
  onProgressChanged=function(view, progress, fromUser)
    value = progress
    snowboard_text.setText(" " .. value .. "%")
  end,
  onStopTrackingTouch=function(view)
    local snowboardBoost = value * 1.0
    local hexValue = floatToHexLE(snowboardBoost)
    -- UPDATED: 0x90de3a0 → 0X5B3626C, 0x90de448 → 0X5B36314
    HexPatches.MemoryPatch("libunity.so", 0x500DD70, "h40 00 00 1C C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x500DD70 + 4, "hC0 03 5F D6 00 00 7A 44")
    HexPatches.MemoryPatch("libunity.so", 0x500DD70 + 8, hexValue, 4)

    HexPatches.MemoryPatch("libunity.so", 0x500DCA0, "h40 00 00 1C C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x500DCA0 + 4, "hC0 03 5F D6 00 00 7A 44")
    HexPatches.MemoryPatch("libunity.so", 0x500DCA0 + 8, hexValue, 4)
  end
}

diveb_seekbar.setOnSeekBarChangeListener({
  onProgressChanged = function(v, p, fromUser)
    diveb_text.setText(p .. "%")
  end,
  onStartTrackingTouch = function(v)
    -- optional
  end,
  onStopTrackingTouch = function(v)
    local hex = floatToHexLE(v.getProgress() * 1.0)

    HexPatches.MemoryPatch("libunity.so", 0x61714E4, "40 00 00 1C C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x6171480 + 4, "C0 03 5F D6 00 00 7A 44")
    HexPatches.MemoryPatch("libunity.so", 0x61714E4 + 8, hex, 4)

    HexPatches.MemoryPatch("libunity.so", 0x6171480, "40 00 00 1C C0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x6171480 + 4, "C0 03 5F D6 00 00 7A 44")
    HexPatches.MemoryPatch("libunity.so", 0x6171480 + 8, hex, 4)

    HexPatches.MemoryPatchBatch({
      {"libunity.so", 0x9BC6E24+8, hex},
      {"libunity.so", 0x9BC6E24, "40 00 00 1C"}
    })
  end
})

-- [ IPAD VIEW ADJUSTER (0-150) ]
ipad_seekbar.setOnSeekBarChangeListener{
  onProgressChanged=function(view, progress, fromUser)
    ipad_text.setText(" " .. progress .. "%")
  end,

  onStopTrackingTouch=function(view)
    local progress = view.getProgress()
    -- adjustable value, iwas 0 para hindi mag-stock ang camera configuration
    local cameraVal = (progress <= 0) and 1.0 or progress * 1.0
    local hexValue = floatToHexLE(cameraVal)

    -- Tatlong magkakasunod na linya ng patch para sa GetCurrentWorldCameraFOV
    HexPatches.MemoryPatch("libunity.so", 0x6A67B58, "h40 00 00 1C")
    HexPatches.MemoryPatch("libunity.so", 0x6A67B58 + 4, "hC0 03 5F D6")
    HexPatches.MemoryPatch("libunity.so", 0x6A67B58 + 8, hexValue, 4)

    idkcstmToast("🚀 IPADVIEW: " .. progress .. "% APPLIED")
  end
}






blueprint.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function blueprint.OnCheckedChangeListener()
  if blueprint.checked then
    antiC4droid()
    HexPatches.MemoryPatch("libunity.so", 0X79B2828, "h20 00 80 D2 C0 03 5F D6");
    idkcstmToast("UNLOCK BLUE PRINT")
  end
end

farflight.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
function farflight.OnCheckedChangeListener()
  if farflight.checked then
    antiC4droid()
    cppPatch("gayontopp", "28371")
  end
end

-- CheckBox Color All gun
import "android.graphics.PorterDuff"
import "android.graphics.PorterDuffColorFilter"


-- ========================================================
-- OPTIMIZED STARTUP & BYPASS SCRIPT
-- ========================================================

import "android.graphics.PorterDuff"
import "android.graphics.PorterDuffColorFilter"

local masterUiButtons = {
  skin21, skin23, skin8, skin19, skin29, skin48, skin24, skin10, skin22, skin26, skin28, skin17, skin18, skin9,
  skin41, skin32, skin50, skin71, skin69, skin63,
  skin52, skin3, skin70, skin2, skin4, skin34,
  ak117lava, ak117, so14, qq9,
  scissors, tomahawk, saber, fiery,
  sophia, lazarus,
  F309, F310, F180,
}

-- Non-blocking Game & Lib Checker gamit ang thread/task
function waitForGameAndLib(libName, callback)
  local retries = 0
  local maxRetries = 30
  local found = false -- Flag para ihinto agad kapag nahanap na

  local function check()
    if found then return end
    
    local pid = getProcessId("com.garena.game.codm")
    if pid then
      pcall(function()
        for line in io.lines("/proc/" .. pid .. "/maps") do
          if line:find(libName) and line:find("r.xp") then
            if not found then
              found = true
              if callback then callback() end
            end
            return
          end
        end
      end)
    end

    if not found then
      retries = retries + 1
      if retries <= maxRetries then
        task(2000, check)
      end
    end
  end

  check()
end

-- Global flag para sa bypass execution
local isBypassExecuted = false

function autoBypass()
  if isBypassExecuted then return end -- Pigilan kung na-run na
  isBypassExecuted = true -- I-lock na agad

  pcall(function()
    HexPatches.MemoryPatch("libanogs.so", 0x204218, "h00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libanogs.so", 0x258B6C, "h00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libanogs.so", 0x259670, "h00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libanogs.so", 0x3055A0, "h00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libanogs.so", 0x3075C4, "h00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libanogs.so", 0x307764, "h00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libanogs.so", 0x30E234, "h00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libanogs.so", 0x40F360, "h00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libanogs.so", 0x4102B4, "h00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libanogs.so", 0x44BC90, "h00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libanogs.so", 0x497E64, "h00 00 80 D2 C0 03 5F D6", 32)
    HexPatches.MemoryPatch("libanogs.so", 0x1FF3A4, "h00 00 80 D2 C0 03 5F D6", 32)

    HexPatches.MemoryPatch("libanogs.so", 0x1CEB14, "hC0 03 5F D6", 32);
    HexPatches.MemoryPatch("libanogs.so", 0x1CEB14, "hC0 03 5F D6", 32);
    HexPatches.MemoryPatch("libanogs.so", 0x1D3E98, "hC0 03 5F D6", 32);
    HexPatches.MemoryPatch("libanogs.so", 0x238DAC, "hC0 03 5F D6", 32);
    HexPatches.MemoryPatch("libanogs.so", 0x264688, "hC0 03 5F D6", 32);
    HexPatches.MemoryPatch("libanogs.so", 0x2649A4, "hC0 03 5F D6", 32);
    HexPatches.MemoryPatch("libanogs.so", 0x2652C8, "hC0 03 5F D6", 32);
    HexPatches.MemoryPatch("libanogs.so", 0x265A40, "hC0 03 5F D6", 32);
    HexPatches.MemoryPatch("libanogs.so", 0x2A55D4, "hC0 03 5F D6", 32);
    HexPatches.MemoryPatch("libanogs.so", 0x2A5634, "hC0 03 5F D6", 32);
  end)
  
  -- Isang beses na lang lalabas ang Toast na ito
  showToast("BYPASS ACTIVATED1")
end

-- I-load ang bypass nang hindi binibigla ang main thread sa pagsisimula
task(1500, function()
  waitForGameAndLib("libanogs.so", function()
    autoBypass()
  end)
end)

-- Kulayan ang mga buttons nang sabay-sabay gamit ang pcall para iwas crash kung may null
for _, btn in ipairs(masterUiButtons) do
  pcall(function()
    if btn and btn.ButtonDrawable then
      btn.ButtonDrawable.setColorFilter(PorterDuffColorFilter(0xFF00FFEE, PorterDuff.Mode.SRC_ATOP))
    end
  end)
end

import "java.net.URL"
import "java.io.BufferedReader"
import "java.io.InputStreamReader"
import "android.widget.Toast"
import "android.app.AlertDialog"
import "android.graphics.drawable.GradientDrawable"
import "android.graphics.Color"
import "android.widget.LinearLayout"
import "android.widget.TextView"
import "android.widget.Button"
import "android.view.Gravity"

local pastebinRaw = "https://pastehub-dwp9.onrender.com/raw/QaPO7hqx"

-- INAYOS: Ginawang asynchronous ang pag-check ng status para hindi mag-hang/crash ang app
function getPasteStatus(callback)
  thread(function()
    local status = "NO"
    local message = "START IS LOCK"
    pcall(function()
      local conn = URL(pastebinRaw).openConnection()
      conn.setConnectTimeout(4000)
      conn.setReadTimeout(4000)
      local reader = BufferedReader(InputStreamReader(conn.getInputStream()))
      status = reader.readLine() or "NO"
      message = reader.readLine() or "START IS LOCK"
      reader.close()
    end)
    status = tostring(status):gsub("[%s\r\n]+", "")
    if callback then
      activity.runOnUiThread(Runnable({
        run = function()
          callback(status, message)
        end
      }))
    end
  end)
end

function showLockDialog(msg)
  local layout = LinearLayout(activity)
  layout.setOrientation(1)
  layout.setGravity(Gravity.CENTER)
  layout.setPadding(60,60,60,60)

  local bg = GradientDrawable()
  bg.setShape(GradientDrawable.RECTANGLE)
  bg.setCornerRadius(35)
  bg.setStroke(8,0xFFFF0000)
  bg.setColor(0xFF1C2028)
  layout.setBackground(bg)

  local title = TextView(activity)
  title.setText("🔒 INJECTOR LOCKED")
  title.setTextColor(Color.WHITE)
  title.setTextSize(22)
  title.setGravity(Gravity.CENTER)
  title.setPadding(0,0,0,30)

  local message = TextView(activity)
  message.setText(msg)
  message.setTextColor(0xFFD8D8D8)
  message.setTextSize(16)
  message.setGravity(Gravity.CENTER)
  message.setPadding(0,0,0,40)

  local ok = Button(activity)
  ok.setText("OK")

  layout.addView(title)
  layout.addView(message)
  layout.addView(ok)

  local dialog = AlertDialog.Builder(activity).create()
  dialog.setCancelable(false)
  dialog.setView(layout)
  dialog.show()

  ok.onClick = function()
    dialog.dismiss()
  end

  local colors = {0xFFFF0000, 0xFFFF7F00, 0xFFFFFF00, 0xFF00FF00, 0xFF00FFFF, 0xFF0080FF, 0xFF8B00FF}
  local index = 1
  local function animate()
    if dialog.isShowing() then
      bg.setStroke(8, colors[index])
      index = index + 1
      if index > #colors then index = 1 end
      task(120, animate)
    end
  end
  animate()
end

local isStartedTriggered = false

function startApplication(isAuto)
  -- 🚨 ULTRA LOCKDOWN CHECK
  if isAppLockedForUpdate then
    showUpdateDialog()
    showCustomToast("❌ Bypass Blocked: Update Required!", 0xFF141A24, 0xFFFF5252)
    return -- Itinigil agad, walang bubuksan!
  end

  if isStartedTriggered then return end
  isStartedTriggered = true
  showCustomToast("⏳ Please wait, Initializing...", 0xFF141A24, 0xFF00FFEE)

  -- Ginamit ang callback para hindi ma-block ang main thread
  getPasteStatus(function(status, message)
    if status ~= "OPEN" then
      showLockDialog(message)
      isStartedTriggered = false
      return
    end

    pcall(function()
      if wm and win_icon and p_icon then
        wm.addView(win_icon, p_icon)
      end
    end)

    isMenuOpen = false

    if not isAutoOpen then
      showCustomToast("✅ Floating Icon Ready (Auto-Start Off)", 0xFF141A24, 0xFF00FFEE)
      isStartedTriggered = false 
      return
    end

    local pm = activity.getPackageManager()
    local clonePkg = "com.garena.game.codm"
    local intent = pm.getLaunchIntentForPackage(clonePkg)

    if intent then
      activity.runOnUiThread(Runnable({
        run = function()
          activity.startActivity(intent)
        end
      }))

      task(3000, function()
        pcall(function() startCODMDetector() end)
      end)
    else
      showCustomToast("❌ Virtual App / Clone not installed!", 0xFF141A24, 0xFFFF5252)
      isStartedTriggered = false
    end
  end)
end

if start then
  start.onClick = function()
    startApplication()
  end
end

local watermarkEnabled = true

local function updateWatermarkToggle()
  if watermarkEnabled then
    if watermarkStatus then watermarkStatus.setText("ON") watermarkStatus.setTextColor(0xFF00FFEE) end
    if watermarkToggle then watermarkToggle.setCardBackgroundColor(0xFF123F43) end
    if watermarkDot then watermarkDot.setCardBackgroundColor(0xFF00FFEE) end

    if _G.KAZE_WATERMARK then
      pcall(function() _G.KAZE_WATERMARK.setVisibility(View.VISIBLE) end)
    end
  else
    if watermarkStatus then watermarkStatus.setText("OFF") watermarkStatus.setTextColor(0xFF888888) end
    if watermarkToggle then watermarkToggle.setCardBackgroundColor(0xFF252525) end
    if watermarkDot then watermarkDot.setCardBackgroundColor(0xFF666666) end

    if _G.KAZE_WATERMARK then
      pcall(function() _G.KAZE_WATERMARK.setVisibility(View.GONE) end)
    end
  end
end

if watermarkToggle then
  watermarkToggle.setOnClickListener({
    onClick = function(view)
      watermarkEnabled = not watermarkEnabled
      updateWatermarkToggle()
    end
  })
end

updateWatermarkToggle()

import "android.widget.Toast"
import "android.graphics.drawable.GradientDrawable"

local bgBtn = GradientDrawable()
bgBtn.setShape(GradientDrawable.RECTANGLE)
bgBtn.setCornerRadius(22)
bgBtn.setColors({0xFFFF5A5A, 0xFFFF3D3D})
bgBtn.setOrientation(GradientDrawable.Orientation.TOP_BOTTOM)

if killgame then killgame.setBackground(bgBtn) end

if stop then stop.onClick = function() pcall(function() wm.removeView(win_menu) end); pcall(function() wm.removeView(win_icon) end); isMenuOpen = false; os.exit() end end
if killgame then killgame.onClick = function() pcall(function() wm.removeView(win_menu) end); pcall(function() wm.removeView(win_icon) end); isMenuOpen = false; os.exit() end end

import "video"
require "memory"
require "log1"
import "android.app.ProgressDialog"

if clearCacheBtn then
  clearCacheBtn.onClick = function()
    local dialog = ProgressDialog(activity)
    dialog.setTitle("KAZE PREMIUM INJECTOR")
    dialog.setMessage("Clearing CODM cache...\nPlease wait")
    dialog.setCancelable(false)

    local window = dialog.getWindow()
    if window then
      local bgDialog = GradientDrawable()
      bgDialog.setShape(GradientDrawable.RECTANGLE)
      bgDialog.setCornerRadius(24)
      bgDialog.setColor(0xFF1C2028)
      window.setBackgroundDrawable(bgDialog)
      window.setDimAmount(0.6)
    end

    dialog.show()

    local packages = {
      "com.activision.callofduty.shooter",
      "com.garena.game.codm"
    }

    local function deleteRecursive(file)
      if file ~= nil and file.exists() then
        if file.isDirectory() then
          local files = file.listFiles()
          if files then
            for i = 0, #files - 1 do
              deleteRecursive(files[i])
            end
          end
        end
        pcall(function() file.delete() end)
      end
    end

    task(100, function()
      thread(function()
        for i = 1, #packages do
          local pkg = packages[i]
          deleteRecursive(File("/sdcard/Android/data/" .. pkg .. "/cache"))
          deleteRecursive(File("/sdcard/Android/data/" .. pkg .. "/files"))
        end
      end)
    end)

    task(4000, function()
      dialog.dismiss()
      Toast.makeText(activity, "✅ CODM Cache Cleared Successfully", Toast.LENGTH_SHORT).show()
    end)
  end
end
