AutoHotkey App Toggler
Overview
This script provides a way to open, close, or toggle focus between different applications using predefined hotkeys. It reads from a configuration file (app_hotkeys.ini) where you can define your preferred hotkeys and the corresponding applications.

Configuration File Format (app_hotkeys.ini)
The configuration file should contain key-value pairs structured as follows:

```
^!v:Code.exe,ahk_exe Code.exe
^!c:chrome.exe,ahk_exe chrome.exe ahk_class Chrome_WidgetWin_1
```

Each line consists of three parts:

The Hotkey: This is the combination of keys that will be used to toggle the application. This is specified before the colon. In the examples above, ^!v and ^!c are the hotkeys (representing Ctrl + Alt + V and Ctrl + Alt + C respectively). Here is a brief list of some special characters used in defining hotkeys, for more check
AutoHotkey Key List:
(https://www.autohotkey.com/docs/v1/KeyList.html):

```
Ctrl Key : ^

Alt Key : !

Shift Key : +

Windows Key : #
```

The Process Name: The name of the application process, which is specified after the colon and before the comma. This is typically the executable file name.

The Query: The query that AutoHotkey uses to identify the application's window(s). This is specified after the comma.

Usage
Press the defined hotkey to toggle the associated application. The behavior is as follows:

If the application isn't running, it will start.
If the application is running and the window is active, it will minimize. If there are multiple windows for the application, it will cycle through minimizing each window one at a time.
If the application is running and all windows are minimized, they will be restored.
If the application is running and the window is not active, it will be brought to focus.
Advanced Window Management
When there are multiple windows for a single application, the script can manage them individually. The hotkey press will focus or minimize the windows in the order they were opened. If the currently active window is minimized, the next window in the cycle will be brought to focus. If all windows are minimized, the next hotkey press will restore all windows.

Portability
This script can be compiled into an executable file using the AutoHotkey compiler (Ahk2Exe). This makes it portable, allowing you to use the functionality on any Windows machine without needing to install AutoHotkey.

Download
The compiled executable can be downloaded directly from the "Releases" section of this GitHub repository. Simply click on the latest release and download the .exe file attached. Keep the configuration file in the same directory as the executable.