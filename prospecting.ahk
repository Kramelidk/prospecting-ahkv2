#Requires AutoHotkey v2.0

WinActivate "Roblox"

SetKeyDelay 50, 50
CoordMode "Pixel", "Window"
CoordMode "Mouse", "Window"

global sleepTime := 1
global mineError := false
global foundPerfect := false
isRunning := false

positionRobloxWindow() {
    WinActivate "Roblox"

    ; Give it a moment to activate
    Sleep 200

    ; Move to top-left and resize to a fixed resolution (e.g. 1280x720)
    WinMove(50, 50, A_ScreenWidth - (A_ScreenWidth / 3), A_ScreenHeight - 100, "Roblox")
}
positionRobloxWindow()

MoveMouseToCenter(winTitle) {
    WinGetPos(&x, &y, &w, &h, winTitle)
    centerX := x + w // 2
    centerY := y + h // 2
    MouseMove centerX, centerY
}
MoveMouseToCenter("Roblox")

loop 20
    Send("{WheelUp}")

Sleep 200

Send("{WheelDown}")

saveConfigToFile(filePath := "pixel_config.txt") {
    global PixelConfig
    content := ""
    for key, val in PixelConfig {
        content .= key "=" val[1] "," val[2] "`n"
    }
    if FileExist(filePath)
        FileDelete filePath
    FileAppend content, filePath
}

loadConfigFromFile(filePath := "pixel_config.txt") {
    global PixelConfig, buttons
    if !FileExist(filePath) {
        MsgBox "Config file not found!"
        return
    }

    for line in StrSplit(FileRead(filePath), "`n") {
        if line == ""
            continue
        parts := StrSplit(line, "=")
        key := parts[1]
        coords := StrSplit(parts[2], ",")
        PixelConfig[key] := [coords[1], coords[2]]
        if buttons.Has(key)
            buttons[key].Text := key " (" coords[1] ", " coords[2] ")"
    }
}


; Global pixel positions
global PixelConfig := Map(
    "canMine", [0, 0],
    "canPan", [0, 0],
    "mineCheck", [0, 0],
    "inventoryCheck", [0, 0],
    "barStart", [0, 0],
    "barEnd", [0, 0]
)
global buttons := Map()

openConfigMenu() {
    myGui := Gui("+AlwaysOnTop +Resize", "Bot Configuration")

    buttons["canMine"] := myGui.Add("Button", "w200", "Set 'Collect Deposit'")
    buttons["canMine"].OnEvent("Click", (*) => capturePixel("canMine", buttons["canMine"]))

    buttons["canPan"] := myGui.Add("Button", "w200", "Set 'Pan'")
    buttons["canPan"].OnEvent("Click", (*) => capturePixel("canPan", buttons["canPan"]))

    buttons["mineCheck"] := myGui.Add("Button", "w200", "Set 'Green Click Spot'")
    buttons["mineCheck"].OnEvent("Click", (*) => capturePixel("mineCheck", buttons["mineCheck"]))

    buttons["barStart"] := myGui.Add("Button", "w200", "Set 'Fill Pan' Top Left Corner'")
    buttons["barStart"].OnEvent("Click", (*) => capturePixel("barStart", buttons["barStart"]))

    buttons["barEnd"] := myGui.Add("Button", "w200", "Set 'Fill Pan' Bottom Right Corner'")
    buttons["barEnd"].OnEvent("Click", (*) => capturePixel("barEnd", buttons["barEnd"]))

    myGui.Add("Button", "w200", "Save Config").OnEvent("Click", (*) => saveConfigToFile())
    myGui.Add("Button", "w200", "Load Config").OnEvent("Click", (*) => (
        loadConfigFromFile()
    ))


    ; Print config
    myGui.Add("Button", "w200", "Print Config").OnEvent("Click", printConfig)

    global txtStatus := myGui.Add("Text", "w200", "Status: Waiting...")

    myGui.Show()
    WinMove(100 + A_ScreenWidth - (A_ScreenWidth / 3), 200,,, "ahk_id " myGui.Hwnd)

    ; Define button event handlers as nested functions
    capturePixel(name, button) {
        global PixelConfig
        WinActivate "Roblox"
        ToolTip("select pixel...")
        KeyWait("LButton", "D")
        if (name = "mineCheck")
        {
            MsgBox 'press again'
            Sleep 100
            KeyWait("LButton", "D")
        }
        CoordMode "Mouse", "Window"
        MouseGetPos &x, &y
        ToolTip("")
        PixelConfig[name] := [x, y]
        button.Text := name " (" x ", " y ")"
    }
    

    printConfig(*) {
        out := ""
        for key, val in PixelConfig {
            out .= key ": " val[1] ", " val[2] "`n"
        }
        MsgBox out
    }    
}

