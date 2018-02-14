param 
(
    [Parameter(Mandatory=$true)][string]$serverInstance,[Parameter(Mandatory=$true)][string]$Database,[Parameter(Mandatory=$true)][string]$SqlScripts 
)
$Directory = "$PSScriptRoot\..\Database\$SqlScripts"


foreach ($f in Get-ChildItem -path $Directory -Filter *.sql | sort-object -desc ) 
{ 
  
  invoke-sqlcmd -InputFile $f.fullname -ServerInstance $serverInstance -Database $Database
}