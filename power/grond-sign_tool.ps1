# grond-sign_tool.ps1 - Sign a file using Microsoft Authenticode

# To create the needed certificates and sign this file:
#
# mkdir c:\windows\certs
# cd c:\windows\certs
#
# makecert -n "CN=PowerShell Local Certificate Root" -a sha1 `
#   -eku 1.3.6.1.5.5.7.3.3 -r -sv root.pvk root.cer -ss Root `
#   -sr localMachine
#
# makecert -pe -n "CN=PowerShell User" -ss MY -a sha1        `
#   -eku 1.3.6.1.5.5.7.3.3 -iv root.pvk -ic root.cer
#
# $cert = @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0]
# set-authenticodesignature grond-sign_tool.ps1 $cert
#

param([string] $file=$(throw "Please specify a filename."))
$cert = @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0]
Set-AuthenticodeSignature $file $cert

