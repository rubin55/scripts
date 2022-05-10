#!/usr/bin/env bash

# Common settings.
proxyPort="8080"
proxyHost="proxy.example.com"
proxyUrl="http://$proxyHost:$proxyPort"
proxyPac="http://$proxyHost:8000/some.pac"
proxyNet="Wi-Fi"
proxyEnv="http_proxy https_proxy ftp_proxy no_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY NO_PROXY"
proxyNo="localhost,127.0.0.1"

# Set current proxy state
if [ -e "$HOME/.proxy.state" ]; then
    proxyState=$(cat "$HOME/.proxy.state")
else
    proxyState="unknown"
fi

# Print to stderr.
function printError() {
	>&2 echo $@;
}

# Don't run if another instance of the script is running.
script="$(echo $0)"
for pid in $(pgrep -f "bash $script"); do
    if [ $pid != $$ ]; then
        printError "Process for $script is already running with PID $pid"
        exit 1
    fi
done

# Show a usage message.
function printUsage {
    echo "Usage: $0 on|off|status"
}

function checkExit {
    if [ $1 = 0 ]; then
        echo "done"
    else
        echo "failed"
    fi
}

function startDocker {
    open -a Docker
    while [ -z "$(docker info 2> /dev/null)" ]; do
        >&2 printf "."
        sleep 1
    done
}

function stopDocker {
    osascript -e 'quit app "Docker"'
    while [ ! -z "$(docker info 2> /dev/null)" ]; do
        >&2 printf "."
        sleep 1
    done
}

function isDockerRunning {
    local check=$(ps ax | grep -i com.docker.hyperkit | grep -v grep)
    if [ -z "$check" ]; then
        echo "false"
    else
        echo "true"
    fi
}

function proxyForSystem {
    case "$1" in
        "detect")
        echo true
        ;;
        "enable")
        if [ "$proxyState" != "enabled" ]; then
            echo -n "# Enabling proxy settings for System: "
            networksetup -setautoproxyurl "$proxyNet" "$proxyPac"
            networksetup -setautoproxystate "$proxyNet" on
            checkExit $?
        fi
        ;;
        "disable")
        if [ "$proxyState" != "disabled" ]; then
            echo -n "# Disabling proxy settings for System: "
            networksetup -setautoproxyurl "$proxyNet" "http://localhost:8080/none.pac"
            networksetup -setautoproxystate "$proxyNet" off
            checkExit $?
        fi
        ;;
        "status")
        echo "# Showing proxy settings for System: "
        networksetup -getautoproxyurl "$proxyNet"
        echo ""
        ;;
        *)
        printError "$0: invalid parameter \"$1\" passed; expected either \"enable\", \"disable\" or \"status\"."
        ;;
    esac
}

