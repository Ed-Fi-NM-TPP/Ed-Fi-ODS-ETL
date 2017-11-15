param 
(
    [Parameter(Mandatory=$true)][string]$type,
    [string]$suffix = ''
)

if ($suffix -ne '')
{
	$suffix = '-' + $suffix
}

$name = "Interchange-$type$suffix"
$file = "$name.xml"

$manifest = 
"
<Interchanges>
    <Interchange>
        <Filename>$file</Filename>
        <Type>$($type.ToLower())</Type>
    </Interchange>
</Interchanges>
"

$manifest > "$PSScriptRoot\..\manifest\$file"

$bat = "$PSScriptRoot\BulkLoadManifest.bat"

$bat

. $bat $name

