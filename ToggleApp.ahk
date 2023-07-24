#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

app_hotkeys := {}

FileRead, lines, %A_ScriptDir%\app_hotkeys.ini

Loop, Parse, lines, `n, `r
{
    If (SubStr(A_LoopField, 1, 2) = "//")
        continue  ; Skip lines starting with //

    parts := StrSplit(A_LoopField, ":")
    subparts := StrSplit(parts[2], ",")
    app_hotkeys[parts[1]] := { "process": subparts[1], "query": subparts[2] }
}

for hotkey, app in app_hotkeys
    Hotkey, %hotkey%, OpenCloseApp

return

OpenCloseApp:
    current_hotkey := RegExReplace(A_ThisHotkey, "i)^(.*) up$", "$1")
    app_to_toggle := app_hotkeys[current_hotkey]
    
    Process, Exist, % app_to_toggle["process"]
    if (ErrorLevel = 0)
    {
        ; The process isn't running, so start it
        Run, % app_to_toggle["process"]
    }
    else
    {
        ; The process is running
        WinGet, id, list, % app_to_toggle["query"]
        Loop, %id%
        {
            this_id := id%A_Index%
            IfWinActive, ahk_id %this_id%
            {
                ; If the window is active, minimize it
                WinMinimize, ahk_id %this_id%
                break
            }
            else
            {
                ; If the window is not active, first restore it if it's minimized
                WinGet, MinMax, MinMax, ahk_id %this_id%
                if (MinMax = -1)  ; If the window is minimized
                    WinRestore, ahk_id %this_id%
                
                ; Then, activate the window
                WinActivate, ahk_id %this_id%
                break
            }
        }
    }
return
