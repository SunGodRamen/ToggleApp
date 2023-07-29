;ToggleApp.ahk
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; Initialize -------------------------------------
;   Reads the app_hotkeys.ini file and store the hotkeys and processes in a dictionary

if (!FileExist(A_ScriptDir . "\app_hotkeys.ini"))
{
    MsgBox, % "The app_hotkeys.ini file does not exist in the same directory as this script. Exiting."
    ExitApp
}

backup_config_exists := FileExist(A_ScriptDir . "\app_hotkeys_backup.ini")

; Read the config file
config_file := A_ScriptDir . "\app_hotkeys.ini"
app_hotkeys := {}
line_errors := ""
Gosub, ReadConfigFile

if StrLen(line_errors) != 0
{
    MsgBox, % "The following errors were found:`n" . line_errors . ((backup_config_exists) 
        ? "`nReverting to backup configuration." 
        : " Backup configuration not found, exiting.")

    if (!backup_config_exists)
        ExitApp

    ; Read the backup file instead
    config_file := A_ScriptDir . "\app_hotkeys_backup.ini"
    app_hotkeys := {}
    line_errors = ""
    Gosub, ReadConfigFile    
}
else
{
    ; Copy the file to the backup file, overwriting if it exists
    FileCopy, %A_ScriptDir%\app_hotkeys.ini, %A_ScriptDir%\app_hotkeys_backup.ini, 1
}

; Assign hotkeys
for hotkey, app in app_hotkeys
    Hotkey, %hotkey%, OpenCloseApp
return

; ReadConfigFile ---------------------------------
;    This function reads and validates the app_hotkeys.ini file
;    and stores the hotkeys and processes in a dictionary
ReadConfigFile:
    FileRead, lines, %config_file%
    Loop, Parse, lines, `n, `r
    {
        ; Skip lines starting with // as they are comments
        If (SubStr(A_LoopField, 1, 2) = "//")
            continue
        
        ; Skip blank lines
        If (A_LoopField = "")
            continue

        ; Split into sections with the pipe character
        config_line_sections := StrSplit(A_LoopField, "|")

        ; Replace any environment variables in the path
        path_parts := StrSplit(config_line_sections[2], "\")
        for index, path_part in path_parts
        {
            ; Environment variables are surrounded by % characters
            if (SubStr(path_part, 1, 1) = "%" && SubStr(path_part, StrLen(path_part), 1) = "%")
            {
                env_var_name := SubStr(path_part, 2, StrLen(path_part) - 2)  ; Remove the %
                ; Check if the environment variable exists
                EnvGet, env_var_value, % env_var_name
                If (StrLen(env_var_value) > 0)
                {
                    ; Replace the environment variable with the value
                    config_line_sections[2] := StrReplace(config_line_sections[2], path_part, env_var_value)
                }
            }
        }

        ; Validate the line
        Switch 
        {
            ; Check if there are 3 config_line_sections
            Case (config_line_sections.MaxIndex() != 3):
                line_errors .= "Line " . A_Index . " format is incorrect: " . A_LoopField . "`n"

            ; Check if the hotkey is specified
            Case (StrLen(config_line_sections[1]) < 1):
                line_errors .= "Missing hotkey at line " . A_Index . ": " . A_LoopField . "`n"

            ; Check if the process is specified
            Case (StrLen(config_line_sections[2]) < 1):
                line_errors .= "Missing process at line " . A_Index . ": " . A_LoopField . "`n"

            ; Check if the query is specified
            Case (StrLen(config_line_sections[3]) < 1):
                line_errors .= "Missing query at line " . A_Index . ": " . A_LoopField . "`n"

            ; Check if the process exists
            Case (!FileExist(config_line_sections[2])):
                line_errors .= "Process does not exist at line " . A_Index . ": " . A_LoopField . "`n"

            ; if no errors, store the hotkey and process in the dictionary
            Default:
                app_hotkeys[config_line_sections[1]] := { "process": config_line_sections[2], "query": config_line_sections[3] }
        }
    }
return

; CheckConfigFile ---------------------------------
;   This function is called every time a hotkey is used
;   to check if the config file has changed

CheckConfigFile:
    FileRead, new_lines, %A_ScriptDir%\app_hotkeys.ini
    if (new_lines != lines)  ; If the file has changed
    {
        FileRead, lines, %A_ScriptDir%\app_hotkeys.ini  ; Re-read the file
        Reload  ; Reload the script
    }
return

; OpenCloseApp ---------------------------------
;   This function is called when a hotkey is pressed
;   It will either start the process or toggle the window_ids
;   minimize/restore/focus state

window_states := {}

OpenCloseApp:
    ; Check if the config file has changed
    Gosub, CheckConfigFile

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
        window_ids := []  ; Array to hold the window IDs in the order they are found

        Loop, %id%
        {
            this_id := id%A_Index%
            ; Push the window IDs into the array in order
            window_ids.Push(this_id)  

            ; Determine if this window is active or minimized
            WinGet, MinMax, MinMax, ahk_id %this_id%
            IfWinActive, ahk_id %this_id%
            {
                ; If the window is active, mark it as active in the window states
                window_states[this_id] := "active"
            }
            else if (MinMax = -1)
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
            ; If all window_ids are minimized, restore all of them
            for window_id, state in window_states
            {
                WinRestore, ahk_id %window_id%
            }
        }
        else if (all_inactive)
        {
            ; If all window_ids are inactive, activate the first one
            first_window := window_ids[1]
            WinActivate, ahk_id %first_window%
            window_states[first_window] := "active"
        }
        else
        {
            ; If not all window_ids are minimized or inactive, find the active window and minimize it, then activate the next window in the list
            next_window := ""
            for index, window_id in window_ids
            {
                if (window_states[window_id] = "active")
                {
                    ; If the window is active, minimize it
                    WinMinimize, ahk_id %window_id%
                    window_states[window_id] := "minimized"
                    
                    ; Set the next window to activate
                    if (window_ids.MaxIndex() = index)
                    {
                        ; If this is the last window in the list, the next window is the first window
                        next_window := window_ids[1]
                    }
                    else
                    {
                        ; Otherwise, the next window is the window after this one in the list
                        next_window := window_ids[index + 1]
                    }
                    break
                }
            }
            
            if (next_window != "")
            {
                ; If there is a next window to activate,
                ; If the window is not minimized, activate it
                WinGet, MinMax, MinMax, ahk_id %next_window%
                if (MinMax != -1)
                {
                    WinActivate, ahk_id %next_window%
                    window_states[next_window] := "active"
                }
            }
        }
    }
return
