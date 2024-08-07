#!/bin/sh

red='\033[0;31m'
none='\033[0m'

echo -e ""
echo -e "Press ${red}Ctrl B${none} followed by a command character below:"
echo -e ""
echo -e "Session Commands:"
echo -e ""
echo -e "        ${red}S${none} List sessions."
echo -e "        ${red}\$${none} Rename current session."
echo -e "        ${red}D${none} Detach current session."
echo -e "        ${red}?${none} Display Help page in tmux."
echo -e ""
echo -e "Window Commands:"
echo -e ""
echo -e "        ${red}C${none} Create a new window."
echo -e "        ${red},${none} Rename the current window."
echo -e "        ${red}W${none} List the windows."
echo -e "        ${red}N${none} Move to the next window."
echo -e "        ${red}P${none} Move to the previous window."
echo -e "        ${red}0${none} to 9: Move to the window number specified."
echo -e ""
echo -e "Pane Commands:"
echo -e ""
echo -e "        ${red}%${none} Create a horizontal split."
echo -e "        ${red}\"${none} Create a vertical split."
echo -e "        ${red}←${none} Move to the pane on the left."
echo -e "        ${red}→${none} Move to the pane on the right."
echo -e "        ${red}↓${none} Move to the pane below."
echo -e "        ${red}↑${none} Move to the pane above."
echo -e "        ${red}Q${none} Briefly show pane numbers."
echo -e "        ${red}O${none} Move through panes in order. Each press takes you to the next."
echo -e "        ${red}}${none} Swap the position of the current pane with the next."
echo -e "        ${red}{${none} Swap the position of the current pane with the previous."
echo -e "        ${red}X${none} Close the current pane."
echo -e ""
echo -e "Resize Commands:"
echo -e ""
echo -e "   ${red}Ctrl ←${none} Resize pane towards the left."
echo -e "   ${red}Ctrl →${none} Resize pane towards the right."
echo -e "   ${red}Ctrl ↓${none} Resize pane towards below."
echo -e "   ${red}Ctrl ↑${none} Resize pane towards above."
echo -e "   ${red} Alt 1${none} Switch to even-horizontal pane layout."
echo -e "   ${red} Alt 2${none} Switch to even-vertical pane layout."
echo -e "   ${red} Alt 3${none} Switch to main-horizontal pane layout."
echo -e "   ${red} Alt 4${none} Switch to main-horizontal pane layout."
echo -e "   ${red} Alt 5${none} Switch to tiled pane layout."
echo -e "   ${red} Alt Space${none} Move through above layouts in order."
