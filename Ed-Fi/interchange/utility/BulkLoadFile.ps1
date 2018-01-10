param 
(
    [Parameter(Mandatory=$true)][string]$file
)

$re = [regex] '(_\d+|\S+)\.xml$'
if ($file.IndexOf('Interchange-') -ne 0 -Or !$re.IsMatch($file))
{
	Write-Error "$file does not follow the naming convention Interchange-Type.xml or Interchange-Type-Suffix.xml"
	return
}

$file = $file.Substring('Interchange-'.Length);
$file = $file.Substring(0, $file.Length - 4);
$suffix = ""

$hyphenPosition = $file.IndexOf('-')

if ($hyphenPosition -ne -1)
{
	$suffix = $file.Substring($hyphenPosition + 1)
	$file = $file.Substring(0, $hyphenPosition)
}

 $type = $file


$command = "$PSScriptRoot\BulkLoadInterchange.ps1"

if ($suffix -eq "")
{
	. $command -type $type
}
else
{
	. $command -type $type -suffix $suffix
}

