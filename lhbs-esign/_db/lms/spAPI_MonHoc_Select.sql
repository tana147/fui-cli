CREATE PROC [dbo].[spAPI_MonHoc_Select]
AS
BEGIN
    SELECT MonHocID,
           MonHocName,
		   MonHocCode
    FROM dbo.tblMonHoc
    WHERE Enable = 1;
END;