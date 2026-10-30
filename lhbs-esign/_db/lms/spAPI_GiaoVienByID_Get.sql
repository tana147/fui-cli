CREATE PROCEDURE [dbo].[spAPI_GiaoVienByID_Get]
    @ToGiangDayID INT = NULL,       
    @CapID INT = NULL,              
    @GiaoVienID NVARCHAR(50) = NULL 
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra điều kiện truyền vào: Nếu truyền CapID, cần phải có ToGiangDayID và ngược lại
    IF (@CapID IS NOT NULL AND @ToGiangDayID IS NULL) OR (@CapID IS NULL AND @ToGiangDayID IS NOT NULL)
    BEGIN
        RAISERROR('Khi lọc theo CapID, bạn phải cung cấp cả ToGiangDayID và ngược lại.', 16, 1);
        RETURN;
    END;

    -- Tạo bảng tạm để lưu kết quả cuối cùng
    CREATE TABLE #KetQua (
        GiaoVienID NVARCHAR(50),
        HoTenGV NVARCHAR(100),
        MonHocID INT,
        MonHocName NVARCHAR(100),
        Color NVARCHAR(10),
        ToGiangDayID INT,
        CapID INT
    );

    -- Lấy dữ liệu giáo viên
    IF @GiaoVienID IS NOT NULL
    BEGIN
        -- Nếu có GiaoVienID cụ thể
        INSERT INTO #KetQua (GiaoVienID, HoTenGV, MonHocID, MonHocName, Color, ToGiangDayID, CapID)
        SELECT 
            GV.GiaoVienID, 
            GV.HoGV + ' ' + GV.TenGV AS HoTenGV,
            TG.MonHocID,
            MH.MonHocName,
            MH.Color,
            TGD.ToGiangDayID,
            TGD.CapID
        FROM dbo.tblGiaoVien GV
        LEFT JOIN dbo.tblToGiangDay_GiaoVien_MonHoc TG ON GV.GiaoVienID = TG.GiaoVienID
        LEFT JOIN dbo.tblMonHoc MH ON TG.MonHocID = MH.MonHocID
        LEFT JOIN dbo.tblToGiangDay TGD ON TG.ToGiangDayID = TGD.ToGiangDayID
        WHERE 
            GV.GiaoVienID = @GiaoVienID
            AND GV.Enable = 1;
    END
    ELSE IF @ToGiangDayID IS NOT NULL AND @CapID IS NOT NULL
    BEGIN
        -- Nếu có ToGiangDayID và CapID
        INSERT INTO #KetQua (GiaoVienID, HoTenGV, MonHocID, MonHocName, Color, ToGiangDayID, CapID)
        SELECT 
            DISTINCT TG.GiaoVienID, 
            GV.HoGV + ' ' + GV.TenGV AS HoTenGV,
            TG.MonHocID,
            MH.MonHocName,
         	MH.Color,
            TGD.ToGiangDayID,
            TGD.CapID
        FROM dbo.tblToGiangDay_GiaoVien_MonHoc TG
        INNER JOIN dbo.tblGiaoVien GV ON TG.GiaoVienID = GV.GiaoVienID
        LEFT JOIN dbo.tblMonHoc MH ON TG.MonHocID = MH.MonHocID
        LEFT JOIN dbo.tblToGiangDay TGD ON TG.ToGiangDayID = TGD.ToGiangDayID
        WHERE 
            TG.ToGiangDayID = @ToGiangDayID
            AND TGD.CapID = @CapID
            AND GV.Enable = 1;
    END
    ELSE
    BEGIN
        -- Nếu không có tham số, lấy tất cả giáo viên
        INSERT INTO #KetQua (GiaoVienID, HoTenGV, MonHocID, MonHocName, Color, ToGiangDayID, CapID)
        SELECT 
            GV.GiaoVienID, 
            GV.HoGV + ' ' + GV.TenGV AS HoTenGV,
            TG.MonHocID,
            MH.MonHocName,
         	MH.Color,
            TGD.ToGiangDayID,
            TGD.CapID
        FROM dbo.tblGiaoVien GV
        LEFT JOIN dbo.tblToGiangDay_GiaoVien_MonHoc TG ON GV.GiaoVienID = TG.GiaoVienID
        LEFT JOIN dbo.tblMonHoc MH ON TG.MonHocID = MH.MonHocID
        LEFT JOIN dbo.tblToGiangDay TGD ON TG.ToGiangDayID = TGD.ToGiangDayID
        WHERE 
             GV.Enable = 1;
    END

    -- Trả về kết quả
    SELECT GiaoVienID, HoTenGV  AS HoTenGV, MonHocID, MonHocName, Color, ToGiangDayID, CapID
	FROM #KetQua ORDER BY GiaoVienID, MonHocID;

    -- Xóa bảng tạm
    DROP TABLE #KetQua;
END;
