CREATE PROCEDURE [dbo].[spAPI_Admin_Clear_TestData_20261021]
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Xóa dữ liệu test Cuộc thi & SHTT
    DELETE FROM dbo.ThiKHCN_ThanhVien;
    DELETE FROM dbo.ThiKHCN_File;
    DELETE FROM dbo.ThiKHCN_LichSu;
    DELETE FROM dbo.ThiKHCN_KhenThuong;
    DELETE FROM dbo.ThiKHCN_Dot;
    DELETE FROM dbo.ThiKHCN_DotDuyet;

    -- 2. Xóa các bản ghi test CGCN (chỉ giữ lại những bản ghi gốc từ ChuyenGiaoCongNghe_Old)
    DELETE FROM dbo.ChuyenGiaoCongNghe 
    WHERE CGCNID NOT IN (SELECT CGCNID FROM dbo.ChuyenGiaoCongNghe_Old);

    -- 3. Trả về kết quả kiểm tra
    SELECT 
        (SELECT COUNT(*) FROM dbo.ThiKHCN_KhenThuong) AS Remaining_ThiKHCN_KhenThuong,
        (SELECT COUNT(*) FROM dbo.ThiKHCN_Dot) AS Remaining_ThiKHCN_Dot,
        (SELECT COUNT(*) FROM dbo.ChuyenGiaoCongNghe) AS Remaining_CGCN,
        (SELECT COUNT(*) FROM dbo.ChuyenGiaoCongNghe_Old) AS Original_CGCN,
        (SELECT COUNT(*) FROM dbo.ThiKHCN_CongThucKhenThuong) AS CongThuc_Preserved;
END;
