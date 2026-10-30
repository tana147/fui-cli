CREATE PROC [dbo].[spAPI_EL_BaoCaoLMS_KyNang_GetBy_HocSinhID]
    @MonHocID     INT           = 46,
    @LopID        NVARCHAR(100)  = '2448',
    @HocSinhID    INT           = 0 , --17100078,
    @AssignmentID INT           = 0 -- NULL = tất cả bài; có giá trị = bài cụ thể
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------
    -- 1. CẤU HÌNH MỨC ĐÁNH GIÁ KỸ NĂNG (%)
    --    < @Muc_ChuaDat   → Chưa đạt
    --    < @Muc_Dat       → Đạt
    --    >= @Muc_Dat      → Vượt đạt
    -------------------------------------------------------------
    DECLARE @Muc_ChuaDat  INT = 60;  -- Dưới 60%
    DECLARE @Muc_Dat      INT = 80;  -- Từ 60% đến dưới 80%


    -------------------------------------------------------------
    -- 2. SKILLS TẠM (Fallback khi bảng không có JSON Skills)
    --    Bạn có thể bỏ đoạn này khi triển khai thật.
    -------------------------------------------------------------
    DECLARE @SkillsTemp NVARCHAR(MAX) = N'[
        {"KyNang_MonHoc_ChiTietID":1,"TenKyNang":"Kĩ năng tính toán","MoTaKyNang":"Tính toán với sự chính xác tối đa"},
        {"KyNang_MonHoc_ChiTietID":2,"TenKyNang":"Kĩ năng phân tích","MoTaKyNang":"Phân tích vấn đề"},
		{"KyNang_MonHoc_ChiTietID":3,"TenKyNang":"Kĩ năng hiểu biết","MoTaKyNang":"Phân tích vấn đề"},
		{"KyNang_MonHoc_ChiTietID":4,"TenKyNang":"Kĩ năng đọc hiểu","MoTaKyNang":"Phân tích vấn đề"},
		{"KyNang_MonHoc_ChiTietID":5,"TenKyNang":"Kĩ năng tư duy logic","MoTaKyNang":"Phân tích vấn đề"}
    ]';


    -------------------------------------------------------------
    -- 3. LẤY DỮ LIỆU THÔ TỪ tblEL_Analytics_QuestionResults
    -------------------------------------------------------------
    ;WITH SourceData AS
    (
        SELECT 
              ana.*
            , CASE 
                    WHEN ana.Skills IS NOT NULL THEN ana.Skills
                    ELSE @SkillsTemp
              END AS SkillJSON
        FROM dbo.tblEL_Analytics_QuestionResults ana
        WHERE 
                ana.MonHocID = @MonHocID
            AND ana.LopID     = @LopID
            AND (ana.HocSinhID = @HocSinhID OR @HocSinhID =0)
            AND ana.IsDeleted = 0
            AND (@AssignmentID =0 OR ana.AssignmentID = @AssignmentID)
    ),

    -------------------------------------------------------------
    -- 4. MỞ JSON → TÁCH KỸ NĂNG THEO TỪNG CÂU
    -------------------------------------------------------------
    QuestionSkills AS
    (
        SELECT 
              sd.HocSinhID
            , sd.AssignmentID
            , sd.QuestionID_InJSON
            , sd.IsCorrect
            , sd.Score
            , sd.MaxScore

            , skill.KyNang_MonHoc_ChiTietID
            , skill.TenKyNang
            , skill.MoTaKyNang
        FROM SourceData sd
        CROSS APPLY OPENJSON(sd.SkillJSON)
        WITH (
              KyNang_MonHoc_ChiTietID INT            '$.KyNang_MonHoc_ChiTietID',
              TenKyNang               NVARCHAR(200)  '$.TenKyNang',
              MoTaKyNang              NVARCHAR(100)  '$.MoTaKyNang'
        ) skill
    ),

    -------------------------------------------------------------
    -- 5. GROUP THEO KỸ NĂNG (TỔNG HỢP TOÀN BỘ CÁC BÀI)
    -------------------------------------------------------------
    KetQuaKyNang AS
    (
        SELECT 
              HocSinhID
            , KyNang_MonHoc_ChiTietID
            , TenKyNang
            , MoTaKyNang
            , COUNT(*) AS TongSoCau
            , SUM(CASE WHEN IsCorrect = 1 THEN 1 ELSE 0 END) AS SoCauDung
            , SUM(Score) AS TongDiem
            , SUM(MaxScore) AS TongDiemToiDa
        FROM QuestionSkills
        GROUP BY 
              HocSinhID
            , KyNang_MonHoc_ChiTietID
            , TenKyNang
            , MoTaKyNang
    )

    -------------------------------------------------------------
    -- 6. SELECT CUỐI — TÍNH % + MỨC ĐÁNH GIÁ
    -------------------------------------------------------------
    SELECT 
          k.HocSinhID
        , CASE WHEN @AssignmentID IS NOT NULL THEN @AssignmentID ELSE NULL END AS AssignmentID
        , k.KyNang_MonHoc_ChiTietID
        , k.TenKyNang
        , k.MoTaKyNang
        , k.TongSoCau
        , k.SoCauDung

        -- % số câu đúng
        , CAST(k.SoCauDung * 100.0 / NULLIF(k.TongSoCau, 0) AS DECIMAL(5,2)) AS Score

        -- % theo MaxScore
        , CAST(k.TongDiem * 100.0 / NULLIF(k.TongDiemToiDa, 0) AS DECIMAL(5,2)) AS TyLeDiemTheoMax

        ---------------------------------------------------------
        --  MỨC ĐÁNH GIÁ
        ---------------------------------------------------------
        , CASE 
                WHEN (k.SoCauDung * 100.0 / NULLIF(k.TongSoCau, 0)) < @Muc_ChuaDat
                    THEN N'Chưa đạt'
                WHEN (k.SoCauDung * 100.0 / NULLIF(k.TongSoCau, 0)) < @Muc_Dat
                    THEN N'Đạt'
                ELSE N'Vượt đạt'
          END AS MucDanhGia

        -- Loại thống kê
        , CASE WHEN @AssignmentID IS NULL 
                THEN N'Tổng hợp tất cả bài' 
                ELSE N'Bài tập cụ thể' 
          END AS LoaiThongKe

    FROM KetQuaKyNang k
    ORDER BY KyNang_MonHoc_ChiTietID;

END;