openConfigMenu()

checkAreaChange(x1, y1, x2, y2, sampleStep := 10) {
    initial := sampleArea(x1, y1, x2, y2, sampleStep)
    Sleep 500
    later := sampleArea(x1, y1, x2, y2, sampleStep)

    changes := 0
    for key, color in initial {
        if (later.Has(key) && later[key] != color)
            changes++
    }

    return changes > 0
}

sampleArea(x1, y1, x2, y2, step) {
    colors := Map()
    y := y1
    while y <= y2 {
        x := x1
        while x <= x2 {
            colors[x "," y] := PixelGetColor(x, y, "RGB")
            x += step
        }
        y += step
    }
    return colors
}

F6:: {
    global isRunning
    isRunning := !isRunning
    if isRunning {
        txtStatus.Value := "Status: StartingS"
        SetTimer mainLoop, 100
    } else {
        txtStatus.Value := "Status: Paused"
        releaseAllKeys()
        KeyWait "F6"
    }
}

mainLoop() {

    color := getPixelColor(PixelConfig["barEnd"][1], PixelConfig["barEnd"][2])
    if (color = 0x8C8C8C)
    {
        txtStatus.Value := "Status: The bar is NOT full - going to mine"
        if !canMine()
            {
                txtStatus.Value := "Status: (Error) Cannot Mine? going forward"
                holdKey("W")
                Sleep 500
                releaseKey("W")
                return
            }
            ; Mine block
            Sleep 800
            Loop {
                txtStatus.Value := "Status: Mining!"
                color := getPixelColor(PixelConfig["barEnd"][1], PixelConfig["barEnd"][2])
                if color = 0x8C8C8C {
                    mineOneTime()
                    Sleep 800
                } else {
                    txtStatus.Value := "Status: Mining Finished"
                    break
                }
                if (mineError)
                {
                    global mineError := false
                    txtStatus.Value := "Status: (Error) some mining error wtf"
                    break
                }
            }
    }
    else
    {
        txtStatus.Value := "Status: The bar is full - going to pan"
        holdKey("S")
        waitForAlmostWhite(PixelConfig["canPan"][1], PixelConfig["canPan"][2])
        releaseKey("S")
        txtStatus.Value := "Status: Can Pan Here"

        if canPan() {
            txtStatus.Value := "Status: Starting to Pan"
            Sleep 100
            clickOnce()
            Sleep 400
            txtStatus.Value := "Status: Panning!"
            loop
            {
                color := getPixelColor(PixelConfig["barStart"][1], PixelConfig["barStart"][2])
                if (color = 0x8C8C8C)
                {
                    txtStatus.Value := "Status: Finished"
                    break
                }
                else
                {
                    clickOnce()
                }
                Sleep 20
            }
            loop 5
                clickOnce()
                Sleep 10
            txtStatus.Value := "Status: Panning Finished"
            txtStatus.Value := "Status: Going to Mine"
            holdKey("W")
            Loop {
                if isAlmostWhite(getPixelColor(PixelConfig["canMine"][1], PixelConfig["canMine"][2])) {
                    releaseKey("W")
                    txtStatus.Value := "Status: Starting to Mine"
                    break
                }
                Sleep 20
            }
        }
    }

}

; Utility Functions

isAlmostWhite(color) {
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    return (r >= 250 && g >= 250 && b >= 250)
}

getPixelColor(x, y) {
    return PixelGetColor(x, y, "RGB")
}

