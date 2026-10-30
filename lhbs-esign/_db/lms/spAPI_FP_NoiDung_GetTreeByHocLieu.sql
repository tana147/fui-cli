--. API lấy cây cấu trúc của một "cuốn sách"
--Mục đích: Sau khi người dùng chọn một "cuốn sách" từ danh sách ở trên, trang chi tiết sẽ gọi API này để lấy toàn bộ cây cấu trúc (Chương, Bài, Hoạt động...) của cuốn sách đó.
--Tên SP đề xuất: spAPI_FP_NoiDung_GetTreeByHocLieu
CREATE PROCEDURE [dbo].[spAPI_FP_NoiDung_GetTreeByHocLieu]
    @HocLieuID INT,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy thông tin chung của cuốn sách
    SELECT
        HocLieuID,
        TenHocLieu,
        (SELECT COUNT(*) FROM dbo.tblNoiDungHocLieu_FP nd WHERE nd.HocLieuID = hl.HocLieuID AND nd.Is_Xoa = 0) AS TongSoNoiDung,
        (SELECT COUNT(*) FROM dbo.tblNoiDungHocLieu_FP nd WHERE nd.HocLieuID = hl.HocLieuID AND nd.LoaiNoiDung LIKE 'QUIZ%' AND nd.Is_Xoa = 0) AS TongSoBaiKiemTra
    FROM
        dbo.tblHocLieu_FP hl
    WHERE
        hl.HocLieuID = @HocLieuID;

    -- Lấy toàn bộ cây cấu trúc bên trong cuốn sách đó
    SELECT 
        NoiDungID,
        ParentID,
        TenNoiDung,
        LoaiNoiDung,
        ThuTu,
		DataJson,
        CreateUser,
        CreateTime,
        UpdateUser,
        UpdateTime
    FROM 
        dbo.tblNoiDungHocLieu_FP
    WHERE 
        HocLieuID = @HocLieuID
        AND Is_Xoa = 0
    ORDER BY 
        ISNULL(ParentID, 0), ThuTu, TenNoiDung;
END
