CREATE PROC [dbo].[spAPI_EL_KyNang_MonHoc_Get] @MonHocID INT
AS
BEGIN
    SELECT *
    FROM
           tblEL_KyNang_MonHoc
    WHERE
           IsDeleted = 0
      AND  MonHocID   = @MonHocID;
END;