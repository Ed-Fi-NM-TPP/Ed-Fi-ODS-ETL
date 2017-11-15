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

"<InterchangeAssessmentMetadata xmlns='http://ed-fi.org/0200'>"

foreach ($row in $dataTable.Rows)
{
    $exdesc = escapeForXml($row['EXDESC'].Trim())
    
    "<Assessment>"
        "<AssessmentTitle>Essential Skills</AssessmentTitle>"
        "<AssessmentIdentificationCode>
            <IdentificationCode>Essential Skills-$exdesc-1</IdentificationCode>
            <AssessmentIdentificationSystem>
                <CodeValue>District</CodeValue>
                <Namespace>http://ed-fi.org/Descriptor/AssessmentIdentificationSystemDescriptor.xml</Namespace>
            </AssessmentIdentificationSystem>
         </AssessmentIdentificationCode>"
        "<AcademicSubject>"
            "<CodeValue>$exdesc</CodeValue>"
            "<Namespace>http://www.ped.state.nm.us/Descriptor/AcademicSubjectDescriptor.xml</Namespace>"
        "</AcademicSubject>"
        "<AssessedGradeLevel>"
            "<CodeValue>Professional Certification</CodeValue>"
            "<Namespace>http://exchange.ed-fi.org/TPDP/Descriptor/GradeLevelDescriptor.xml</Namespace>"
        "</AssessedGradeLevel>"
        "<Version>1</Version>"
    "</Assessment>"
}

"</InterchangeAssessmentMetadata>"