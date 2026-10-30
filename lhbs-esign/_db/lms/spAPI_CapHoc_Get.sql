
CREATE PROC [dbo].[spAPI_CapHoc_Get]
AS
BEGIN
    SELECT CH.CapID,
           CH.TenCapHoc,
           CH.CapHocCode
    FROM dbo.tblCap CH
    WHERE CH.Enable = 1;
END;