CREATE PROCEDURE [dbo].[spAPI_HocLieu_UpdateOrder]
    @JsonData NVARCHAR(MAX), -- '[{"HocLieuID": 1, "ThuTu": 0}, {"HocLieuID": 5, "ThuTu": 1}]'
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE T
    SET 
        T.ThuTu = J.ThuTu,
        T.UpdateUser = @sys_UserID,
        T.UpdateTime = GETDATE()
    FROM 
        dbo.tblHocLieu AS T
    INNER JOIN 
        OPENJSON(@JsonData) WITH (
            HocLieuID INT '$.HocLieuID',
            ThuTu INT '$.ThuTu'
        ) AS J ON T.HocLieuID = J.HocLieuID;

    SELECT Success = 1, Message = N'Đã cập nhật thứ tự thành công.';
END
