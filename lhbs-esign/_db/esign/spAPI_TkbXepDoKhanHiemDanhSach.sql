CREATE PROCEDURE spAPI_TkbXepDoKhanHiemDanhSach
    @RunID INT,
    @Khoi VARCHAR(50) = '',
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-12 (theo de xuat nguoi dung "cho tôi 1 list GV chạy Round 2, để nhìn biết tại sao chạy
    -- cho GV đó trước"): liet ke TOAN BO GV thuoc dien Round 2 (cung dieu kien loc voi
    -- spAPI_TkbXepDoKhanHiem — loai MaMon='SH', loai GV day NhomCon cua Cum tach vi nhung GV do luon
    -- don sang Round 4), kem "Diem khan hiem" (cung CONG THUC dung de xep hang trong vong lap that su:
    -- (45 - so slot da ban - so slot GVCamTuyetDoi) / tong so tiet can day — CANG THAP cang duoc xu ly
    -- SOM). Diem nay la SNAPSHOT tai thoi diem goi (se doi khi cac GV khac duoc khoa them), sap xep
    -- theo dung thu tu se xu ly TIEP THEO cho nhung GV con lai.
    -- SUA 2026-09-17 (tong quat hoa cung fix voi GVDiem/spAPI_TkbXepDoKhanHiem — xem comment day du o
    -- spAPI_TkbChayAuto.GVDiem): tinh truoc @tmpGVHop (GV -> tap slot hop to co dinh) de so hien thi
    -- khop dung con so solver dung xu ly thuc te.
    DECLARE @tmpGVHop TABLE (MaGV VARCHAR(9), Thu INT, Buoi VARCHAR(10), Tiet INT, PRIMARY KEY (MaGV, Thu, Buoi, Tiet));
    ;WITH GVNhomSom AS (
        SELECT MaGV, 'TUNHIEN' AS MaNhom, 'To' AS LoaiNhom FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ tự nhiên%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'NGUVAN', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ ngữ văn%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'XAHOI', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ xã hội%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'HDTNHN', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Hoạt động trải nghiệm%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'TOAN', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Toán%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'TDANMT', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ thể dục - Quốc phòng - Nghệ thuật%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'TATIEUHOC', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Ngoại Ngữ%Khối Tiểu Học%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'TATRUNGHOC', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Ngoại Ngữ%Khối THCS%' AND LaThinhGiang = 0
        UNION ALL SELECT DISTINCT l.GVCN, l.Khoi, 'KhoiTH' FROM tblTKB_Lop l WHERE l.Enable = 1 AND l.Khoi IN ('01','02','03','04','05') AND l.GVCN IS NOT NULL
        UNION ALL SELECT DISTINCT l.GVCN, 'CAP23SH', 'KhoiCap23SH' FROM tblTKB_Lop l WHERE l.Enable = 1 AND l.Khoi IN ('06','07','08','09','10','11','12') AND l.GVCN IS NOT NULL
        UNION ALL SELECT MaGV, 'KT', 'KhoiTruong' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Khối trưởng%'
    )
    INSERT INTO @tmpGVHop (MaGV, Thu, Buoi, Tiet)
    SELECT DISTINCT gn.MaGV, lh.Thu, lh.Buoi, TRY_CAST(s.value AS INT)
    FROM tblTKB_LichHopCoDinh lh
    INNER JOIN GVNhomSom gn ON gn.LoaiNhom = lh.LoaiNhom AND gn.MaNhom = lh.MaNhom
    CROSS APPLY STRING_SPLIT(lh.TietList, ',') s
    WHERE lh.Enable = 1 AND TRY_CAST(s.value AS INT) <= 5;

    DECLARE @LopNhomCon TABLE (MaLop VARCHAR(10) PRIMARY KEY);
    INSERT INTO @LopNhomCon (MaLop)
    SELECT DISTINCT nc.MaLop FROM tblTKB_CumTach_NhomCon nc
    INNER JOIN tblTKB_CumTach ct ON ct.ID = nc.CumTachID AND ct.Enable = 1;

    DECLARE @GVDangXuLy VARCHAR(9) = (SELECT GVDangXuLy FROM tblTKB_ChayAutoLog WHERE RunID = @RunID);

    ;WITH PCGDLoc AS (
        SELECT pc.MaGV, SUM(pc.SoTietChuanTuan) AS TongCan
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        WHERE pc.Enable = 1 AND pc.MaMon <> 'SH'
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
        GROUP BY pc.MaGV
        HAVING SUM(pc.SoTietChuanTuan) > 0
    ),
    Tinh AS (
        SELECT p.MaGV, gv.HoTen AS TenGV, p.TongCan,
               -- SUA 2026-09-13 (dong bo Round 1.5/GVDiem): SoKhoi + TyLeTietDoi tinh tren TOAN BO
               -- PCGD cua GV (khong loc @Khoi/con lai) — phan anh dung do kho THAT, dung de dieu
               -- chinh DiemKhanHiem hien thi cho khop dung thu tu xu ly thuc te trong vong lap.
               (SELECT COUNT(DISTINCT l4.Khoi) FROM tblTKB_PhanCongGiangDay pc4
                INNER JOIN tblTKB_Lop l4 ON l4.MaLop = pc4.MaLop
                WHERE pc4.Enable = 1 AND pc4.MaMon <> 'SH' AND pc4.MaGV = p.MaGV
                  AND (@HocKy = '' OR pc4.HocKy = @HocKy)
                  AND (@TuanHienTai IS NULL OR pc4.TuanApDungTu IS NULL OR @TuanHienTai >= pc4.TuanApDungTu)
                  AND (@TuanHienTai IS NULL OR pc4.TuanApDungDen IS NULL OR @TuanHienTai <= pc4.TuanApDungDen)
                  AND (@TuanHienTai IS NULL OR pc4.ApDungTuanChan IS NULL OR pc4.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
               ) AS SoKhoi,
               ISNULL((SELECT CAST(SUM(CASE WHEN mh4.BatBuocXepDoi = 1 THEN pc4.SoTietChuanTuan ELSE 0 END) AS FLOAT) / NULLIF(SUM(pc4.SoTietChuanTuan), 0)
                FROM tblTKB_PhanCongGiangDay pc4
                LEFT JOIN tblTKB_MonHoc mh4 ON mh4.MaMon = pc4.MaMon
                WHERE pc4.Enable = 1 AND pc4.MaMon <> 'SH' AND pc4.MaGV = p.MaGV
                  AND (@HocKy = '' OR pc4.HocKy = @HocKy)
                  AND (@TuanHienTai IS NULL OR pc4.TuanApDungTu IS NULL OR @TuanHienTai >= pc4.TuanApDungTu)
                  AND (@TuanHienTai IS NULL OR pc4.TuanApDungDen IS NULL OR @TuanHienTai <= pc4.TuanApDungDen)
                  AND (@TuanHienTai IS NULL OR pc4.ApDungTuanChan IS NULL OR pc4.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
               ), 0) AS TyLeTietDoi,
               -- SUA 2026-09-12 (phat hien qua phan anh nguoi dung "Tong can it hon Da xep"): loai
               -- MaMon IN ('SH','HOP') khoi dem "Da xep" — 2 loai nay KHONG nam trong TongCan (SH bi
               -- loai o PCGDLoc phia tren, HOP la marker lich hop rieng khong phai tu PCGD) nen phai
               -- loai tuong tu o day de so sanh dung "tao" (apples-to-apples), tranh hien thi sai kieu
               -- "da xep nhieu hon can" du thuc te xep dung 100% cac mon that.
               (SELECT COUNT(*) FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaGV = p.MaGV AND k.MaMon NOT IN ('SH','HOP')) AS SoTietDaXep,
               -- SUA 2026-09-16 (tong quat hoa cung fix voi GVDiem/spAPI_TkbXepDoKhanHiem — xem comment
               -- day du o spAPI_TkbChayAuto.GVDiem): UNION them tblTKB_GVCamTuyetDoi_Tuan, vi bang theo
               -- RunID thuc te luon rong tru khi co "Bao ban" tuong tac, khien GV thinh giang/ban dai
               -- han hien thi DiemKhanHiem cao hon that (list nay chi de NGUOI DUNG XEM, phai khop dung
               -- con so solver dung de xu ly thuc te).
               (SELECT COUNT(DISTINCT CONCAT(Thu,'-',Buoi,'-',Tiet)) FROM (
                   SELECT Thu, Buoi, Tiet FROM tblTKB_GVCamTuyetDoi WHERE RunID = @RunID AND MaGV = p.MaGV
                   UNION
                   SELECT g.Thu, bb.Buoi, tt.Tiet
                   FROM tblTKB_GVCamTuyetDoi_Tuan g
                   CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE g.Buoi = '' OR g.Buoi = x.Buoi) bb
                   CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) y(Tiet) WHERE g.Tiet IS NULL OR g.Tiet = y.Tiet) tt
                   WHERE g.MaGV = p.MaGV AND g.Tuan = @TuanHienTai
                   UNION
                   SELECT h.Thu, h.Buoi, h.Tiet FROM @tmpGVHop h WHERE h.MaGV = p.MaGV
               ) camGop) AS SoSlotCam,
               -- SUA 2026-09-12 (theo de xuat nguoi dung, co du lieu that): "ChoRound4" gio chi tinh
               -- khi GV CON it nhat 1 dong cum tach CHUA duoc khoa (chua giai qua Round 1.5) — sau khi
               -- Round 1.5 khoa cung xong, GV duoc coi la khong con vuong cum tach nua, quay lai xu ly
               -- binh thuong trong Round 2 cho phan lop thuong con lai.
               CASE WHEN EXISTS (
                   SELECT 1 FROM @LopNhomCon nc INNER JOIN tblTKB_PhanCongGiangDay pc2 ON pc2.MaLop = nc.MaLop
                   WHERE pc2.Enable = 1 AND pc2.MaGV = p.MaGV
                     AND NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep k2 WHERE k2.RunID = @RunID AND k2.MaLop = pc2.MaLop AND k2.MaMon = pc2.MaMon AND k2.MaGV = pc2.MaGV)
               ) THEN 1 ELSE 0 END AS LaNhomCon
        FROM PCGDLoc p
        LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = p.MaGV
    )
    SELECT MaGV, TenGV, TongCan, SoTietDaXep, (TongCan - SoTietDaXep) AS ConLai,
           CAST((45.0 - SoTietDaXep - SoSlotCam) / NULLIF(TongCan, 0) / NULLIF(SoKhoi, 0) / (1.0 + TyLeTietDoi) AS DECIMAL(6,3)) AS DiemKhanHiem,
           CASE
               WHEN LaNhomCon = 1 THEN N'ChoRound4'
               WHEN TongCan - SoTietDaXep <= 0 THEN N'DaXong'
               WHEN MaGV = @GVDangXuLy THEN N'DangXuLy'
               ELSE N'ChuaXu'
           END AS TrangThai
    FROM Tinh
    -- SUA 2026-09-12 (theo phan anh nguoi dung "trang 1 toan DaXong tuong da xong het, gay hieu lam"):
    -- doi uu tien sap xep — GV DANG xu ly + SAP toi (ChuaXu) len DAU (de theo doi tien do de thay ngay
    -- ai dang lam, ai sap toi), DaXong/ChoRound4 xuong CUOI (chi de tham khao lai, khong can xem truoc).
    ORDER BY
        CASE WHEN MaGV = @GVDangXuLy THEN 0 WHEN TongCan - SoTietDaXep > 0 AND LaNhomCon = 0 THEN 1 WHEN LaNhomCon = 1 THEN 3 ELSE 2 END,
        CAST((45.0 - SoTietDaXep - SoSlotCam) / NULLIF(TongCan, 0) / NULLIF(SoKhoi, 0) / (1.0 + TyLeTietDoi) AS DECIMAL(6,3)) ASC;
END