function proxyForDocker {

    local settingsFile="$HOME/Library/Group Containers/group.com.docker/settings.json"
    #  "proxyHttpMode" : "manual",
    #  "overrideProxyHttp" : "http://proxy.example.com:8080",
    #  "overrideProxyHttps" : "http://proxy.example.com:8080",

    local proxyFile="$HOME/Library/Group Containers/group.com.docker/http_proxy.json"
    local proxyFileContentsDisabled="{ \"transparent_http_ports\": [ 80 ], \"transparent_https_ports\": [ 443 ] }"
    local proxyFileContentsEnabled="{ \"http\": \"$proxyUrl\", \"https\": \"$proxyUrl\", \"exclude\": \"$proxyNo\", \"transparent_http_ports\": [ 80 ], \"transparent_https_ports\": [ 443 ] }"
    local wasDockerRunningInTheFirstPlace=$(isDockerRunning)

    #
    #

    case "$1" in
        "detect")
        local check="$(which docker)"
        [[ ! -z "$check" ]] && echo true || echo false
        ;;
        "enable")
        if [ "$proxyState" != "enabled" ]; then
            echo -n "# Enabling proxy settings for Docker: "
            if [ "$wasDockerRunningInTheFirstPlace" == "true" ]; then
                stopDocker
            fi
            sed -i.orig "s|\"proxyHttpMode\".*$|\"proxyHttpMode\" : \"manual\",|g" "$settingsFile"
            sed -i.orig "s|\"overrideProxyHttp\".*$|\"overrideProxyHttp\" : \"$proxyUrl\",|g" "$settingsFile"
            sed -i.orig "s|\"overrideProxyHttps\".*$|\"overrideProxyHttps\" : \"$proxyUrl\",|g" "$settingsFile"
            echo "$proxyFileContentsEnabled" > "$proxyFile"
            if [[ "$wasDockerRunningInTheFirstPlace" == "true" && "$(isDockerRunning)" == "false" ]]; then
                startDocker
            fi
            checkExit $?
        fi
        ;;
        "disable")
        if [ "$proxyState" != "disabled" ]; then
            echo -n "# Disabling proxy settings for Docker: "
            if [ "$wasDockerRunningInTheFirstPlace" == "true" ]; then
                stopDocker
            fi
            sed -i.orig "s|\"proxyHttpMode\".*$|\"proxyHttpMode\" : \"system\",|g" "$settingsFile"
            sed -i.orig "s|\"overrideProxyHttp\".*$|\"overrideProxyHttp\" : \"http://localhost:8080\",|g" "$settingsFile"
            sed -i.orig "s|\"overrideProxyHttps\".*$|\"overrideProxyHttps\" : \"http://localhost:8080\",|g" "$settingsFile"
            echo "$proxyFileContentsDisabled" > "$proxyFile"
            if [[ "$wasDockerRunningInTheFirstPlace" == "true" && "$(isDockerRunning)" == "false" ]]; then
                startDocker
            fi
            checkExit $?
        fi
        ;;
        "status")
        echo "# Showing proxy settings for Docker: "
        cat "$proxyFile"
        echo ""
        ;;
        *)
        printError "$0: invalid parameter \"$1\" passed; expected either \"enable\", \"disable\" or \"status\"."
        ;;
    esac
}

function proxyForConsole {
    case "$1" in
        "detect")
        echo true
        ;;
        "enable")
            echo "# Enabling proxy settings for Console: "
            for element in $proxyEnv; do
                if [ "$element" == "no_proxy" -o "$element" == "NO_PROXY" ]; then
                    echo "export $element=\"$proxyNo\""
                else
                    echo "export $element=\"$proxyUrl\""
                fi
            done
        ;;
        "disable")
            echo "# Disabling proxy settings for Console: "
            for element in $proxyEnv; do
                echo "unset $element"
            done
        ;;
        "status")
        echo "# Showing proxy settings for Console:"
        for element in $proxyEnv; do
            value="$(env | grep "$element")"
            if [ ! -z  "$value" ]; then echo $value; fi
        done
        echo ""
        ;;
        *)
        printError "$0: invalid parameter \"$1\" passed; expected either \"enable\", \"disable\" or \"status\"."
        ;;
    esac
}

function proxyForOpenSSH {
    local configurationFile="$HOME/.ssh/config"

    local codeBlockOne="\nHost shell.xs4all.nl\n    Hostname shell.xs4all.nl\n    Port 443\n    ProxyCommand corkscrew $proxyHost $proxyPort \045h \045p\n"

    local codeBlockTwo="\nHost github.com\n    Hostname ssh.github.com\n    Port 443\n    ProxyCommand corkscrew $proxyHost $proxyPort \045h \045p\n    User git\n"

    touch "$configurationFile"

    case "$1" in
        "detect")
        local check="$(which corkscrew)"
        [[ -x "$check" ]] && echo true || echo false
        ;;
        "enable")
        if [ "$proxyState" != "enabled" ]; then
            echo -n "# Enabling proxy settings for OpenSSH: "

            if [ ! "$(grep "Host shell.xs4all.nl" "$configurationFile")" ]; then
                printf "$codeBlockOne" >> $configurationFile
            fi

            if [ ! "$(grep "Host github.com" "$configurationFile")" ]; then
                printf "$codeBlockTwo" >> $configurationFile
            fi

            checkExit $?
        fi
        ;;
        "disable")
        if [ "$proxyState" != "disabled" ]; then
            echo -n "# Disabling proxy settings for OpenSSH: "

            sed  -i.orig '/Host shell.xs4all.nl/,/8080 %h %p/d' "$configurationFile"
            sed  -i.orig '/Host github.com/,/User git/d' "$configurationFile"
            sed -i.orig '/^\s*$/d' "$configurationFile"
            checkExit $?
        fi
        ;;
        "status")
        echo "# Showing proxy settings for OpenSSH: "
        cat "$configurationFile"
        echo ""
        ;;
        *)
        printError "$0: invalid parameter \"$1\" passed; expected either \"enable\", \"disable\" or \"status\"."
        ;;
    esac
}

