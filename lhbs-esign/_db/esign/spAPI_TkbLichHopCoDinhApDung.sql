CREATE PROCEDURE spAPI_TkbLichHopCoDinhApDung
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Ap dung toan bo lich hop to/khoi trong tblTKB_LichHopCoDinh vao phien TKB dang xay — chen
    -- thang tung dong that (RunID, MaLop=MaNhom, Thu, Buoi, Tiet, MaMon='HOP', MaGV) vao
    -- tblTKB_KetQuaXep, dung R17 (giong het spAPI_TkbKhoaPhongDungChungApDung). GVNhom/Expanded
    -- CTE lay y het logic dang dung trong spAPI_TkbChayAuto (GVBanCoDinh) de xac dinh GV nao thuoc
    -- nhom nao. Chi lay Tiet<=5 vi lich hop tiet 8-9 nam ngoai gio ban tru, ngoai pham vi mo hinh.
    --
    -- Loc theo Khoi cua RunID: 1 To chuyen mon / Khoi truong co the co GV day nhieu khoi khac
    -- nhau — neu khong loc se chen HOP cho ca truong (da xay ra: 603 dong) du RunID chi dang xay
    -- cho 1 khoi. Chi chen cho GV THAT SU co day (PCGD) trong khoi cua RunID nay. Khoi luu trong
    -- log co the la '1+' (rut gon khi gop nhieu khoi qua dau phay luc goi Auto/PhienMoi) — truong
    -- hop nay khong the xac dinh chinh xac tap khoi nen giu hanh vi cu (khong loc, ap dung tat ca).
    DECLARE @KhoiRun VARCHAR(50) = (SELECT Khoi FROM tblTKB_ChayAutoLog WHERE RunID = @RunID);
    DECLARE @LocTheoKhoi BIT = CASE WHEN @KhoiRun IS NOT NULL AND @KhoiRun <> '' AND RIGHT(@KhoiRun, 1) <> '+' THEN 1 ELSE 0 END;

    DECLARE @SoLuongChen INT = 0;

    ;WITH GVNhom AS (
        SELECT MaGV, 'TUNHIEN' AS MaNhom, 'To' AS LoaiNhom FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ tự nhiên%'
        UNION ALL SELECT MaGV, 'NGUVAN', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ ngữ văn%'
        UNION ALL SELECT MaGV, 'XAHOI', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ xã hội%'
        UNION ALL SELECT MaGV, 'HDTNHN', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Hoạt động trải nghiệm%'
        UNION ALL SELECT MaGV, 'TOAN', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Toán%'
        UNION ALL SELECT MaGV, 'TDANMT', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ thể dục - Quốc phòng - Nghệ thuật%'
        -- Hop khoi Tieu hoc chi danh cho GVCN thuc su cua lop (tblTKB_Lop.GVCN) — KHONG suy luan qua
        -- "co day mon gi cho lop thuoc khoi do" nhu truoc, vi GV bo mon day cheo nhieu khoi/cap (vd
        -- TD, Nhac, MT) se bi gan nham vao hop cua MOI khoi ho day qua (phat hien 2026-08-27).
        UNION ALL SELECT DISTINCT l.GVCN, l.Khoi, 'KhoiTH' FROM tblTKB_Lop l WHERE l.Enable = 1 AND l.Khoi IN ('01','02','03','04','05') AND l.GVCN IS NOT NULL
        UNION ALL SELECT MaGV, 'KT', 'KhoiTruong' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Khối trưởng%'
    ),
    Expanded AS (
        SELECT DISTINCT gn.MaGV, lh.LoaiNhom, lh.MaNhom, lh.Thu, lh.Buoi, TRY_CAST(s.value AS INT) AS Tiet
        FROM tblTKB_LichHopCoDinh lh
        INNER JOIN GVNhom gn ON gn.LoaiNhom = lh.LoaiNhom AND gn.MaNhom = lh.MaNhom
        CROSS APPLY STRING_SPLIT(lh.TietList, ',') s
        WHERE lh.Enable = 1
    )
    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV)
    SELECT @RunID, e.MaNhom, e.Thu, e.Buoi, e.Tiet, 'HOP', e.MaGV
    FROM Expanded e
    WHERE e.Tiet <= 5
      AND (
          @LocTheoKhoi = 0
          -- Nhom KhoiTH gan lien 1 khoi cu the (vd hop khoi 2) — phai khop dung MaNhom, khong
          -- duoc suy tu "GV co day khoi nay" vi 1 GV chuyen (TD-AN-MT, Khoi truong...) co the day
          -- nhieu khoi TH cung luc, se lam lot ca hop khoi khac (da xay ra khi test: RunID khoi 02
          -- lai dinh kem ca hop khoi 01/03/04/05 cua GV chuyen day lien khoi).
          OR (e.LoaiNhom = 'KhoiTH' AND e.MaNhom = @KhoiRun)
          -- Nhom To/KhoiTruong bat qua nhieu khoi theo thiet ke — chi can GV co day it nhat 1 lop
          -- thuoc khoi cua RunID nay la coi nhu lien quan.
          OR (e.LoaiNhom <> 'KhoiTH' AND EXISTS (
              SELECT 1 FROM tblTKB_PhanCongGiangDay pc
              INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
              WHERE pc.MaGV = e.MaGV AND pc.Enable = 1 AND l.Khoi = @KhoiRun
          ))
      )
      AND NOT EXISTS (
          SELECT 1 FROM tblTKB_KetQuaXep k
          WHERE k.RunID = @RunID AND k.Thu = e.Thu AND k.Buoi = e.Buoi AND k.Tiet = e.Tiet AND k.MaGV = e.MaGV
      );

    SET @SoLuongChen = @@ROWCOUNT;
    SELECT CAST(1 AS BIT) AS Success, @SoLuongChen AS SoLuongChen, N'Đã áp dụng lịch họp vào phiên' AS Message;
END