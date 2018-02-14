CREATE NONCLUSTERED INDEX [Ix_Cred] 
  ON [staging].[Credential] ([teachercandidateidentifier]) 
  include ([CERT_AREA_DESC], [CERT_AREA_KEY], [CERT_LEVEL_DESC], 
[CERT_LEVEL_KEY], [CERT_STATUS], [CERT_TYPE_CAT], [CERT_TYPE_DESC], 
[CERT_TYPE_KEY], [CERTIFICATE_NUMBER], [EFFECTIVE_DATE], [EXPIRATION_DATE]) 
WITH (drop_existing = on)
ON [PRIMARY]; 

CREATE CLUSTERED INDEX [PK_LOCATION_YEAR] 
  ON [staging].[LOCATION_YEAR] ([location_id]) 
  WITH (drop_existing = on)
  ON [PRIMARY]; 

CREATE CLUSTERED INDEX [PK_ObservationDataID] 
  ON [staging].[ObservationData] ([observationdataid]) 
  WITH (drop_existing = on)
  ON [PRIMARY]; 

CREATE NONCLUSTERED INDEX [IX_ObservationData] 
  ON [staging].[ObservationData] ([yearending], [schoolid], [licensenumber]) 
  include ([Assessment], [DistrictCode], [ObservationDataID])
  WITH (drop_existing = on)
  ON [PRIMARY]; 

CREATE CLUSTERED INDEX [PK_ObservationDataPivotID] 
  ON [staging].[ObservationDataPivot] ([id], [educationorganizationid]) 
  WITH (drop_existing = on)
  ON [PRIMARY]; 

CREATE CLUSTERED INDEX [PK_STAFF] 
  ON [staging].[STAFF] ([staff_key]) 
  WITH (drop_existing = on)
  ON [PRIMARY]; 

CREATE NONCLUSTERED INDEX [IX_BirthDate] 
  ON [staging].[STAFF] ([staff_birthdate]) 
  include ([DISTRICT_KEY], [STAFF_ID], [STAFF_KEY]) 
  WITH (drop_existing = on)
  ON [PRIMARY]; 

CREATE CLUSTERED INDEX [PK_STAFF_CERT_AREA] 
  ON [staging].[STAFF_CERT_AREA] ([cert_area_key]) 
  WITH (drop_existing = on)
  ON [PRIMARY]; 

CREATE CLUSTERED INDEX [PK_STAFF_CERT_LEVEL] 
  ON [staging].[STAFF_CERT_LEVEL] ([cert_level_key]) 
  WITH (drop_existing = on)
  ON [PRIMARY]; 

CREATE CLUSTERED INDEX [PK_STAFF_CERT_SNAPSHOT] 
  ON [staging].[STAFF_CERT_SNAPSHOT] ([cert_type_key], [cert_area_key], 
[cert_level_key]) 
WITH (drop_existing = on)
  ON [PRIMARY]; 

CREATE NONCLUSTERED INDEX [IX_CERTAREA] 
  ON [staging].[STAFF_CERT_SNAPSHOT] ([cert_area_key]) 
  include ([CERT_LEVEL_KEY], [CERT_STATUS], [CERT_TYPE_KEY], 
[CERTIFICATE_NUMBER], [EFFECTIVE_DATE], [EXPIRATION_DATE])
WITH (drop_existing = on)
 ON [PRIMARY]; 

CREATE NONCLUSTERED INDEX [IX_SCHOOL_YEAR] 
  ON [staging].[STAFF_CERT_SNAPSHOT] ([school_year]) 
  include ([CERT_AREA_KEY], [CERT_LEVEL_KEY], [CERT_STATUS], [CERT_TYPE_KEY], 
[CERTIFICATE_NUMBER], [EFFECTIVE_DATE], [EXPIRATION_DATE], [STAFF_KEY])
WITH (drop_existing = on)
ON [PRIMARY]; 

CREATE NONCLUSTERED INDEX [IX_CERTAREA_SCHOOLYEAR] 
  ON [staging].[STAFF_CERT_SNAPSHOT] ([cert_area_key], [school_year]) 
  include ([CERT_LEVEL_KEY], [CERT_STATUS], [CERT_TYPE_KEY], 
[CERTIFICATE_NUMBER], [EFFECTIVE_DATE], [EXPIRATION_DATE], [STAFF_KEY])
WITH (drop_existing = on)
 ON [PRIMARY]; 

CREATE NONCLUSTERED INDEX [IX_STAFF_DISTRICT] 
  ON [staging].[STAFF_CERT_SNAPSHOT] ([staff_key], [district_key]) 
  include ([CERTIFICATE_NUMBER]) 
  WITH (drop_existing = on)
  ON [PRIMARY]; 

CREATE CLUSTERED INDEX [PK_STAFF_CERT_TYPE] 
  ON [staging].[STAFF_CERT_TYPE] ([cert_type_key])
  WITH (drop_existing = on) 
  ON [PRIMARY]; 

CREATE NONCLUSTERED INDEX [IX_STAFF_SNAPSHOT] 
  ON [staging].[STAFF_SNAPSHOT] ([school_year]) 
  include ([ORIG_HIRE_DATE], [STAFF_ID])
  WITH (drop_existing = on)
  ON [PRIMARY]; 

CREATE NONCLUSTERED INDEX [IX_ExternalStaffID] 
  ON [staging].[Teachers] ([externalstaffid]) 
  include ([LicenseNumber], [TeacherID]) 
  WITH (drop_existing = on)
  ON [PRIMARY]; 