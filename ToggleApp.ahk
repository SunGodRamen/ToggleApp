;ToggleApp.ahk
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; Initialize -------------------------------------
;   Read the app_hotkeys.ini file and store the hotkeys and processes in a dictionary
;   Validate that the processes exist

app_hotkeys := {}

missing_files := ""

FileRead, lines, %A_ScriptDir%\app_hotkeys.ini

Loop, Parse, lines, `n, `r
{
    If (SubStr(A_LoopField, 1, 2) = "//")
        continue  ; Skip lines starting with //, comments

    parts := StrSplit(A_LoopField, "|")  ; Split with the pipe character

    if InStr(parts[2], "\")
    {
        var := StrSplit(parts[2], "\")[1]
        EnvGet, var_value, % var
        parts[2] := StrReplace(parts[2], var, var_value)
    }

    ; Check if the file exists
    if (FileExist(parts[2]))
    {
        ; Assign the second and third parts of the line to "process" and "query"
        app_hotkeys[parts[1]] := { "process": parts[2], "query": parts[3] }
    }
    else
    {
        missing_files .= parts[2] . "`n"
    }
}

if StrLen(missing_files) != 0
{
    MsgBox, % "The following processes do not exist on your machine:`n" . missing_files
    ExitApp
}

for hotkey, app in app_hotkeys
    Hotkey, %hotkey%, OpenCloseApp

return


; Assign Hotkeys ---------------------------------
; This function is called when a hotkey is pressed
; It will either start the process or toggle the windows
; minimize/restore/focus state
window_states := {}

OpenCloseApp:
    current_hotkey := RegExReplace(A_ThisHotkey, "i)^(.*) up$", "$1")
    app_to_toggle := app_hotkeys[current_hotkey]

    ; Get the process name from the full path
    processPath := app_to_toggle["process"]
    SplitPath, processPath, name

    Process, Exist, % name
    if (ErrorLevel = 0)
    {
        ; The process isn't running, so start it
        Run, % app_to_toggle["process"]
    }
    else
    {
        ; The process is running, query for the window IDs
        WinGet, id, list, % app_to_toggle["query"]

        window_states := {}  ; Reset the window states for this process
        windows := []  ; Array to hold the window IDs in the order they are found

        Loop, %id%
        {
            this_id := id%A_Index%
            windows.Push(this_id)  ; Push the window IDs into the array in order

            ; Determine if this window is active or minimized
            WinGet, MinMax, MinMax, ahk_id %this_id%
            IfWinActive, ahk_id %this_id%
            {
                ; If the window is active, mark it as active in the window states
                window_states[this_id] := "active"
            }
            else if (MinMax = -1)  ; If the window is minimized
            {
                ; If the window is minimized, mark it as minimized in the window states
                window_states[this_id] := "minimized"
            }
            else
            {
                ; If the window is neither active nor minimized, mark it as inactive in the window states
                window_states[this_id] := "inactive"
            }
        }

        all_minimized := true
        all_inactive := true
        for window_id, state in window_states
        {
            if (state != "minimized")
            {
                all_minimized := false
            }
            if (state != "inactive")
            {
                all_inactive := false
            }
            if (!all_minimized && !all_inactive)
            {
                break
            }
        }

        if (all_minimized)
        {
            ; If all windows are minimized, restore all of them
            for window_id, state in window_states
            {
                WinRestore, ahk_id %window_id%
            }
        }
        else if (all_inactive)
        {
            ; If all windows are inactive, activate the first one
            first_window := windows[1]
            WinActivate, ahk_id %first_window%
            window_states[first_window] := "active"
        }
        else
        {
            ; If not all windows are minimized or inactive, find the active window and minimize it, then activate the next window in the list
            next_window := ""  ; This will hold the ID of the next window to activate
            for index, window_id in windows
            {
                if (window_states[window_id] = "active")
                {
                    ; If the window is active, minimize it
                    WinMinimize, ahk_id %window_id%
                    window_states[window_id] := "minimized"
                    
                    ; Set the next window to activate
                    if (windows.MaxIndex() = index)
                    {
                        ; If this is the last window in the list, the next window is the first window
                        next_window := windows[1]
                    }
                    else
                    {
                        ; Otherwise, the next window is the window after this one in the list
                        next_window := windows[index + 1]
                    }
                    break
                }
            }
            
            if (next_window != "")
            {
                ; If there is a next window to activate, activate it
                WinGet, MinMax, MinMax, ahk_id %next_window%
                if (MinMax != -1)  ; If the window is not minimized
                {
                    WinActivate, ahk_id %next_window%
                    window_states[next_window] := "active"
                }
            }
        }
    }
return
