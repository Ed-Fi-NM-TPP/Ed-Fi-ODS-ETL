function escapeForXML
{
    param([string]$data)
    return $data.Replace("&", "&amp;").Replace("<", "&lt;")
}

$connectionString = "DSN=AS/400;Uid=UPD;Pwd=SQL;"
$sql = @'
SELECT M.EXDESC, K.TXSSN, K.TXDOB, K.TXEXMD, V.TXRSLT, V.TXSCR
FROM
(
    SELECT TXEXMC, RIGHT(TXSSN, 5) AS TXSSN, TXDOB, TXEXMD, MAX(CASE WHEN TXFILE <> 0 THEN '1' ELSE '0' END CONCAT '-' CONCAT CASE WHEN TXCHGD > TXADDD THEN TXCHGD ELSE TXADDD END) AS TXFIRST
    FROM LICENSE.EXAMPF
    GROUP BY TXEXMC, RIGHT(TXSSN, 5), TXDOB, TXEXMD
)
K
INNER JOIN LICENSE.EXAMMPF M ON M.EXEXMC = K.TXEXMC
INNER JOIN LICENSE.EXAMPF V ON V.TXEXMC = K.TXEXMC AND RIGHT(V.TXSSN, 5) = K.TXSSN AND V.TXDOB = K.TXDOB AND V.TXEXMD = K.TXEXMD AND CASE WHEN V.TXFILE <> 0 THEN '1' ELSE '0' END CONCAT '-' CONCAT CASE WHEN V.TXCHGD > V.TXADDD THEN V.TXCHGD ELSE V.TXADDD END = K.TXFIRST
'@
$connection = New-Object System.Data.Odbc.OdbcConnection($connectionString)
$connection.open()
$command = New-Object System.Data.Odbc.OdbcCommand($sql, $connection)
$dataAdapter = New-Object System.Data.Odbc.OdbcDataAdapter($command)
$dataTable = New-Object System.Data.DataTable
$null = $dataAdapter.fill($dataTable)
$connection.close()

"<InterchangeStudentAssessment xmlns='http://ed-fi.org/0200'>"

foreach ($row in $dataTable.Rows)
{
    $txssn = $row['TXSSN'].ToString()
    $txdob = $row['TXDOB'].ToString()
    
    if ($txdob -eq "0")
    {
        $txdob = "00000000";
    }
    
    $studentUniqueId = $txssn + $txdob
    
    $txexmd = $row['TXEXMD'].ToString()
    $txexmd = $txexmd.Substring(0, 4) + '-' + $txexmd.Substring(4, 2) + '-' + $txexmd.Substring(6, 2)
    
    $exdesc = escapeForXml($row['EXDESC'].Trim())

    "<StudentAssessment>"
        "<AdministrationDate>$txexmd</AdministrationDate>"
        "<ScoreResult>"
            "<Result>$($row['TXSCR'])</Result>"
            "<ResultDatatypeType>Integer</ResultDatatypeType>"
            "<AssessmentReportingMethod>Proficiency level</AssessmentReportingMethod>"
        "</ScoreResult>"
        "<ScoreResult>"
            "<Result>$($row['TXRSLT'])</Result>"
            "<ResultDatatypeType>Level</ResultDatatypeType>"
            "<AssessmentReportingMethod>Pass-fail</AssessmentReportingMethod>"
        "</ScoreResult>"
        "<StudentReference>"
            "<StudentIdentity><StudentUniqueId>$studentUniqueId</StudentUniqueId></StudentIdentity>"
        "</StudentReference>"
        "<AssessmentReference>"
            "<AssessmentIdentity>"
                "<AssessmentTitle>Essential Skills</AssessmentTitle>"
                "<AcademicSubject>"
                    "<CodeValue>$exdesc</CodeValue>"
                    "<Namespace>http://www.ped.state.nm.us/Descriptor/AcademicSubjectDescriptor.xml</Namespace>"
                "</AcademicSubject>"
                "<AssessedGradeLevel>"
                    "<CodeValue>Professional Certification</CodeValue>"
                    "<Namespace>http://exchange.ed-fi.org/TPDP/Descriptor/GradeLevelDescriptor.xml</Namespace>"
                "</AssessedGradeLevel>"
                "<Version>1</Version>"
            "</AssessmentIdentity>"
        "</AssessmentReference>"
    "</StudentAssessment>"
}

"</InterchangeStudentAssessment>"