--Apple Script to open kitty or a new window if already open
on is_running(appName)
	tell application "System Events" to (name of processes) contains appName
end is_running

if not is_running("kitty") then
	tell application "kitty" to activate
else
	tell application "System Events" to tell process "kitty"
		click menu item "New OS Window" of menu 1 of menu bar item "Shell" of menu bar 1
	end tell
end if
