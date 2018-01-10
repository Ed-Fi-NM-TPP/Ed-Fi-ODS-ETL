
$Directory = "$PSScriptRoot\..\xml"

 foreach( $file in Get-ChildItem $Directory)
 {
   $re = [regex]'Descriptors|Assessment'
    if( !$re.Match($file).Success) {
   
          Remove-Item $file
          Write-Host $file
   }
   
 }