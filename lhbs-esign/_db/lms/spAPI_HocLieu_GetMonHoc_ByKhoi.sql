CREATE PROCEDURE [dbo].[spAPI_HocLieu_GetMonHoc_ByKhoi]
    @url1_KhoiID INT,
    @sys_UserID VARCHAR(9) -- Và các tham số @sys_ khác
AS
BEGIN
    SET NOCOUNT ON;

    -- Giả sử bạn có bảng tblMonHoc và có cột KhoiID
    -- Query này cần được điều chỉnh theo cấu trúc DB thực tế của bạn
    SELECT 
        mh.MonHocID,
        mh.MonHocName TenMonHoc
    FROM 
        dbo.tblMonHoc mh
    WHERE 
        mh.CapID = @url1_KhoiID
    ORDER BY 
        mh.MonHocName;
END
