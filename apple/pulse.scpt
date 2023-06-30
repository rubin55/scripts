sh_button for c to which
        if which is "connect" then
                set notdone to "Disconnected"
                set isdone to "Connected"
        else
                set notdone to "Connected"
                set isdone to "Disconnected"
        end if

        tell application "Junos Pulse"
                set istr to indexStr of c
                if connectionStatus of c is notdone then
                        -- Time to connect
                        do PulseMainUI command "SELECTCONNECTION" ConnectionIndexStr istr
                        do PulseMainUI command "CLICKCONNECTBUTTON" ConnectionIndexStr istr
                        do PulseMainUI command "QUITPULSEUI" -- ConnectionIndexStr istr
                else if connectionStatus of c is isdone then
                        -- display dialog "Connection is already " & connectionStatus of c
                        do PulseMainUI command "QUITPULSEUI" -- ConnectionIndexStr istr
                else
                        display dialog "Connection status is " & connectionStatus of c
                end if
        end tell
end push_button

(*
QUITPULSEUI
FORGETALLSAVEDSETTINGS
ADDCONNECTIONCLICKED
DELETESELECTEDCONNECTION
EDITSELECTEDCONNECTION
CLICKCONNECTBUTTON
SELECTCONNECTION
ConnectionIndexStr
*)
