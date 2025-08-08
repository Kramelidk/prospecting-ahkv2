#Requires AutoHotkey v2.0

WinActivate "Roblox"

SetKeyDelay 50, 50
CoordMode "Pixel", "Window"
CoordMode "Mouse", "Window"

global CUSTOMPERFECTWAITTIME := 205

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

WinGetPos(&x, &y, &w, &h, "Roblox")
centerX := x + w // 2
centerY := y + h // 2 
MouseMove centerX, centerY

loop 10
    Send("{WheelUp}")
    Sleep 20
Sleep 400

Send("{WheelDown}")
Sleep 250
MouseGetPos &x, &y
MouseMove x, y + 172

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
        txtStatus.Value := "i couldnt find a pixel_config.txt file, make it and dont forget to save it :)"
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

    buttons["savePainite"] := myGui.Add("CheckBox", "vSavePainite", "Save Painite?")
    buttons["saveInferlume"] := myGui.Add("CheckBox", "vSaveInferlume", "Save Inferlume?")
    buttons["saveVortessence"] := myGui.Add("CheckBox", "vSaveVortessence", "Save Vortessence?")
    buttons["savePrismara"] := myGui.Add("CheckBox", "vSavePrismara", "Save Prismara?")
    buttons["saveFlarebloom"] := myGui.Add("CheckBox", "vSaveFlarebloom", "Save Flarebloom?")
    buttons["saveVolcanicCore"] := myGui.Add("CheckBox", "vSaveVolcanicCore", "Save Volcanic Core?")
    buttons["saveDinosaurSkull"] := myGui.Add("CheckBox", "vSaveDinosaurSkull", "Save Dinosaur Skull?")

    buttons["saveCustomText"] := myGui.Add("Text", "vSaveCustom", "Save custom minerals:")
    buttons["saveCustom1"] := myGui.Add("Edit", "vSaveCustom1")
    buttons["saveCustom2"] := myGui.Add("Edit", "vSaveCustom2")
    buttons["saveCustom3"] := myGui.Add("Edit", "vSaveCustom3")

    myGui.Add("Button", "w200", "Save Config").OnEvent("Click", (*) => saveConfigToFile())
    myGui.Add("Button", "w200", "Load Config").OnEvent("Click", (*) => (
        loadConfigFromFile()
    ))

    loadConfigFromFile()


    ; Print config
    myGui.Add("Button", "w200", "Print Config").OnEvent("Click", printConfig)

    global txtStatus := myGui.Add("Text", "w200", "im waiting")
    txtStatus.Value := "i loaded the config for u <3"

    myGui.Show()
    WinMove(100 + A_ScreenWidth - (A_ScreenWidth / 3), 200,,, "ahk_id " myGui.Hwnd)

    ; Define button event handlers as nested functions
    capturePixel(name, button) {
        global PixelConfig
        WinActivate "Roblox"
        ToolTip("select pixel...")
        KeyWait("LButton", "d")
        if (name = "mineCheck")
        {
            MsgBox 'press again'
            Sleep 100
            KeyWait("LButton", "d")
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
    global mineCount := 0
    isRunning := !isRunning
    if isRunning {
        txtStatus.Value := "im starting"
        SetTimer mainLoop, 100
    } else {
        txtStatus.Value := "im paused"
        releaseAllKeys()
        MsgBox "i paused, to resume click ok lil bro"
        KeyWait "F6"
    }
}

mainLoop() {

    color := getPixelColor(PixelConfig["barEnd"][1], PixelConfig["barEnd"][2])
    if (color = 0x8C8C8C)
    {
        txtStatus.Value := "the bar is not full, im gonna mine"
        if !canMine()
            {
                txtStatus.Value := "i cant mine, im gonna go forward"
                holdKey("w")
                Sleep 500
                releaseKey("w")
                return
            }
            ; Mine block
            Sleep 800
            Loop {
                txtStatus.Value := "im mining"
                color := getPixelColor(PixelConfig["barEnd"][1], PixelConfig["barEnd"][2])
                if color = 0x8C8C8C {
                    mineOneTime()
                    ;Sleep 800
                } else {
                    txtStatus.Value := "i finished mining"
                    break
                }
                if (mineError)
                {
                    global mineError := false
                    txtStatus.Value := "there was some mining error lil bro"
                    break
                }
            }
    }
    else
    {
        txtStatus.Value := "im gonna pan, the bar is full"
        holdKey("s")
        startTime := A_TickCount
        loop 
        {
            color := getPixelColor(PixelConfig["canPan"][1], PixelConfig["canPan"][2])
            if isAlmostWhite(color)
            {
                break
            }
            if (A_TickCount - startTime >= 3000)
            {
                txtStatus.Value := "i think im bugging, ill try again"
                break
            }
            Sleep 50
        }
        releaseKey("s")
        txtStatus.Value := "i can pan here :)"

        if canPan() {
            mineCount := 0
            txtStatus.Value := "im starting to pan"
            Sleep 100
            clickOnce()
            Sleep 400
            txtStatus.Value := "im panning lil bro"
            panStartTime := A_TickCount
            loop
            {

                if (A_TickCount - panStartTime >= 5000)
                {
                    txtStatus.Value := "im probly retarded"
                    holdKey("s")
                    Sleep 300
                    releaseKey("s")
                    break
                }

                color := getPixelColor(PixelConfig["barStart"][1], PixelConfig["barStart"][2])
                if (color = 0x8C8C8C)
                {
                    txtStatus.Value := "i finished panning"
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
            txtStatus.Value := "now im walking to mine"
            holdKey("w")
            Loop {
                if isAlmostWhite(getPixelColor(PixelConfig["canMine"][1], PixelConfig["canMine"][2])) {
                    releaseKey("w")
                    txtStatus.Value := "im starting to mine"
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

isAlmostRed(color) {
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    return(r > g + 60 && r > b + 60)
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

typeBypasser(text) {
    for char in StrSplit(text) {
        SendText(char)  ; This sends literal text, not hotkey syntax
        Sleep Round(Random(2, 15))
    }
}

moveMouseToSearchBox() {
    Sleep 1000
    MouseMove 808, 605, 10
    Sleep 50
    MouseMove 812, 605, 10
    Sleep 500
    WinActivate "Roblox"
    loop 3 {
        clickOnce()
        Sleep 20
    }
    Sleep 500
}

checkLockedMinerals() {
    slotCoordsX := 327
    slotCoordsY := 680

    howManyMinerals := 0

    loop
    {
        color := getPixelColor(slotCoordsX, slotCoordsY)
        if (color = 0x191B1D)
        {
            txtStatus.Value := "im checking if they are locked"
            if PixelSearch(&Px, &Py, slotCoordsX, slotCoordsY - 60, slotCoordsX + 50, slotCoordsY - 50, 0xFFCC00, 3)
            {
            }
            else
            {
                MouseMove slotCoordsX, slotCoordsY, 10
                Sleep 50
                MouseClick "right", , , , , "D"
                Sleep 50
                MouseClick "right", , , , , "U"
                Sleep 100
            }

            howManyMinerals := howManyMinerals + 1
            slotCoordsX := slotCoordsX + 66
        } else
        {
            txtStatus.Value := "i found " howManyMinerals " minerals"
            break
        }
        Sleep 50
    }
}

mineOneTime() {
    global isRunning
    clickDown()
    isMining := false

    global mineCount := mineCount + 1
    errorColor := getPixelColor(655, 673)
    MouseMove 655, 673

    if CUSTOMPERFECTWAITTIME
    {
        Sleep (290 * (232 / CUSTOMPERFECTWAITTIME))
        clickUp()
        if isAlmostRed(errorColor){
            txtStatus.Value := "ok im gonna sell"

            SendInput "g"
            xCoords := 900
            loop 5
            {
                fullColor := getPixelColor(xCoords, 560)
                if isAlmostRed(fullColor)
                {
                    break
                }
                xCoords := xCoords + 11
            }

            if buttons["savePainite"].Value
            {

                moveMouseToSearchBox()
                search := "paini"

                typeBypasser(search)

                Sleep 800
                Send "{Enter}"
                Sleep 200

                checkLockedMinerals()
            }

            if buttons["saveInferlume"].Value
            {

                moveMouseToSearchBox()
                search := "inferl"

                typeBypasser(search)

                Sleep 800
                Send "{Enter}"
                Sleep 200

                checkLockedMinerals()
            }

            if buttons["saveVortessence"].Value
            {

                moveMouseToSearchBox()
                search := "vortess"

                typeBypasser(search)

                Sleep 800
                Send "{Enter}"
                Sleep 200

                checkLockedMinerals()
            }

            if buttons["savePrismara"].Value
            {

                moveMouseToSearchBox()
                search := "prisma"

                typeBypasser(search)

                Sleep 800
                Send "{Enter}"
                Sleep 200

                checkLockedMinerals()
            }

            if buttons["saveFlarebloom"].Value
            {

                moveMouseToSearchBox()
                search := "flarebl"

                typeBypasser(search)

                Sleep 800
                Send "{Enter}"
                Sleep 200

                checkLockedMinerals()
            }

            if buttons["saveVolcanicCore"].Value
            {

                moveMouseToSearchBox()
                search := "core"

                typeBypasser(search)

                Sleep 800
                Send "{Enter}"
                Sleep 200

                checkLockedMinerals()
            }

            if buttons["saveDinosaurSkull"].Value
            {

                moveMouseToSearchBox()
                search := "skull"

                typeBypasser(search)

                Sleep 800
                Send "{Enter}"
                Sleep 200

                checkLockedMinerals()
            }

            if buttons["saveCustom1"].Value
            {
                moveMouseToSearchBox()
                search := buttons["saveCustom1"].Value

                typeBypasser(search)

                Sleep 800
                Send "{Enter}"
                Sleep 200

                checkLockedMinerals()
            }

            if buttons["saveCustom2"].Value
            {
                moveMouseToSearchBox()
                search := buttons["saveCustom2"].Value

                typeBypasser(search)

                Sleep 800
                Send "{Enter}"
                Sleep 200

                checkLockedMinerals()
            }

            if buttons["saveCustom3"].Value
            {
                moveMouseToSearchBox()
                search := buttons["saveCustom3"].Value

                typeBypasser(search)

                Sleep 800
                Send "{Enter}"
                Sleep 200

                checkLockedMinerals()
            }

            MouseMove 500, 565, 50
            MouseMove 505, 565, 10
            clickOnce()
            Sleep 3000
            SendInput "g"
            Sleep 100
        }
        return
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