clickDown() {
    MouseClick "left", , , , , "D"
}

clickUp() {
    MouseClick "left", , , , , "U"
}
clickOnce(delay := 50) {
    clickDown()
    Sleep delay
    clickUp()
}

holdKey(key) {
    Send "{" key " Down}"
}
releaseKey(key) {
    Send "{" key " Up}"
}
releaseAllKeys() {
    releaseKey("W")
    releaseKey("S")
    releaseKey("Ctrl")
    releaseKey("Shift")
}

waitForColor(x, y, expectedColor, equal := true, delay := 50) {
    Loop {
        color := getPixelColor(x, y)
        if (equal && color = expectedColor) || (!equal && color != expectedColor)
            break
        Sleep delay
    }
}

waitForAlmostWhite(x, y, delay := 50) {
    Loop {
        color := getPixelColor(x, y)
        if isAlmostWhite(color)
            break
        Sleep delay
    }
}

mineOneTime() {
    global isRunning
    clickDown()
    perfectStartTime := A_TickCount

    startSample := sampleArea(
        PixelConfig["barStart"][1], PixelConfig["barStart"][2],
        PixelConfig["barEnd"][1], PixelConfig["barEnd"][2], 20
    )

    if foundPerfect
    {
        Sleep perfectTime
        clickUp()
        return
    }

    startTime := A_TickCount
    Loop {
        color1 := getPixelColor(PixelConfig["mineCheck"][1], PixelConfig["mineCheck"][2])
        color2 := getPixelColor(PixelConfig["mineCheck"][1], PixelConfig["mineCheck"][2]+2)
        color3 := getPixelColor(PixelConfig["mineCheck"][1], PixelConfig["mineCheck"][2]-2)
        color4 := getPixelColor(PixelConfig["mineCheck"][1], PixelConfig["mineCheck"][2]+4)
        color := getPixelColor(PixelConfig["barEnd"][1], PixelConfig["barEnd"][2])

        if isAlmostWhite(color1) || isAlmostWhite(color2) || isAlmostWhite(color3) || isAlmostWhite(color4) || color != 0x8C8C8C {
            clickUp()
            Sleep 500
            WinGetPos(&x, &y, &w, &h, "Roblox")
            xLocation := x + w // 2
            yLocation := h // 2 - 40
            offset := 5
            global endTime := A_TickCount
            loop 10
            {
                perfectColor := getPixelColor(xLocation, yLocation - 25 + offset)
                if (perfectColor = 0xFFD83C)
                {
                    global foundPerfect := true
                    global perfectTime := endTime - perfectStartTime
                    txtStatus.Value := "Status: Perfect detected :3"
                    break
                }
                offset := offset + 5
                Sleep 5
            }
            break
        }

        if getPixelColor(PixelConfig["inventoryCheck"][1], PixelConfig["inventoryCheck"][2]) = 0xFE0000 {
            global isRunning := false
            releaseAllKeys()
            MsgBox "full inventory prolly"
            break
        }

        if (A_TickCount - startTime >= 3000)
        {
            startTime := A_TickCount

            endSample := sampleArea(
                PixelConfig["barStart"][1], PixelConfig["barStart"][2],
                PixelConfig["barEnd"][1], PixelConfig["barEnd"][2], 20
            )

            if !areaChanged(startSample, endSample) {
                txtStatus.Value := "Status: (Error) Area did NOT change wtf"
                global mineError := true
                break
            }

            startSample := sampleArea(
                PixelConfig["barStart"][1], PixelConfig["barStart"][2],
                PixelConfig["barEnd"][1], PixelConfig["barEnd"][2], 20
            )
        }

        Sleep sleepTime
    }
}

areaChanged(before, after) {
    for key, val in before {
        if after.Has(key) && after[key] != val
            return true
    }
    return false
}

;canMine() => isAlmostWhite(getPixelColor(840, 908))
canMine() {
    return isAlmostWhite(getPixelColor(PixelConfig["canMine"][1], PixelConfig["canMine"][2]))
}
canPan() {
    return isAlmostWhite(getPixelColor(PixelConfig["canPan"][1], PixelConfig["canPan"][2]))
}
