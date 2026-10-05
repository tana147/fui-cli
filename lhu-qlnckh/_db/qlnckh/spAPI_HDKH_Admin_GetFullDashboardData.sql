CREATE  PROCEDURE dbo.spAPI_HDKH_Admin_GetFullDashboardData --2025,'',''
    @NamHoc INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Bước 1: Tính toán và lưu kết quả chi tiết của TẤT CẢ giảng viên vào một bảng tạm
    -- Đây là bước tốn tài nguyên nhất, nhưng chỉ làm một lần
    CREATE TABLE #GiangVienStats (
        NhanVienID VARCHAR(9), HoTen NVARCHAR(150), KhoaID VARCHAR(10),
        DinhMuc DECIMAL, DaThucHien DECIMAL, BaoLuu_Thieu DECIMAL, KetQua VARCHAR(20)
    );
    -- INSERT INTO #GiangVienStats ... (Logic tính toán phức tạp nằm ở đây)

    -- Dữ liệu mẫu
    INSERT INTO #GiangVienStats VALUES ('GV001', N'Nguyễn Văn A', 'CNTT', 150, 160, 10, 'DAT');
    INSERT INTO #GiangVienStats VALUES ('GV002', N'Trần Thị B', 'QTKD', 150, 100, -50, 'KHONGDAT');
    INSERT INTO #GiangVienStats VALUES ('GV003', N'Lê Văn C', 'CNTT', 150, 120, -30, 'KHONGDAT');

    -- === Bắt đầu trả về các tập kết quả ===

    -- Result Set 1: Thống kê Toàn trường
    SELECT
        COUNT(1) AS TongSoGiangVien,
        CAST(SUM(CASE WHEN KetQua = 'DAT' THEN 1 ELSE 0 END) AS DECIMAL) / COUNT(1) * 100 AS TyLeHoanThanh,
        AVG(DaThucHien) AS SoGioTB,
        (SELECT COUNT(1) FROM dbo.tblHDKH_KeKhai_Submission WHERE TrangThaiDuyet = 'CHO_DUYET' AND NamHoc = @NamHoc) AS HoatDongChoDuyet
    FROM #GiangVienStats;

    -- Result Set 2: Danh sách các Khoa
    SELECT DISTINCT KhoaID, KhoaID AS TenKhoa -- Thay bằng JOIN với bảng Khoa để có tên đầy đủ
    FROM #GiangVienStats;

    -- Result Set 3: Thống kê theo từng Khoa
    SELECT
        KhoaID,
        COUNT(1) AS TongSoGiangVien,
        CAST(SUM(CASE WHEN KetQua = 'DAT' THEN 1 ELSE 0 END) AS DECIMAL) / COUNT(1) * 100 AS TyLeHoanThanh,
        AVG(DaThucHien) AS SoGioTB
    FROM #GiangVienStats
    GROUP BY KhoaID;

    -- Result Set 4: Danh sách chi tiết TẤT CẢ Giảng viên
    SELECT * FROM #GiangVienStats;

    -- Result Set 5: Danh sách TẤT CẢ các hoạt động kê khai (để frontend tự lọc)
    EXEC dbo.spAPI_HDKH_KeKhai_GetSubmissionList  @NamHoc,  NULL,''; -- Gọi lại SP cũ với UserID=NULL để lấy tất cả

    -- Dọn dẹp
    DROP TABLE #GiangVienStats;
END