function proxyForMaven {
    local settingsFile="$HOME/.m2/settings.xml"
    local settingsWithProxyEnabled="$HOME/.m2/settings.xml.proxyEnabled"
    local settingsWithProxyDisabled="$HOME/.m2/settings.xml.proxyDisabled"

    if [ -e "$settingsWithProxyEnabled" -a -e  "$settingsWithProxyDisabled" ]; then
        case "$1" in
            "detect")
            local check="$(which mvn)"
            [[ ! -z "$check" ]] && echo true || echo false
            ;;
            "enable")
            if [ "$proxyState" != "enabled" ]; then
                echo -n "# Enabling proxy settings for Maven: "
                cp "$settingsWithProxyEnabled" "$settingsFile"
                checkExit $?
            fi
            ;;
            "disable")
            if [ "$proxyState" != "disabled" ]; then
                echo -n "# Disabling proxy settings for Maven: "
                cp "$settingsWithProxyDisabled" "$settingsFile"
                checkExit $?
            fi
            ;;
            "status")
            echo "# Showing proxy settings for Maven: "
            cat "$settingsFile"
            echo ""
            ;;
            *)
            printError "$0: invalid parameter \"$1\" passed; expected either \"enable\", \"disable\" or \"status\"."
            ;;
        esac
    else
        printError "$0 configuration files not found: \"$settingsWithProxyEnabled\", \"$settingsWithProxyDisabled\""
    fi
}

function proxyForAnypoint6 {
    local configurationFile="/Applications/Anypoint Studio 6.app//Contents/Eclipse/configuration/.settings/org.eclipse.core.net.prefs"
    if [ -e "$configurationFile" ]; then
        case "$1" in
            "detect")
            [[ -e "$configurationFile" ]] && echo true || echo false
            ;;
            "enable")
            if [ "$proxyState" != "enabled" ]; then
                echo -n "# Enabling proxy settings for Anypoint Studio 6: "

                sed -i.orig "s|proxiesEnabled=false|proxiesEnabled=true|g" "$configurationFile"

                sed -i.orig "s/nonProxiedHosts=.*$/nonProxiedHosts=$(echo $proxyNo | sed 's/,/|/g')/g" "$configurationFile"

                local string="proxyData/HTTP/hasAuth=false"
                if [ ! "$(grep "$string" "$configurationFile")" ]; then
                    echo "$string" >>"$configurationFile"
                fi

                local string="proxyData/HTTP/host=$proxyHost"
                if [ ! "$(grep "$string" "$configurationFile")" ]; then
                    echo "$string" >>"$configurationFile"
                fi

                local string="proxyData/HTTP/port=$proxyPort"
                if [ ! "$(grep "$string" "$configurationFile")" ]; then
                    echo "$string" >>"$configurationFile"
                fi

                local string="proxyData/HTTPS/hasAuth=false"
                if [ ! "$(grep "$string" "$configurationFile")" ]; then
                    echo "$string" >>"$configurationFile"
                fi

                local string="proxyData/HTTPS/host=$proxyHost"
                if [ ! "$(grep "$string" "$configurationFile")" ]; then
                    echo "$string" >>"$configurationFile"
                fi

                local string="proxyData/HTTPS/port=$proxyPort"
                if [ ! "$(grep "$string" "$configurationFile")" ]; then
                    echo "$string" >>"$configurationFile"
                fi

                sed -i.orig '/^\s*$/d' "$configurationFile"

                checkExit $?
            fi
            ;;
            "disable")
            if [ "$proxyState" != "disabled" ]; then
                echo -n "# Disabling proxy settings for Anypoint Studio 6: "
                sed -i.orig "s|proxiesEnabled=true|proxiesEnabled=false|g" "$configurationFile"
                sed -i.orig "s/nonProxiedHosts=.*$/nonProxiedHosts=/g" "$configurationFile"
                sed -i.orig "s|proxyData/HTTP/hasAuth=false||g" "$configurationFile"
                sed -i.orig "s|proxyData/HTTP/host=$proxyHost||g" "$configurationFile"
                sed -i.orig "s|proxyData/HTTP/port=$proxyPort||g" "$configurationFile"
                sed -i.orig "s|proxyData/HTTPS/hasAuth=false||g" "$configurationFile"
                sed -i.orig "s|proxyData/HTTPS/host=$proxyHost||g" "$configurationFile"
                sed -i.orig "s|proxyData/HTTPS/port=$proxyPort||g" "$configurationFile"
                sed -i.orig '/^\s*$/d' "$configurationFile"
                checkExit $?
            fi
            ;;
            "status")
            echo "# Showing proxy settings for Anypoint Studio 6: "
            cat "$configurationFile"
            echo ""
            ;;
            *)
            printError "$0: invalid parameter \"$1\" passed; expected either \"enable\", \"disable\" or \"status\"."
            ;;
        esac
    else
        printError "$0 configuration file not found: \"$configurationFile\""
    fi
}

