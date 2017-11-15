function escapeForXML
{
    param([string]$data)
    return $data.Replace("&", "&amp;").Replace("<", "&lt;")
}

$connectionString = "DSN=AS/400;Uid=UPD;Pwd=SQL;"
$sql = @'
SELECT EXDESC
FROM LICENSE.EXAMMPF
ORDER BY EXDESC
'@
$connection = New-Object System.Data.Odbc.OdbcConnection($connectionString)
$connection.open()
$command = New-Object System.Data.Odbc.OdbcCommand($sql, $connection)
$dataAdapter = New-Object System.Data.Odbc.OdbcDataAdapter($command)
$dataTable = New-Object System.Data.DataTable
$null = $dataAdapter.fill($dataTable)
$connection.close()

$subjectMapping =
@{
    "BASIC SKILLS" = "Other";
    "BASIC SKILLS I: READING" = "Reading";
    "BASIC SKILLS II: WRITING" = "Writing";
    "BASIC SKILLS III: MATH" = "Mathematics";
    "CKA: ELEMENTARY EDUCATION" = "Other";
    "CKA: LANGUAGE ARTS" = "English Language Arts";
    "CKA: MATHEMATICS" = "Mathematics";
    "CKA: READING" = "Reading";
    "CKA: SCIENCE" = "Science";
    "CKA: SOCIAL STUDIES" = "Social Studies";
    "EDUCATIONAL ADMINISTRATOR" = "Other";
    "EDUCATIONAL DIAGNOSTICIAN" = "Other";
    "ELEM EDUC SUBTEST I" = "Other";
    "ELEM EDUC SUBTEST II" = "Other";
    "ELEM READING (PEARSON)" = "Reading";
    "FAMILY & CONSUMER SCIENCE" = "Physical, Health, and Safety Education";
    "FRENCH" = "Foreign Language and Literature";
    "GENERAL KNOWLEDGE" = "Other";
    "GERMAN" = "Foreign Language and Literature";
    "GIFTED EDUCATION" = "Other";
    "HEALTH EDUCATION" = "Physical, Health, and Safety Education";
    "LIBRARY MEDIA" = "Other";
    "MIDDLE LVL LANG ARTS" = "English Language Arts";
    "MIDDLE LVL MATHEMATICS" = "Mathematics";
    "MIDDLE LVL SCIENCE" = "Science";
    "MIDDLE LVL SOCIAL STUDIES" = "Social Studies";
    "MUSIC" = "Fine and Performing Arts";
    "PHYSICAL EDUCATION" = "Physical, Health, and Safety Education";
    "SCHOOL COUNSELOR" = "Other";
    "SPANISH" = "Foreign Language and Literature";
    "SPECIAL EDUCATION" = "Special Education";
    "TEACH COMP EARLY CHILDHD" = "Other";
    "TEACHER COMPETENCY ELEM" = "Other";
    "TEACHER COMPETENCY 2NDARY" = "Other";
    "TESOL" = "Other";
    "VISUAL ARTS" = "Fine and Performing Arts";
}

"<InterchangeDescriptors xlmns='http://ed.fi.org/0200'>"

foreach ($row in $dataTable.Rows)
{
    $exdesc = escapeForXml($row['EXDESC'].Trim())
    $academicSubjectMap = "";
    
    if ($subjectMapping.ContainsKey($row['EXDESC'].Trim()))
    {
        $academicSubjectMap = $subjectMapping[$row['EXDESC'].Trim()]
    }
    else
    {
        $academicSubjectMap = "Other";
    }
    
    "<AcademicSubjectDescriptor>"
        "<CodeValue>$exdesc</CodeValue>"
        "<ShortDescription>$exdesc</ShortDescription>"
        "<Description>$exdesc</Description>"
        "<Namespace>http://www.ped.state.nm.us/Descriptor/AcademicSubjectDescriptor.xml</Namespace>"
        "<AcademicSubjectMap>$academicSubjectMap</AcademicSubjectMap>"
    "</AcademicSubjectDescriptor>"
}

"</InterchangeDescriptors>"