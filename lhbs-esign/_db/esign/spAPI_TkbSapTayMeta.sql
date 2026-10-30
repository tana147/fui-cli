CREATE PROCEDURE spAPI_TkbSapTayMeta
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-10-06: du lieu phu cho "sap tay kieu co vua" (tab Toan truong) — trinh duyet tu tinh mau cac o co the
    -- chuyen/doi/day ngay khi bam 1 tiet, KHONG goi server moi lan bam. 1 result set (tAPI chi doc tap dau), phan loai:
    --   BAN    : GV bao ban tuan cua RunID, trai ra tung tiet (MaGV, Thu, Buoi, Tiet, Ten = ly do)
    --   MAXNGAY: gioi han so tiet/ngay cua mon theo khoi (MaMon, Khoi, SoTiet)
    --   DOI    : mon bat buoc xep tiet doi (MaMon)
    --   GVMON  : GV duoc phan cong day mon nao (MaGV, MaMon, Ten = ho ten) — de goi y doi GV cung mon
    --   PHONG  : (2026-10-09) phong co dinh cua lop theo mon, tu tblTKB_PhongLopMon — cot MaGV CHUA MA LOP,
    --            Ten = ma phong (giu nguyen bo cot cua result set). Dung de gan phong cho tiet them moi + bao trung phong.
    DECLARE @Tuan INT, @HocKy VARCHAR(4);
    SELECT @Tuan = TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
    SELECT @HocKy = ISNULL(MAX(HocKy), 'HK1') FROM tblTKB_ChayNhanh WHERE RunID = @RunID;

    SELECT 'BAN' AS Loai, g.MaGV, CAST(NULL AS VARCHAR(20)) AS MaMon, CAST(NULL AS VARCHAR(4)) AS Khoi,
           g.Thu, b.Buoi, t.Tiet, CAST(NULL AS INT) AS SoTiet, MAX(ISNULL(g.LyDo, N'GV báo bận')) AS Ten
    FROM tblTKB_GVCamTuyetDoi_Tuan g
    CROSS APPLY (VALUES ('Sang'), ('Chieu')) b(Buoi)
    CROSS APPLY (VALUES (1), (2), (3), (4), (5)) t(Tiet)
    WHERE g.Tuan = @Tuan AND (ISNULL(g.Buoi, '') = '' OR g.Buoi = b.Buoi) AND (g.Tiet IS NULL OR g.Tiet = t.Tiet)
    GROUP BY g.MaGV, g.Thu, b.Buoi, t.Tiet
    UNION ALL
    SELECT 'MAXNGAY', NULL, mq.MaMon, mq.Khoi, NULL, NULL, NULL,
           TRY_CAST(JSON_VALUE(mq.ThamSo, '$.soTiet') AS INT), NULL
    FROM tblTKB_MonQuyTac mq
    WHERE mq.Enable = 1 AND mq.LoaiQuyTac = 'MaxTietMoiNgay'
    UNION ALL
    SELECT 'DOI', NULL, mh.MaMon, NULL, NULL, NULL, NULL, NULL, NULL
    FROM tblTKB_MonHoc mh WHERE mh.BatBuocXepDoi = 1
    UNION ALL
    SELECT 'GVMON', x.MaGV, x.MaMon, NULL, NULL, NULL, NULL, NULL, gv.HoTen
    FROM (SELECT DISTINCT pc.MaGV, pc.MaMon FROM tblTKB_PhanCongGiangDay pc
          WHERE pc.Enable = 1 AND pc.HocKy = @HocKy AND pc.MaGV IS NOT NULL) x
    INNER JOIN tblTKB_GiaoVien gv ON gv.MaGV = x.MaGV
    UNION ALL
    SELECT 'PHONG', f.MaLop, f.MaMon, NULL, NULL, NULL, NULL, NULL, CAST(f.MaPhong AS NVARCHAR(200))
    FROM tblTKB_PhongLopMon f WHERE f.Enable = 1;
END
