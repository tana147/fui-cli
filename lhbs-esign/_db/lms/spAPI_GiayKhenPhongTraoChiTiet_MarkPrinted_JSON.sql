CREATE PROCEDURE [dbo].[spAPI_GiayKhenPhongTraoChiTiet_MarkPrinted_JSON]
    @JsonData   NVARCHAR(MAX)
  , @sys_UserID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ cập nhật trạng thái in sau khi API tạo PDF trả về thành công;
    -- tách riêng khỏi SP sửa nội dung để không ghi đè dữ liệu giấy khen.
    UPDATE t
    SET    t.Is_DaIn     = 1
         , t.UpdateUser  = @sys_UserID
         , t.UpdateTime  = GETDATE()
    FROM dbo.tblGiayKhenPhongTraoChiTiet AS t
    INNER JOIN OPENJSON(@JsonData)
    WITH
    (
        ChiTietID INT
    ) AS j ON j.ChiTietID = t.ChiTietID
    WHERE t.Enable = 1;

    SELECT Updated = @@ROWCOUNT;
END
