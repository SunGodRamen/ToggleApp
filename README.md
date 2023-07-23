### AutoHotkey App Toggler

## Overview
This script provides a way to open, close, or toggle focus to different applications using predefined hotkeys. The script reads from a configuration file (app_hotkeys.ini) where you can define your preferred hotkeys and the corresponding applications.

## Configuration File Format (app_hotkeys.ini)
The configuration file should contain key-value pairs structured as follows:

```
^!v:Code.exe,ahk_exe Code.exe
^!c:chrome.exe,ahk_exe chrome.exe ahk_class Chrome_WidgetWin_1
```

Each line consists of three parts:

- The Hotkey: This is the combination of keys that will be used to toggle the application. This is specified before the colon (:). In the examples above, ^!v and ^!c are the hotkeys (representing Ctrl + Alt + V and Ctrl + Alt + C respectively). Here is a brief list of some special characters used in defining hotkeys:

"^" : Represents the "Ctrl" key.

"!" : Represents the "Alt" key.

"+" : Represents the "Shift" key.

"#" : Represents the "Win" (Windows logo) key.

- The Process Name: The name of the application process, which is specified after the colon and before the comma. This is typically the executable file name.

- The Query: The query that AutoHotkey uses to identify the application's window(s). This is specified after the comma.

## Usage
Press the defined hotkey to toggle the associated application. The behavior is as follows:

- If the application isn't running, it will start.
- If the application is running and the window is active, it will minimize.
- If the application is running and the window is not active, it will be brought to focus.

## Portability
This script can be compiled into an executable file using the AutoHotkey compiler (Ahk2Exe). This makes it portable, allowing you to use the functionality on any Windows machine without needing to install AutoHotkey.

## Download
The compiled executable can be downloaded directly from the "Releases" section of this GitHub repository. Simply click on the latest release and download the .exe file attached.