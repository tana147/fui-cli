CREATE PROCEDURE dbo.spAPI_SoGVCNDanhSachHocSinhLop
    @NienKhoa int,
    @CapID varchar(20),
    @LopID varchar(10),
    @sys_UserID varchar(20),
    @sys_SystemRight int
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Lọc danh sách lớp của niên khóa chỉ định
    SELECT
        l.LopID,
        l.TenLop,
        l.KhoiID,
        l.CapID,
        LopKey = SUBSTRING(l.TenLop, PATINDEX('%[^0-9]%', l.TenLop + 'A'), 50)
    INTO #LopMoi
    FROM dbo.tblLop l
    WHERE l.NienKhoa = @NienKhoa
      AND l.Enable = 1
      AND (
          @CapID = ''
          OR CHARINDEX(',' + CAST(l.CapID AS varchar(10)) + ',', ',' + @CapID + ',') > 0
          OR (@CapID = '23' AND l.KhoiID BETWEEN 6 AND 12)
      )
      AND (@LopID = '' OR l.LopID = @LopID);

    CREATE CLUSTERED INDEX IX_LopMoi ON #LopMoi(LopID);

    -- 2. Học sinh đã phân lớp trong năm học
    SELECT 
        hsl.HSLopID,
        hsl.HocSinhID,
        hsl.SoDanhBo,
        lm.LopID,
        lm.TenLop AS LopMoi,
        lm.KhoiID
    INTO #Nguon
    FROM dbo.tblHocSinhLop hsl
    INNER JOIN #LopMoi lm ON lm.LopID = hsl.LopID
    WHERE hsl.NienKhoa = @NienKhoa AND hsl.Enable = 1;

    -- 3. Fallback: Nếu có lớp chưa phân lớp, lấy danh sách dự kiến từ lớp cũ năm trước
    IF EXISTS (SELECT 1 FROM #LopMoi lm WHERE NOT EXISTS (SELECT 1 FROM #Nguon n WHERE n.LopID = lm.LopID))
    BEGIN
        INSERT INTO #Nguon (HSLopID, HocSinhID, SoDanhBo, LopID, LopMoi, KhoiID)
        SELECT
            lc.HSLopID,
            lc.HocSinhID,
            lc.SoDanhBo,
            lm.LopID,
            lm.TenLop,
            lm.KhoiID
        FROM dbo.tblHocSinhLop lc
        INNER JOIN dbo.tblLop lOld ON lOld.LopID = lc.LopID AND lOld.NienKhoa = @NienKhoa - 1 AND lOld.Enable = 1
        AND lc.NienKhoa = lOld.NienKhoa
        INNER JOIN #LopMoi lm ON lm.KhoiID = lOld.KhoiID + 1 
            AND lm.LopKey = SUBSTRING(lOld.TenLop, PATINDEX('%[^0-9]%', lOld.TenLop + 'A'), 50)
        WHERE lc.NienKhoa = @NienKhoa - 1
          AND lc.Enable = 1
          AND NOT EXISTS (SELECT 1 FROM #Nguon n WHERE n.LopID = lm.LopID);
    END;

    CREATE CLUSTERED INDEX IX_Nguon_HS ON #Nguon(HocSinhID);

    -- 4. Thông tin Lớp cũ của đúng các học sinh trong danh sách nguồn
    SELECT 
        hsl.HocSinhID,
        l.LopID AS LopCuID,
        l.TenLop AS TenLopCu,
        ROW_NUMBER() OVER (PARTITION BY hsl.HocSinhID ORDER BY hsl.HSLopID DESC) AS Rn
    INTO #LopCu
    FROM dbo.tblHocSinhLop hsl
    INNER JOIN #Nguon n ON n.HocSinhID = hsl.HocSinhID
    INNER JOIN dbo.tblLop l ON l.LopID = hsl.LopID AND l.NienKhoa = @NienKhoa - 1 AND l.Enable = 1
    AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.NienKhoa = @NienKhoa - 1 AND hsl.Enable = 1;

    CREATE CLUSTERED INDEX IX_LopCu_HS ON #LopCu(HocSinhID, Rn);

    -- 5. Trả về kết quả
    SELECT
        STT = ROW_NUMBER() OVER (ORDER BY n.KhoiID, n.LopMoi, hs.Ten, hs.Ho),
        n.HSLopID,
        hs.HocSinhID,
        MaHocSinh = CONVERT(varchar(20), hs.HocSinhID),
        HoTen = CONCAT(hs.Ho, N' ', hs.Ten),
        NgaySinh = ISNULL(hs.NgaySinh, ''),
        Nu = ISNULL(hs.Nu, 0),
        IsNu = ISNULL(hs.Nu, 0),
        n.LopID,
        n.LopMoi,
        LopCuID = ISNULL(lc.LopCuID, ''),
        LopCu = ISNULL(lc.TenLopCu, N''),
        n.KhoiID,
        KQRL = ISNULL(kqrl.KQRL_Sau, ISNULL(kqrl.KQRL_Truoc, N'')),
        KQHT = CAST(N'' AS nvarchar(200)),
        NhanXetGVCN = ISNULL(nx.NhanXetGVCN, N''),
        NhanXetGVCN_VeHocSinh_HTML = ISNULL(nx.NhanXetGVCN_VeHocSinh_HTML, N''),
        Cha = CAST(N'' AS nvarchar(200)),
        NgheNghiepCha = CAST(N'' AS nvarchar(200)),
        SDTCha = CAST(N'' AS nvarchar(50)),
        Me = CAST(N'' AS nvarchar(200)),
        NgheNghiepMe = CAST(N'' AS nvarchar(200)),
        SDTMe = CAST(N'' AS nvarchar(50)),
        NguoiDoDau = CAST(N'' AS nvarchar(200)),
        SDTNguoiDoDau = CAST(N'' AS nvarchar(50)),
        DiaChi = CAST(N'' AS nvarchar(500)),
        GhiChu = CAST(N'' AS nvarchar(500)),
        NhomAV = ISNULL(nhomAV.TenNhom, N'')
    FROM #Nguon n
    INNER JOIN dbo.tblHocSinh hs
        ON hs.HocSinhID = n.HocSinhID
       AND hs.TinhTrang = 0
    LEFT JOIN #LopCu lc
        ON lc.HocSinhID = n.HocSinhID AND lc.Rn = 1
    OUTER APPLY
    (
        -- Nhóm tiếng Anh (môn Ngoại ngữ, MonHocID = 76) của năm học hiện tại — chỉ tồn tại ở cấp 3 (khối 10-12)
        SELECT TOP 1 nAV.TenNhom
        FROM dbo.tblHocSinhNhom hsn
        INNER JOIN dbo.tblNhom nAV
            ON nAV.NhomID = hsn.NhomID
           AND nAV.Enable = 1
           AND nAV.NienKhoa = @NienKhoa
           AND nAV.MonHocID = 76
           AND nAV.IsNhomLMS_GiaoBai = 0
        WHERE hsn.HocSinhID = hs.HocSinhID
          AND hsn.Enable = 1
          AND n.KhoiID BETWEEN 10 AND 12
        ORDER BY hsn.HSNhomID DESC
    ) nhomAV
    LEFT JOIN
    (
        SELECT
            nxt.HocSinhID,
            nxtl.LopID,
            NhanXetGVCN = MAX(NULLIF(LTRIM(RTRIM(nxt.NhanXetGVCN)), N'')),
            NhanXetGVCN_VeHocSinh_HTML = MAX(NULLIF(LTRIM(RTRIM(nxt.NhanXetGVCN_VeHocSinh_HTML)), N''))
        FROM dbo.tblNhanXetThang_Lop nxtl
        INNER JOIN dbo.tblNhanXetThang nxt
            ON nxt.Lop_NhanXetThangID = nxtl.Lop_NhanXetThangID
           AND nxt.Enable = 1
        WHERE nxtl.NienKhoa = @NienKhoa - 1
          AND nxtl.Enable = 1
          AND (
              (nxt.NhanXetGVCN IS NOT NULL AND LTRIM(RTRIM(nxt.NhanXetGVCN)) <> N'')
              OR (nxt.NhanXetGVCN_VeHocSinh_HTML IS NOT NULL AND LTRIM(RTRIM(nxt.NhanXetGVCN_VeHocSinh_HTML)) <> N'')
          )
        GROUP BY nxt.HocSinhID, nxtl.LopID
    ) nx
        ON nx.HocSinhID = hs.HocSinhID
       AND nx.LopID = lc.LopCuID
    LEFT JOIN dbo.tblXetKetQuaRenLuyen kqrl
        ON kqrl.HocSinhID = hs.HocSinhID
       AND kqrl.LopID = lc.LopCuID
       AND kqrl.NienKhoa = @NienKhoa - 1
    ORDER BY n.KhoiID, n.LopMoi, hs.Ten, hs.Ho;
END
