--Apple Script to open Google Chrome or a new window if already open
on is_running(appName)
	tell application "System Events" to (name of processes) contains appName
end is_running

if not is_running("Google Chrome") then
	tell application "Google Chrome" to activate
else
	tell application "Google Chrome"
		make new window
		activate
	end tell
end if
