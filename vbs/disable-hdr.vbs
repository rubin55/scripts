Set oShell = CreateObject("WScript.Shell")

oShell.Run("""ms-settings:display""")

WScript.Sleep 2000

oShell.AppActivate "settings"

WScript.Sleep 100

oShell.SendKeys "{TAB}"

WScript.Sleep 60

oShell.SendKeys "{TAB}"

WScript.Sleep 60

oShell.SendKeys " "

WScript.Sleep 3000

oShell.SendKeys "{TAB}"

WScript.Sleep 50

oShell.SendKeys " "

WScript.Sleep 50

oShell.SendKeys "%{F4}"