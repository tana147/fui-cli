CREATE PROCEDURE [dbo].[spAPI_BaoCao_ThongKe_XepLoai_MonHoc_TheoKhoi]
    @NienKhoa INT,
    @MaCotDiem NVARCHAR(50),
    @MonHocID INT,
    @KhoiID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@NienKhoa, 0) = 0
    BEGIN
        RAISERROR(N'Niên khóa là bắt buộc.', 16, 1);
        RETURN;
    END;

    IF @MaCotDiem NOT IN (N'DiemGK_HK1', N'DiemCK_HK1', N'DiemGK_HK2', N'DiemCK_HK2')
    BEGIN
        RAISERROR(N'Cột điểm không hợp lệ.', 16, 1);
        RETURN;
    END;

    IF @KhoiID IS NULL OR @KhoiID NOT IN (0, 6, 7, 8, 9, 10, 11, 12)
    BEGIN
        RAISERROR(N'Khối không hợp lệ.', 16, 1);
        RETURN;
    END;

    DECLARE @CapID INT;
    SET @CapID =
    (
        SELECT mh.CapID
        FROM dbo.tblMonHoc AS mh
        WHERE mh.MonHocID = @MonHocID
          AND mh.Enable = 1
          AND mh.CapID IN (2, 3)
    );

    IF @CapID IS NULL
    BEGIN
        RAISERROR(N'Môn học không hợp lệ hoặc không thuộc cấp THCS/THPT.', 16, 1);
        RETURN;
    END;

    IF (@CapID = 2 AND @KhoiID NOT IN (0, 6, 7, 8, 9))
       OR (@CapID = 3 AND @KhoiID NOT IN (0, 10, 11, 12))
    BEGIN
        RAISERROR(N'Khối không thuộc cấp của môn học đã chọn.', 16, 1);
        RETURN;
    END;

    DECLARE @ClassScopeID INT = CASE WHEN @CapID = 3 THEN 2 ELSE 1 END;
    DECLARE @Semester NVARCHAR(10) = CASE
        WHEN @MaCotDiem IN (N'DiemGK_HK1', N'DiemCK_HK1') THEN N'HK1'
        ELSE N'HK2'
    END;

    -- Materialize target, roster và score sets once; các CTE lặp lại trước đây khiến SQL Server
    -- có thể mở rộng lại nhiều nhánh nối và tổng hợp trên bảng điểm lớn.
    SELECT targetRows.PhamViID, targetRows.DoiTuongID, targetRows.TenDoiTuong, targetRows.KhoiID, targetRows.CapID
    INTO #Targets
    FROM
    (
        SELECT @ClassScopeID AS PhamViID, l.LopID AS DoiTuongID, l.TenLop AS TenDoiTuong, l.KhoiID, l.CapID
        FROM dbo.tblLop AS l
        WHERE l.Enable = 1
          AND l.NienKhoa = @NienKhoa
          AND l.CapID = @CapID
          AND (@KhoiID = 0 OR l.KhoiID = @KhoiID)

        UNION ALL

        SELECT 3 AS PhamViID, n.NhomID AS DoiTuongID, n.TenNhom AS TenDoiTuong, n.KhoiID, n.CapID
        FROM dbo.tblNhom AS n
        WHERE n.Enable = 1
          AND n.NienKhoa = @NienKhoa
          AND n.CapID = @CapID
          AND (@KhoiID = 0 OR n.KhoiID = @KhoiID)
          AND n.MonHocID = @MonHocID
          AND ISNULL(n.IsNhomLMS_GiaoBai, 0) = 0
    ) AS targetRows;

    CREATE CLUSTERED INDEX IX_Targets_Scope_Object ON #Targets (PhamViID, DoiTuongID);
    CREATE NONCLUSTERED INDEX IX_Targets_Object ON #Targets (DoiTuongID);

    SELECT rosterRows.PhamViID, rosterRows.DoiTuongID, rosterRows.HocSinhID
    INTO #Roster
    FROM
    (
        SELECT @ClassScopeID AS PhamViID, l.LopID AS DoiTuongID, hsl.HocSinhID
        FROM dbo.tblLop AS l
        INNER JOIN dbo.tblHocSinhLop AS hsl
            ON hsl.LopID = l.LopID
           AND hsl.NienKhoa = l.NienKhoa
           AND hsl.Enable = 1
        INNER JOIN dbo.tblHocSinh AS hs
            ON hs.HocSinhID = hsl.HocSinhID
           AND hs.TinhTrang = 0
        WHERE l.Enable = 1
          AND l.NienKhoa = @NienKhoa
          AND l.CapID = @CapID
          AND (@KhoiID = 0 OR l.KhoiID = @KhoiID)

        UNION ALL

        SELECT 3 AS PhamViID, n.NhomID AS DoiTuongID, hsn.HocSinhID
        FROM dbo.tblNhom AS n
        INNER JOIN dbo.tblHocSinhNhom AS hsn
            ON hsn.Enable = 1
           -- Nhóm lịch sử được ưu tiên cho HK1; dùng nhóm hiện tại nếu hồ sơ cũ chưa lưu nhóm HK1.
           AND CASE
                   WHEN @Semester = N'HK1' THEN COALESCE(NULLIF(hsn.NhomID_HK1, ''), hsn.NhomID)
                   ELSE hsn.NhomID
               END = n.NhomID
        INNER JOIN dbo.tblHocSinh AS hs
            ON hs.HocSinhID = hsn.HocSinhID
           AND hs.TinhTrang = 0
        WHERE n.Enable = 1
          AND n.NienKhoa = @NienKhoa
          AND n.CapID = @CapID
          AND (@KhoiID = 0 OR n.KhoiID = @KhoiID)
          AND n.MonHocID = @MonHocID
          AND ISNULL(n.IsNhomLMS_GiaoBai, 0) = 0
    ) AS rosterRows;

    CREATE NONCLUSTERED INDEX IX_Roster_Scope_Object_Student ON #Roster (PhamViID, DoiTuongID, HocSinhID);
    CREATE NONCLUSTERED INDEX IX_Roster_Student_Scope_Object ON #Roster (HocSinhID, PhamViID, DoiTuongID);

    -- Dùng tập đối tượng đã lọc để đi từ một số nhỏ các MonHocLopID sang bảng điểm.
    SELECT DISTINCT DoiTuongID
    INTO #ScoreObjects
    FROM #Targets;

    CREATE UNIQUE CLUSTERED INDEX IX_ScoreObjects_Object ON #ScoreObjects (DoiTuongID);

    SELECT kq.HocSinhID,
           mhl.LopNhomID AS DoiTuongID,
           MAX(TRY_CONVERT(DECIMAL(10, 2), NULLIF(LTRIM(RTRIM(kq.KetQuaDanhGia_VI)), N''))) AS Diem
    INTO #DiemMonHoc
    FROM #ScoreObjects AS scoreObject
    INNER JOIN dbo.tblMonHocLop AS mhl
        ON mhl.LopNhomID = scoreObject.DoiTuongID
       AND mhl.Enable = 1
       AND mhl.NienKhoa = @NienKhoa
       AND mhl.MonHocID = @MonHocID
    INNER JOIN dbo.tblKetQuaHocTap AS kq
        ON kq.MonHocLopID = mhl.MonHocLopID
       AND kq.Enable = 1
       AND kq.NienKhoa = @NienKhoa
       AND kq.LopID = mhl.LopNhomID
    INNER JOIN dbo.TemplateBangDiemChiTiet AS ct
        ON ct.CotDiemID = kq.CotDiemID
       AND ct.Enable = 1
       AND ct.Semester = @Semester
       AND ct.MaCotDiem = @MaCotDiem
    INNER JOIN dbo.tblMonHoc AS mh
        ON mh.MonHocID = mhl.MonHocID
       AND mh.Enable = 1
       AND mh.CapID = @CapID
    GROUP BY kq.HocSinhID, mhl.LopNhomID
    OPTION (RECOMPILE);

    CREATE NONCLUSTERED INDEX IX_DiemMonHoc_Object_Student ON #DiemMonHoc (DoiTuongID, HocSinhID) INCLUDE (Diem);
    CREATE NONCLUSTERED INDEX IX_DiemMonHoc_Student_Object ON #DiemMonHoc (HocSinhID, DoiTuongID) INCLUDE (Diem);

    -- Chỉ hiện nhóm có điểm hợp lệ; bảng tạm giúp các bước lớp và nhóm dùng lại kết quả này.
    SELECT DISTINCT r.DoiTuongID
    INTO #NhomCoDiem
    FROM #Roster AS r
    INNER JOIN #DiemMonHoc AS d
        ON d.HocSinhID = r.HocSinhID
       AND d.DoiTuongID = r.DoiTuongID
    WHERE r.PhamViID = 3
      AND d.Diem BETWEEN 0 AND 10;

    CREATE UNIQUE CLUSTERED INDEX IX_NhomCoDiem_Object ON #NhomCoDiem (DoiTuongID);

    -- Dedupe roster once here so the final class-size count does not need COUNT(DISTINCT).
    SELECT DISTINCT reportRows.PhamViID, reportRows.DoiTuongID, reportRows.HocSinhID
    INTO #ReportRoster
    FROM
    (
        SELECT r.PhamViID, r.DoiTuongID, r.HocSinhID
        FROM #Roster AS r
        WHERE r.PhamViID = 3

        UNION ALL

        SELECT r.PhamViID, r.DoiTuongID, r.HocSinhID
        FROM #Roster AS r
        WHERE r.PhamViID = @ClassScopeID
          AND
          (
              NOT EXISTS (SELECT 1 FROM #NhomCoDiem)
              OR EXISTS
              (
                  SELECT 1
                  FROM #DiemMonHoc AS directScore
                  WHERE directScore.DoiTuongID = r.DoiTuongID
                    AND directScore.Diem BETWEEN 0 AND 10
              )
              OR EXISTS
              (
                  SELECT 1
                  FROM #Roster AS groupRoster
                  INNER JOIN #NhomCoDiem AS scoredGroup
                      ON scoredGroup.DoiTuongID = groupRoster.DoiTuongID
                  WHERE groupRoster.PhamViID = 3
                    AND groupRoster.HocSinhID = r.HocSinhID
              )
          )
    ) AS reportRows;

    CREATE NONCLUSTERED INDEX IX_ReportRoster_Scope_Object_Student ON #ReportRoster (PhamViID, DoiTuongID, HocSinhID);

    SELECT rawScores.PhamViID, rawScores.DoiTuongID, rawScores.HocSinhID, rawScores.Diem
    INTO #DiemTheoDoiTuongRaw
    FROM
    (
        -- Điểm lớp gốc gồm điểm trực tiếp và điểm nhóm có điểm của chính học sinh đó.
        SELECT @ClassScopeID AS PhamViID, r.DoiTuongID, r.HocSinhID, MAX(d.Diem) AS Diem
        FROM #ReportRoster AS r
        INNER JOIN #DiemMonHoc AS d
            ON d.HocSinhID = r.HocSinhID
        WHERE r.PhamViID = @ClassScopeID
          AND
          (
              d.DoiTuongID = r.DoiTuongID
              OR EXISTS
              (
                  SELECT 1
                  FROM #Roster AS groupRoster
                  INNER JOIN #NhomCoDiem AS scoredGroup
                      ON scoredGroup.DoiTuongID = groupRoster.DoiTuongID
                  WHERE groupRoster.PhamViID = 3
                    AND groupRoster.DoiTuongID = d.DoiTuongID
                    AND groupRoster.HocSinhID = r.HocSinhID
              )
          )
        GROUP BY r.DoiTuongID, r.HocSinhID

        UNION ALL

        -- Điểm nhóm chỉ dùng nhóm lịch sử HK1 / nhóm hiện tại HK2 như phần roster.
        SELECT 3 AS PhamViID, r.DoiTuongID, r.HocSinhID, d.Diem
        FROM #Roster AS r
        INNER JOIN #DiemMonHoc AS d
            ON d.HocSinhID = r.HocSinhID
           AND d.DoiTuongID = r.DoiTuongID
        WHERE r.PhamViID = 3
          AND EXISTS
          (
              SELECT 1
              FROM #NhomCoDiem AS scoredGroup
              WHERE scoredGroup.DoiTuongID = r.DoiTuongID
          )
    ) AS rawScores;

    SELECT PhamViID, DoiTuongID, HocSinhID, MAX(Diem) AS Diem
    INTO #DiemTheoDoiTuong
    FROM #DiemTheoDoiTuongRaw
    GROUP BY PhamViID, DoiTuongID, HocSinhID;

    CREATE CLUSTERED INDEX IX_DiemTheoDoiTuong_Scope_Object_Student ON #DiemTheoDoiTuong (PhamViID, DoiTuongID, HocSinhID);

    SELECT PhamViID,
           DoiTuongID,
           COUNT(*) AS DaCoDiem,
           AVG(Diem) AS DiemTrungBinh,
           SUM(CASE WHEN Diem >= 8 THEN 1 ELSE 0 END) AS Gioi,
           SUM(CASE WHEN Diem >= 6.5 AND Diem < 8 THEN 1 ELSE 0 END) AS Kha,
           SUM(CASE WHEN Diem >= 5 AND Diem < 6.5 THEN 1 ELSE 0 END) AS TrungBinh,
           SUM(CASE WHEN Diem >= 3.5 AND Diem < 5 THEN 1 ELSE 0 END) AS Yeu,
           SUM(CASE WHEN Diem < 3.5 THEN 1 ELSE 0 END) AS Kem
    INTO #TongDiem
    FROM #DiemTheoDoiTuong
    WHERE Diem BETWEEN 0 AND 10
    GROUP BY PhamViID, DoiTuongID;

    CREATE UNIQUE CLUSTERED INDEX IX_TongDiem_Scope_Object ON #TongDiem (PhamViID, DoiTuongID);

    SELECT t.PhamViID,
           @MonHocID AS MonHocID,
           t.DoiTuongID,
           t.TenDoiTuong,
           t.KhoiID,
           t.CapID,
           COUNT(r.HocSinhID) AS SiSo,
           ISNULL(td.DaCoDiem, 0) AS DaCoDiem,
           CAST(td.DiemTrungBinh AS DECIMAL(10, 2)) AS DiemTrungBinh,
           ISNULL(td.Gioi, 0) AS Gioi,
           ISNULL(td.Kha, 0) AS Kha,
           ISNULL(td.TrungBinh, 0) AS TrungBinh,
           ISNULL(td.Yeu, 0) AS Yeu,
           ISNULL(td.Kem, 0) AS Kem
    FROM #Targets AS t
    LEFT JOIN #ReportRoster AS r
        ON r.PhamViID = t.PhamViID
       AND r.DoiTuongID = t.DoiTuongID
    LEFT JOIN #TongDiem AS td
        ON td.PhamViID = t.PhamViID
       AND td.DoiTuongID = t.DoiTuongID
    WHERE
        (
            t.PhamViID = 3
            AND EXISTS (SELECT 1 FROM #NhomCoDiem AS scoredGroup WHERE scoredGroup.DoiTuongID = t.DoiTuongID)
        )
        OR
        (
            t.PhamViID = @ClassScopeID
            AND
            (
                NOT EXISTS (SELECT 1 FROM #NhomCoDiem)
                OR EXISTS
                (
                    SELECT 1
                    FROM #ReportRoster AS visibleClass
                    WHERE visibleClass.PhamViID = t.PhamViID
                      AND visibleClass.DoiTuongID = t.DoiTuongID
                )
            )
        )
    GROUP BY t.PhamViID, t.DoiTuongID, t.TenDoiTuong, t.KhoiID, t.CapID,
             td.DaCoDiem, td.DiemTrungBinh, td.Gioi, td.Kha, td.TrungBinh, td.Yeu, td.Kem
    ORDER BY t.PhamViID, t.KhoiID, t.TenDoiTuong;
END;
