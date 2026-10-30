CREATE PROC [dbo].[spAPI_MonHoc1_Select]
AS
BEGIN
    SELECT MonHocID,
           MonHocName, 
		   CapID,
		  MonHocName + N' (Cấp ' + CAST(CapID AS nvarchar) + ')' AS TenHienThi

    FROM dbo.tblMonHoc
    WHERE Enable = 1;
END;
