;ToggleApp.ahk
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

CONFIG_DIR := A_ScriptDir . "\config\"
CONFIG_FILE_NAME := "process_hotkeys.ini"
CONFIG_FILE_PATH := CONFIG_DIR . CONFIG_FILE_NAME
BACKUP_CONFIG_FILE_NAME := "process_hotkeys_backup.ini"
BACKUP_CONFIG_FILE_PATH := CONFIG_DIR . "process_hotkeys_backup.ini"

GoSub, Init

; Initialize the script
Init:
    ; Check if the config file exists
    if (!FileExist(CONFIG_FILE_PATH))
    {
        MsgBox, % "The" . CONFIG_FILE_NAME . " file does not exist in the expected config dir:" . CONFIG_DIR . ". Exiting."
        ExitApp
    }
    ; Check if the backup config file exists
    backup_config_exists := FileExist(BACKUP_CONFIG_FILE_PATH)
    
    ; Read the config file
    config_file := CONFIG_FILE_PATH
    process_hotkeys := {}
    total_errors := ""
    Gosub, ReadConfigFile
    
    ; If there were errors, display them and exit or run from the backup file
    if StrLen(total_errors) != 0
    {
        MsgBox, % "The following errors were found:`n" . line_errors . ((backup_config_exists) 
            ? "`nReverting to backup configuration." 
            : " Backup configuration at " . BACKUP_CONFIG_FILE_PATH . " not found, exiting.")
    
        if (!backup_config_exists)
            ExitApp
    
        ; Read the backup file instead
        config_file := BACKUP_CONFIG_FILE_PATH
        process_hotkeys := {}
        total_errors = ""
        Gosub, ReadConfigFile
        If (StrLen(total_errors) > 0)
        {
            MsgBox, % "The following errors were found in the backup configuration:`n" . line_errors . "`nExiting."
            ExitApp
        }
    }
    else
    {
        ; Copy the file to the backup file, overwriting if it exists
        FileCopy, %CONFIG_FILE_PATH%, %BACKUP_CONFIG_FILE_PATH%, 1
    }
    
    ; Assign hotkeys
    for hotkey, app in process_hotkeys
        Hotkey, %hotkey%, OpenCloseApp

return

; This function reads the config file and stores the hotkeys and processes in a dictionary
ReadConfigFile:
    total_errors := ""
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

        ; Validate the line
        total_errors .= ValidateLineFunction(config_line_sections, A_Index)

        ; If no errors, store the hotkey and process in the dictionary
        If (StrLen(total_errors) < 1)
        {
            hotkey := config_line_sections[1]
            ; Check if the hotkey already exists in the dictionary
            if (process_hotkeys[hotkey] != "")
            {
                total_errors .= "Duplicate hotkey at line " . A_Index . ": " . A_LoopField . "`n"
            }
            else
            {
                process_hotkeys[hotkey] := { "process": config_line_sections[2], "query": config_line_sections[3] }
            }
        }
    }
return

; This function validates a line from the config file
ValidateLineFunction(config_line_sections, line_index) {
    ; Initialize error string for this line
    line_errors := ""

    ; Check if there are 3 config_line_sections
    If (config_line_sections.MaxIndex() != 3)
    {
        line_errors .= "Line " . A_Index . " incorrect number of sections: " . A_LoopField . "`n"
    }
    Else
    {
        ; Check if the hotkey is specified
        If (StrLen(config_line_sections[1]) < 1)
            line_errors .= "Missing hotkey at line " . A_Index . ": " . A_LoopField . "`n"

        ; Check if the process is specified
        If (StrLen(config_line_sections[2]) < 1)
        {
            line_errors .= "Missing process at line " . A_Index . ": " . A_LoopField . "`n"
        }
        Else
        {
            ; If any environment variables are specified
            Gosub, TranslateEnvVars

            ; Check if the process is a valid path
            processPath := config_line_sections[2]
            SplitPath, processPath, name
            If (StrLen(name) < 1)
            {
                line_errors .= "Invalid process path at line " . A_Index . ": " . A_LoopField . "`n"
            }
            Else
            {
                ; Check if the process exists
                If (!FileExist(config_line_sections[2]))
                    line_errors .= "Process does not exist at line " . A_Index . ": " . A_LoopField . "`n"
            }
        }

        ; Check if the query is specified
        If (StrLen(config_line_sections[3]) < 1)
            line_errors .= "Missing query at line " . A_Index . ": " . A_LoopField . "`n"
    }
 
    ; Return any errors found
    return line_errors
}

; This function interpolates environment variables in the path
TranslateEnvVars:
    ; Split the path into parts
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
            Else
            {
                ; If the environment variable doesn't exist, add an error
                line_errors .= "Environment variable " . env_var_name . " does not exist at line " . A_Index . ": " . A_LoopField . "`n"
            }
        }
    }
return


; This function checks if the config file has changed and reloads the script if it has
CheckConfigFile:
    FileRead, new_lines, %CONFIG_FILE_PATH%
    if (new_lines != lines)  ; If the file has changed
        Reload  ; Reload the script
return


; This function runs every time a hotkey is pressed and
; toggles the window states of the specified process
OpenCloseApp:
    ; Check if the config file has changed
    Gosub, CheckConfigFile

    current_hotkey := RegExReplace(A_ThisHotkey, "i)^(.*) up$", "$1")
    process_to_toggle := process_hotkeys[current_hotkey]

    ; Get the process name from the full path
    processPath := process_to_toggle["process"]
    SplitPath, processPath, name

    Process, Exist, % name
    if (ErrorLevel = 0)
    {
        ; The process isn't running, so start it
        Run, % process_to_toggle["process"]
    }
    else
    {
        ; The process is running, query for the window IDs
        WinGet, id, list, % process_to_toggle["query"]

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
            
            ; If there is a next window to activate,
            if (next_window != "")
            {
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
