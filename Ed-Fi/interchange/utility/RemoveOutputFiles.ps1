$Directory = "$PSScriptRoot\..\out"

 foreach( $file in Get-ChildItem $Directory)
 {
  
          Remove-Item $file.FullName
          Write-Host $file.FullName
   
 }