
$Directory = "$PSScriptRoot\..\xml"

$LoadOrder =@("Descriptors",
 "EducationOrganization","EducationOrgCalendar",
 "MasterSchedule", "StaffAssociation" , 
 "TeacherCandidate-Credential", "TeacherCandidate-Student",
 "TeacherCandidate-TeacherCandidate","TeacherCandidate-TeacherCandidateAcademicRecord",
 "TeacherCandidate-TeacherCandidateFieldworkExperience","TeacherCandidate-TeacherCandidateTeacherPreparationProviderAssociation",
 "TeacherCandidate-TeacherCandidateTeacherPreparationProviderProgramAssociation", 
 "PerformanceMeasure-PerformanceMeasure","PerformanceMeasure-Rubric", "PerformanceMeasure-RubricLevel","PerformanceMeasure-RubricLevelResponse", 
 "AssessmentMetadata-EssentialSkills","StudentAssessment-EssentialSkills"
 );
 $FileOrder = @{};
 foreach( $file in Get-ChildItem $Directory)
 {
   $re = [regex]'(_|-)\d+\.xml$'
   $IndexFromTheEnd = if($re.Match($file).Success) { $re.Match($file).Value.Length } else { '.xml'.Length };
   $FileName =   $file.Name;
   $file = $file.Name.Substring('Interchnage-'.Length)
   $file = $file.Substring(0, $file.Length - $IndexFromTheEnd)

   $FileOrder.add(  $FileName , [array]::IndexOf($LoadOrder, $file));
 }

  
  $FileOrder = $FileOrder.GetEnumerator() | Sort-Object -Property Value

 foreach($file  in $FileOrder)
 {
   
     $command = "$PSScriptRoot\BulkLoadFile.ps1"

    

    . $command -file $file.Key;      

 }