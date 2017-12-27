# powershellv5_printer_state_monitor
Script to check printer states and report errors via email and local text file
main.ps1 contains comments at the top of the file regarding use of the script.

Get a list of all your installed printers:
Powershell > $a = get-wmiobject -class win32_printer | select name
Powershell > $a |out-file c:\powershell\printerlist.txt