function proxyForAnypoint7 {
    local configurationFile="/Applications/Anypoint Studio 7.app//Contents/Eclipse/configuration/.settings/org.eclipse.core.net.prefs"
    if [ -e "$configurationFile" ]; then
        case "$1" in
            "detect")
            [[ -e "$configurationFile" ]] && echo true || echo false
            ;;
            "enable")
            if [ "$proxyState" != "enabled" ]; then
                echo -n "# Enabling proxy settings for Anypoint Studio 7: "

                sed -i.orig "s|proxiesEnabled=false|proxiesEnabled=true|g" "$configurationFile"

                sed -i.orig "s/nonProxiedHosts=.*$/nonProxiedHosts=$(echo $proxyNo | sed 's/,/|/g')/g" "$configurationFile"

                local string="proxyData/HTTP/hasAuth=false"
                if [ ! "$(grep "$string" "$configurationFile")" ]; then
                    echo "$string" >>"$configurationFile"
                fi

                local string="proxyData/HTTP/host=$proxyHost"
                if [ ! "$(grep "$string" "$configurationFile")" ]; then
                    echo "$string" >>"$configurationFile"
                fi

                local string="proxyData/HTTP/port=$proxyPort"
                if [ ! "$(grep "$string" "$configurationFile")" ]; then
                    echo "$string" >>"$configurationFile"
                fi

                local string="proxyData/HTTPS/hasAuth=false"
                if [ ! "$(grep "$string" "$configurationFile")" ]; then
                    echo "$string" >>"$configurationFile"
                fi

                local string="proxyData/HTTPS/host=$proxyHost"
                if [ ! "$(grep "$string" "$configurationFile")" ]; then
                    echo "$string" >>"$configurationFile"
                fi

                local string="proxyData/HTTPS/port=$proxyPort"
                if [ ! "$(grep "$string" "$configurationFile")" ]; then
                    echo "$string" >>"$configurationFile"
                fi

                sed -i.orig '/^\s*$/d' "$configurationFile"

                checkExit $?
            fi
            ;;
            "disable")
            if [ "$proxyState" != "disabled" ]; then
                echo -n "# Disabling proxy settings for Anypoint Studio 7: "
                sed -i.orig "s|proxiesEnabled=true|proxiesEnabled=false|g" "$configurationFile"
                sed -i.orig "s/nonProxiedHosts=.*$/nonProxiedHosts=/g" "$configurationFile"
                sed -i.orig "s|proxyData/HTTP/hasAuth=false||g" "$configurationFile"
                sed -i.orig "s|proxyData/HTTP/host=$proxyHost||g" "$configurationFile"
                sed -i.orig "s|proxyData/HTTP/port=$proxyPort||g" "$configurationFile"
                sed -i.orig "s|proxyData/HTTPS/hasAuth=false||g" "$configurationFile"
                sed -i.orig "s|proxyData/HTTPS/host=$proxyHost||g" "$configurationFile"
                sed -i.orig "s|proxyData/HTTPS/port=$proxyPort||g" "$configurationFile"
                sed -i.orig '/^\s*$/d' "$configurationFile"
                checkExit $?
            fi
            ;;
            "status")
            echo "# Showing proxy settings for Anypoint Studio 7: "
            cat "$configurationFile"
            echo ""
            ;;
            *)
            printError "$0: invalid parameter \"$1\" passed; expected either \"enable\", \"disable\" or \"status\"."
            ;;
        esac
    else
        printError "$0 configuration file not found: \"$configurationFile\""
    fi
}


