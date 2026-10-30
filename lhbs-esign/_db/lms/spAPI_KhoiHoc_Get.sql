CREATE PROC [dbo].[spAPI_KhoiHoc_Get]
AS
BEGIN
    SELECT KH.KhoiID,
           KH.TenKhoiHoc,
           KH.KhoiHocCode
    FROM dbo.tblKhoi KH
    WHERE KH.Enable = 1;
END;