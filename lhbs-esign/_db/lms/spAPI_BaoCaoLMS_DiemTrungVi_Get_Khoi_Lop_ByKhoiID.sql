CREATE PROC [dbo].[spAPI_BaoCaoLMS_DiemTrungVi_Get_Khoi_Lop_ByKhoiID]
@CapID INT,
@KhoiID INT,
@MonHocID INT,
@NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- 1. Lấy danh sách khối
    ------------------------------------------------------------
    DECLARE @Table_Khoi TABLE (KhoiID INT);

    IF (@KhoiID IS NULL OR @KhoiID = 0)
        INSERT INTO @Table_Khoi
        SELECT KhoiID FROM dbo.tblKhoi WHERE CapID = @CapID;
    ELSE
        INSERT INTO @Table_Khoi VALUES (@KhoiID);

    ------------------------------------------------------------
    -- 2. Lấy danh sách lớp + nhóm
    ------------------------------------------------------------
    DECLARE @Table_Lop TABLE (LopID NVARCHAR(20), KhoiID INT);

    INSERT INTO @Table_Lop
    SELECT l.LopID, k.KhoiID
    FROM dbo.tblLop l
    JOIN @Table_Khoi k ON l.KhoiID = k.KhoiID
    WHERE l.NienKhoa = @NienKhoa AND l.Enable = 1

    UNION ALL

    SELECT n.NhomID, k.KhoiID
    FROM dbo.tblNhom n
    JOIN @Table_Khoi k ON n.KhoiID = k.KhoiID
    WHERE n.NienKhoa = @NienKhoa AND n.Enable = 1;


    ------------------------------------------------------------
    -- 3. Bảng tạm chứa kết quả chi tiết
    ------------------------------------------------------------
    DECLARE @Result TABLE (
        HocSinhID NVARCHAR(20),
        HoTen NVARCHAR(200),
        AssignmentID INT,
        Title NVARCHAR(500),
        MedianScore DECIMAL(10,2),
        MedianMaxScore DECIMAL(10,2),
        SL_Lam INT,
        PercentScore DECIMAL(5,2),
		SoDanhBo NVARCHAR(20),
        LopID NVARCHAR(20),
        TenLop NVARCHAR(200),
        KhoiID INT
    );

    ------------------------------------------------------------
    -- 4. Gọi store con bằng INSERT EXEC (mỗi lớp 1 lần)
    ------------------------------------------------------------
    DECLARE @LopID NVARCHAR(20), @Khoi INT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT LopID, KhoiID FROM @Table_Lop;

    OPEN cur;
    FETCH NEXT FROM cur INTO @LopID, @Khoi;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO @Result (
            HocSinhID, HoTen, AssignmentID, Title,
            MedianScore, MedianMaxScore, SL_Lam, PercentScore, SoDanhBo
        )
        EXEC dbo.spAPI_BaoCaoLMS_DiemTrungVi_By_LopID
            @LopID = @LopID, @MonHocID = @MonHocID, @NienKhoa = @NienKhoa;

        -- ==== SỬA: dùng @LopID để lấy tên lớp/nhóm và gán cho các hàng vừa insert ====
        UPDATE r
        SET r.LopID = @LopID,
            r.KhoiID = @Khoi,
            r.TenLop = COALESCE(l.TenLop, n.TenNhom)
        FROM @Result r
        LEFT JOIN dbo.tblLop l ON l.LopID = @LopID AND l.NienKhoa = @NienKhoa
        LEFT JOIN dbo.tblNhom n ON n.NhomID = @LopID AND n.NienKhoa = @NienKhoa
        WHERE r.LopID IS NULL;

        FETCH NEXT FROM cur INTO @LopID, @Khoi;
    END

    CLOSE cur;
    DEALLOCATE cur;


    ------------------------------------------------------------
    -- 5. Trung vị theo lớp
    ------------------------------------------------------------
    ;WITH CTE_Lop AS (
        SELECT *,
               ROW_NUMBER() OVER(PARTITION BY LopID ORDER BY MedianScore) AS rn,
               COUNT(*) OVER(PARTITION BY LopID) AS cnt
        FROM @Result
    )
    SELECT 
        TenLop,
        LopID,
        KhoiID,
        COUNT(*) AS SoHocSinh,
        ROUND(AVG(CASE WHEN rn IN ((cnt+1)/2, (cnt+2)/2) THEN MedianScore END), 2) AS MedianScore_Lop,
        ROUND(AVG(CASE WHEN rn IN ((cnt+1)/2, (cnt+2)/2) THEN PercentScore END), 2) AS MedianPercent_Lop,
        SUM(SL_Lam) AS TongBaiLam
    FROM CTE_Lop
    GROUP BY TenLop, LopID, KhoiID
    ORDER BY TenLop, KhoiID, LopID;


    ------------------------------------------------------------
    -- 6. Trung vị theo khối
    ------------------------------------------------------------
    ;WITH CTE_Khoi AS (
        SELECT *,
               ROW_NUMBER() OVER(PARTITION BY KhoiID ORDER BY MedianScore) AS rn,
               COUNT(*) OVER(PARTITION BY KhoiID) AS cnt
        FROM @Result
    )
    SELECT 
        KhoiID,
        COUNT(*) AS SoHocSinh,
        ROUND(AVG(CASE WHEN rn IN ((cnt+1)/2, (cnt+2)/2) THEN MedianScore END), 2) AS MedianScore_Khoi,
        ROUND(AVG(CASE WHEN rn IN ((cnt+1)/2, (cnt+2)/2) THEN PercentScore END), 2) AS MedianPercent_Khoi,
        SUM(SL_Lam) AS TongBaiLam
    FROM CTE_Khoi
    GROUP BY KhoiID
    ORDER BY KhoiID;

END