function proxyForInsomnia {
    local configurationFile="$HOME/Library/Application Support/Insomnia/insomnia.Settings.db"
    if [ -e "$configurationFile" ]; then
        case "$1" in
            "detect")
            [[ -e "$configurationFile" ]] && echo true || echo false
            ;;
            "enable")
            if [ "$proxyState" != "enabled" ]; then
                echo -n "# Enabling proxy settings for Insomnia: "

                sed -i.orig "s|\"proxyEnabled\":false,|\"proxyEnabled\":true,|g" "$configurationFile"

                sed -i.orig "s|\"httpsProxy\":\"\",|\"httpsProxy\":\"$proxyHost:$proxyPort\",|g" "$configurationFile"

                sed -i.orig "s|\"httpProxy\":\"\",|\"httpProxy\":\"$proxyHost:$proxyPort\",|g" "$configurationFile"

                sed -i.orig "s|\"noProxy\":\"\",|\"noProxy\":\"$proxyNo\",|g" "$configurationFile"

                sed -i.orig "s|\"modified\":[0-9].*,$|\"modified\":$(date +%s),|g" "$configurationFile"

                sed -i.orig '/^\s*$/d' "$configurationFile"

                checkExit $?
            fi
            ;;
            "disable")
            if [ "$proxyState" != "disabled" ]; then
                echo -n "# Disabling proxy settings for Insomnia: "
                sed -i.orig "s|\"proxyEnabled\":true,|\"proxyEnabled\":false,|g" "$configurationFile"

                sed -i.orig "s|\"httpsProxy\":\"$proxyHost:$proxyPort\",|\"httpsProxy\":\"\",|g" "$configurationFile"

                sed -i.orig "s|\"httpProxy\":\"$proxyHost:$proxyPort\",|\"httpProxy\":\"\",|g" "$configurationFile"

                sed -i.orig "s|\"noProxy\":\"$proxyNo\",|\"noProxy\":\"\",|g" "$configurationFile"

                sed -i.orig "s|\"modified\":[0-9].*,$|\"modified\":$(date +%s),|g" "$configurationFile"

                sed -i.orig '/^\s*$/d' "$configurationFile"
                checkExit $?
            fi
            ;;
            "status")
            echo "# Showing proxy settings for Insomnia: "
            cat "$configurationFile"
            echo ""
            ;;
            *)
            printError "$0: invalid parameter \"$1\" passed; expected either \"enable\", \"disable\" or \"status\"."
            ;;
        esac
    else
        printError "$0 configuration file not found: \"$configurationFile\""
    fi
}

# If no parameters given, print usage.
if [ -z "$1" ] ; then
	printUsage
	exit 1
fi

# List the proxy functions.
functionList=$(typeset -F | awk '{print $3}'| grep 'proxyFor')

# Main case entry.
case "$1" in
    "on")
    for f in $functionList; do
        [[ "$($f detect)" == "true" ]] && $f enable
    done
    echo enabled > "$HOME/.proxy.state"
    ;;
    "off")
    for f in $functionList; do
        [[ "$($f detect)" == "true" ]] && $f disable
    done
    echo disabled > "$HOME/.proxy.state"
    ;;
    "status")
    for f in $functionList; do
        [[ "$($f detect)" == "true" ]] && $f status
    done
    ;;
    *)
    printUsage
    ;;
esac
