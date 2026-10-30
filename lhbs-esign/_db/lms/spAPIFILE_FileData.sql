CREATE PROCEDURE [dbo].[spAPIFILE_FileData] --'1D982737632240B39DFDD3D3552459E6'
@FileID CHAR(32)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.FileData WHERE FileID = @FileID)
	BEGIN
		SELECT 
			   [FileName],
			   ContentType,
			   Size,
			   FileContent = BinaryContent
		FROM dbo.FileData
		WHERE FileID = @FileID;
	END
	ELSE
	BEGIN
		EXEC [LMS-LHBS-file].[dbo].[spIO_OUT_FileSelect] @FileID;
	END

END