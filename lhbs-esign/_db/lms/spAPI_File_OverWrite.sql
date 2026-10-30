CREATE PROC [dbo].[spAPI_File_OverWrite]
    @FileID_Origin    CHAR(32)
  , @FileID_OverWrite CHAR(32)
  , @Annotations      NVARCHAR(MAX)
  , @Sys_UserID       VARCHAR(9) = NULL
AS
BEGIN
    EXEC [LMS-LHBS-file].[dbo].[spIO_IN_OverWrite] @FileID_Origin = @FileID_Origin
                                                 , @FileID_OverWrite = @FileID_OverWrite
                                                 , @Annotations = @Annotations
                                                 , @UserUpdate = @Sys_UserID;
END;