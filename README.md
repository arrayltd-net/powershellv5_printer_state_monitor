# powershellv5_printer_state_monitor
Script to check printer states and report errors via email and local text file
main.ps1 contains comments at the top of the file regarding use of the script.

Get a list of all your installed printers:
Powershell > $a = get-wmiobject -class win32_printer | select name
Powershell > $a |out-file c:\powershell\printerlist.txt

In the printer_state_monitor_list.csv you must define the names of all printers to be monitored. 
The values for the default_printer_settings row must be defined
appenddefaultcodes - 0 (append codes) or 1 (don't append codes)
codestoignore - comma separated list of codes to ignore
schedule - days of week to monitor
starttime - start time to monitor
stoptime - stop time to monitor

The same values can be modified for each printer

If running an older version of powershell (older than v3) that doesn't recognize the get-content's -raw parameter, replace the existing final lines of code with this to manually insert line breaks and carriage returns after each line in the log before emailing it: 

    
 #send email 
    
   $body =""
   $bodyarray=""
   
    [array]$bodyarray = Get-Content -path "$text_output"
    
    foreach($b in $bodyarray){
        
        [string]$body += ($b  + "`r`n")
    }
   
     Send-MailMessage -from $sender -to $recipient -smtpserver $smtpserver -subject $subject -body $body  -Verbose

}
