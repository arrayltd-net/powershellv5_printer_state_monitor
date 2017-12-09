#Version 1
#Powershell 5.1.14393.1914

#Date: 12/9/2017

#author: AIC, www.arrayltd.net


#Features
#Read printer settings from printer_state_monitor_list.csv
#output printer errors to printer_state_monitor_log.txt
#email printer error log to email address
#powershell reminder: powershell passes parameters by not using parentheses.



#Sections: 
#Functions - the procedural code relies on these
#Variables - set script path and email options
#Procedural code - loops through printers and finds those with errors. 

#The CSV file contains printer settings: 


#The first row contains default settings, defined as a printer, which will overwrite all values except #appenddefaultcodes (they will be appended)
#If values are defined for printers in the file they will take priority and the default values will be ignored.

#name	 -  Data: Name of Printer. Only printers listed will be monitored 
#appenddefaultcodes	- Data: Whether or not to include the default printer's codestoignore. 0 or 1. Allows one to exempt a printer from
#     ignoring the default codes by setting to 0. 
#codestoignore	- Data: Codes that will not trigger an alert. Codes will be added to default printer's codes if appenddefaultcodes is 
#      set to 1 for the printer. If appenddefaultcodes is set to 0 then only these codes here will trigger an alert
#schedule	 -  Data: Days of week that will printer will be monitored. Default value will be used if none defined
#starttime - 	Data: Military time of day to start monitoring printer. Default value will be used if none defined
#stoptime  -  Data: Military time of day to start monitoring printer. Default value will be used if none defined




#*************
#*************
#FUNCTIONS
#*************
#*************

Function Get-PrinterSettings($printer,$printersettings) {

  for($j=0; $j -lt $printersettings.Count; $j++){
  [string]$a = $printers[$i].name
  [string]$b = $printersettings[$j].name
     if($b -like $a){
        return $printersettings[$j]    
        
      }
     }
    }  
    
 
 
 Function isWithinDayandTimeRange($schedule, $starttime, $stoptime){
    $fail = 0
   
    
    if($schedule.split(",") -notcontains (get-date).dayofweek){
       $fail = 1
    }
    
    if(($(get-date) -le $starttime)) {
        $amfail = 1
       
       }
    
    if(($(get-date) -ge $stoptime)) {
        $pmfail = 1
        
       }    
    
    if ($amfail -or $pmfail) {
        $fail = 1
       
    }
    
    return $fail
 
     }
        
 
   
 Function Convert-NumericCodeToEnglish($val){
    switch($val){
        0 {"Printer ready"}
        1 {"Printer paused"}
        2 {"Printer error"}
        4 {"Printer pending deletion"}
        8 {"Paper jam"}
        16 {"Out of paper"}
        32 {"Manual feed"}
        64 {"Paper problem"}
        128 {"Printer offline"}
        256 {"IO active"}
        512 {"Printer busy"}
        1024 {"Printing"}
        2048 {"Printer output bin full"}
        4096 {"Not available"}
        8192 {"Waiting"}
        16384 {"Processing"}
        32768 {"Initializing"}
        65536 {"Warming up"}
        131072 {"Toner low"}
        262144 {"No toner"}
        524288 {"Page punt"}
        1048576 {"User intervention"}
        2097152 {"Out of memory"}
        4194304 {"Door open"}
        8388608 {"Server unknown"}
        6777216 {"Power save"}
      
        default{}
        }   
}
 

#*************
#*************
#END FUNCTIONS
#*************
#*************



#Define Variables
$homepath = "c:\powershell\printer_state"
$printerlistfile = "$homepath\printer_state_monitor_list.csv"
$text_output = "$homepath\printer_state_monitor_log.txt"
$OFS ="" #new line character so the text shows up correctly on the receiving mail client

#Mail Server credential variables
$username = "smtp_username"
$password = "smtp_password"
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr


#mail server settings:  
$smtpserver= "smtp.gmail.com" 
$recipient = "recipient@recipient.com" 
$sender = "sender@sender.com" 
$subject = "Printer State Error Detected on Printsvr1" 
$email_body_heading = "Printer Error Detected"
$smtpport = "587"
# -UseSSL is specified in send-mailmessage command
#End Mail server


#get printer list text file
$PrinterSettings = Import-Csv "$printerlistfile"
$defaultprintersettings = $printersettings[0]



#this array will store printers that have errors - ?
$printers_with_errors_ht=@{} #new array to store printers that return errors

#Get printer objects on system an make an array of them. These are pulled from the system
$Printers = Get-WmiObject -class Win32_Printer



#Functions (search for this text to jump to this section

#import functions file
#. "$homepath\functions.ps1"




#Procedural

#This For loop is used to begin the processing on each printer found on the system and in the $printers array of objects
for ($i=0; $i -lt $printers.Count; $i++ ){
 
    #this if test returns non-zero as long as there is a printer listed in $printersettings. other printers are ignored completely
    if($CurrentPrinterSettings = Get-PrinterSettings $printers[$i] $printersettings){
      
        #populate unfilled values with default values
        $CurrentPrinterSettings.psobject.properties | ForEach-Object{
       
          if(!$_.value){
            $_.value = $defaultprintersettings.$($_.Name)
          }
        }           
     
      #compare current day and current time to the settings file. set variable true if it's outside of operating hours
      $is_inactive = isWithinDayandTimeRange $CurrentPrinterSettings.schedule $CurrentPrinterSettings.starttime $CurrentPrinterSettings.stoptime
      
      #compare codestoignore with printer code
      $code = $printers[$i].printerstate
      $code_is_error = 0
      $error_code = 0
      
      #build an array containing the default and the 
      
      [array]$codestoignore = $CurrentPrinterSettings.codestoignore.split(",")
      if($CurrentPrinterSettings.appenddefaultcodes -eq 1){
        $codesToIgnore += $defaultprintersettings.codestoignore.split(",")
      }

      if($codesToIgnore -notcontains $code){
       $code_is_error = 1
      }
      
     if($code_is_error -and !$is_inactive){
       $printers_with_errors_ht.add($CurrentPrinterSettings.name, $code)
     }
   }
 }


    
#build text file using data and email it if there is data in the hash table

if($printers_with_errors_ht.Count -ge 1){
    $email_body_heading | out-file $text_output
    ""  + $OFS| out-file -append $text_output

    foreach($kvp in $printers_with_errors_ht.GetEnumerator()){
        $name = $kvp.key
        $error_code = $kvp.value
        $error_code_verbose = Convert-NumericCodeToEnglish $error_code
       "Printer: " + $name + $OFS |out-file -append $text_output
       "Status code: " + $error_code  + $OFS | out-file -append $text_output
       "Verbose code: " + $error_code_verbose  + $OFS| out-file -append $text_output
          
       "" + $OFS| out-file -append $text_output
    }
     
    #send email 
    
    [string]$body = Get-Content -path "$text_output" -Raw
   
     Send-MailMessage -from $sender -to $recipient -smtpserver $smtpserver -port $smtpport -subject $subject -body $body  -Credential $cred -UseSsl -Verbose

}    
     
 
 
    
   
