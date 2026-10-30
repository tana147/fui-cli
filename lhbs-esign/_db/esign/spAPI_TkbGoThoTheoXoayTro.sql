CREATE PROCEDURE spAPI_TkbGoThoTheoXoayTro
    @RunID INT,
    @TopN INT = 20,
    @NguongXoayTroToiThieu INT = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-12 (theo de xuat nguoi dung — "tỉ lệ xoay trở"): go bot cac tiet DA KHOA co XoayTro CAO
    -- (linh hoat nhat, it thiet hai nhat neu phai xep lai) de nhuong cho cho CP-SAT thu giai lai, thay
    -- vi go dai tra hoac doan mo. Lam 2 lop dung nhu da thong nhat:
    --   Lop 1 (re): loc so bo bang cot XoayTro da luu san (snapshot luc khoa — Round1=0 tuyet doi
    --                khong dong, Round2=diem khan hiem GV luc khoa, Round4=90 co dinh).
    --   Lop 2 (dat, chinh xac): voi dung so ung vien da loc duoc, tinh LAI that so cho trong hien tai
    --                cho GV/Lop do — chi go that neu con it nhat 1 cho khac de xep lai, tranh go xong
    --                khong co duong lui (XoayTro cu co the da lech xa thuc te).
    -- Luon LOAI TUYET DOI XoayTro=0 (Round 1) khoi moi buoc — khong bao gio go.
    -- Tu dong MO RONG theo cap/cum (R23 CumTach, R24 CapMonDongBo) de tranh dung lai loi da tim thay
    -- truoc do (go 1 ben, ben kia mat dong bo).

    DECLARE @UngVien TABLE (ID INT PRIMARY KEY, MaLop VARCHAR(10), MaMon VARCHAR(15), MaGV VARCHAR(9),
                            Thu INT, Buoi VARCHAR(10), Tiet INT, XoayTroCu TINYINT, LyDoGop NVARCHAR(50));

    -- Lop 1: loc so bo tu cot da luu san — chi xet cac dong DA KHOA (con dang "on dinh"), loai Round1.
    INSERT INTO @UngVien (ID, MaLop, MaMon, MaGV, Thu, Buoi, Tiet, XoayTroCu, LyDoGop)
    SELECT TOP (@TopN) k.ID, k.MaLop, k.MaMon, k.MaGV, k.Thu, k.Buoi, k.Tiet, k.XoayTro, N'Uu tien ban dau'
    FROM tblTKB_KetQuaXep k
    INNER JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
    WHERE k.RunID = @RunID
      AND k.XoayTro > 0
      AND (@NguongXoayTroToiThieu IS NULL OR k.XoayTro >= @NguongXoayTroToiThieu)
      AND k.MaMon NOT IN ('SH', 'HDTN1') -- khong bao gio go 2 mon nay du XoayTro the nao (kien truc rieng, khong qua NhuCau binh thuong)
    ORDER BY k.XoayTro DESC;

    -- Mo rong theo R23 (CumTach): neu ung vien la NhomCon hoac LopNguon cua 1 cum, gop them MOI dong
    -- khac (LopNguon hoac NhomCon con lai) dang khoa CUNG dung slot (Thu,Buoi,Tiet) — vi R23 dong bo
    -- theo TUNG SLOT, khong phai theo mon, nen phai gop theo dung slot trung nhau.
    INSERT INTO @UngVien (ID, MaLop, MaMon, MaGV, Thu, Buoi, Tiet, XoayTroCu, LyDoGop)
    SELECT DISTINCT k2.ID, k2.MaLop, k2.MaMon, k2.MaGV, k2.Thu, k2.Buoi, k2.Tiet, k2.XoayTro, N'Cum tach (R23) dong bo cung slot'
    FROM @UngVien uv
    INNER JOIN tblTKB_CumTach_NhomCon nc ON nc.MaLop = uv.MaLop
    INNER JOIN tblTKB_CumTach ct ON ct.ID = nc.CumTachID AND ct.Enable = 1
    CROSS APPLY (
        SELECT MaLop FROM tblTKB_CumTach_NhomCon WHERE CumTachID = ct.ID
        UNION ALL
        SELECT MaLop FROM tblTKB_CumTach_LopNguon WHERE CumTachID = ct.ID
    ) cungCum
    INNER JOIN tblTKB_KetQuaXep k2 ON k2.RunID = @RunID AND k2.MaLop = cungCum.MaLop
        AND k2.Thu = uv.Thu AND k2.Buoi = uv.Buoi AND k2.Tiet = uv.Tiet
    WHERE k2.XoayTro > 0 AND NOT EXISTS (SELECT 1 FROM @UngVien x WHERE x.ID = k2.ID);

    INSERT INTO @UngVien (ID, MaLop, MaMon, MaGV, Thu, Buoi, Tiet, XoayTroCu, LyDoGop)
    SELECT DISTINCT k2.ID, k2.MaLop, k2.MaMon, k2.MaGV, k2.Thu, k2.Buoi, k2.Tiet, k2.XoayTro, N'Cum tach (R23) dong bo cung slot'
    FROM @UngVien uv
    INNER JOIN tblTKB_CumTach_LopNguon ln ON ln.MaLop = uv.MaLop
    INNER JOIN tblTKB_CumTach ct ON ct.ID = ln.CumTachID AND ct.Enable = 1
    CROSS APPLY (
        SELECT MaLop FROM tblTKB_CumTach_NhomCon WHERE CumTachID = ct.ID
        UNION ALL
        SELECT MaLop FROM tblTKB_CumTach_LopNguon WHERE CumTachID = ct.ID
    ) cungCum
    INNER JOIN tblTKB_KetQuaXep k2 ON k2.RunID = @RunID AND k2.MaLop = cungCum.MaLop
        AND k2.Thu = uv.Thu AND k2.Buoi = uv.Buoi AND k2.Tiet = uv.Tiet
    WHERE k2.XoayTro > 0 AND NOT EXISTS (SELECT 1 FROM @UngVien x WHERE x.ID = k2.ID);

    -- Mo rong theo R24 (CapMonDongBoGio): neu ung vien la 1 ben cua cap dong bo, gop toan bo cac dong
    -- cua BEN KIA (cung MaLop/MaMon ben con lai) trong RunID nay — vi 2 ben phai luon trung slot nhau,
    -- go 1 ben ma khong go ben kia se lam mat dong bo (dung loi da tim thay khi sua lech tiet).
    INSERT INTO @UngVien (ID, MaLop, MaMon, MaGV, Thu, Buoi, Tiet, XoayTroCu, LyDoGop)
    SELECT DISTINCT k2.ID, k2.MaLop, k2.MaMon, k2.MaGV, k2.Thu, k2.Buoi, k2.Tiet, k2.XoayTro, N'Cap dong bo (R24) — ben con lai'
    FROM @UngVien uv
    INNER JOIN tblTKB_CapMonDongBoGio c ON c.Enable = 1
        AND ((c.MaLopA = uv.MaLop AND c.MaMonA = uv.MaMon) OR (c.MaLopB = uv.MaLop AND c.MaMonB = uv.MaMon))
    INNER JOIN tblTKB_KetQuaXep k2 ON k2.RunID = @RunID
        AND (
            (c.MaLopA = uv.MaLop AND c.MaMonA = uv.MaMon AND k2.MaLop = c.MaLopB AND k2.MaMon = c.MaMonB)
            OR (c.MaLopB = uv.MaLop AND c.MaMonB = uv.MaMon AND k2.MaLop = c.MaLopA AND k2.MaMon = c.MaMonA)
        )
    WHERE k2.XoayTro > 0 AND NOT EXISTS (SELECT 1 FROM @UngVien x WHERE x.ID = k2.ID);

    -- Lop 2: xac minh that su con cho trong khong, tinh LAI ngay tai thoi diem nay (khong dung XoayTro
    -- cu) — dem so slot con lai trong tuan ma CA GV lan Lop cua dong nay dang RANH (chua bi chiem boi
    -- bat ky don vi nao khac trong RunID). Chi giu lai ung vien co it nhat 1 cho khac — go xong ma
    -- khong con cho nao de xep lai la vo nghia, chi tao them backlog.
    DECLARE @KetQua TABLE (ID INT, MaLop VARCHAR(10), MaMon VARCHAR(15), MaGV VARCHAR(9),
                           Thu INT, Buoi VARCHAR(10), Tiet INT, XoayTroCu TINYINT,
                           SoSlotTrongThat INT, DaGo BIT, LyDoGop NVARCHAR(50));

    INSERT INTO @KetQua (ID, MaLop, MaMon, MaGV, Thu, Buoi, Tiet, XoayTroCu, SoSlotTrongThat, DaGo, LyDoGop)
    SELECT uv.ID, uv.MaLop, uv.MaMon, uv.MaGV, uv.Thu, uv.Buoi, uv.Tiet, uv.XoayTroCu,
        (
            SELECT COUNT(*) FROM (
                SELECT d.Thu, b.Buoi, t.Tiet
                FROM (VALUES(2),(3),(4),(5),(6)) d(Thu)
                CROSS JOIN (VALUES(N'Sang'),(N'Chieu')) b(Buoi)
                CROSS JOIN (VALUES(1),(2),(3),(4),(5)) t(Tiet)
            ) slot
            WHERE NOT (slot.Thu = uv.Thu AND slot.Buoi = uv.Buoi AND slot.Tiet = uv.Tiet) -- khac vi tri hien tai
              AND NOT EXISTS ( -- GV ranh
                  SELECT 1 FROM tblTKB_KetQuaXep k3
                  WHERE k3.RunID = @RunID AND k3.MaGV = uv.MaGV AND k3.Thu = slot.Thu AND k3.Buoi = slot.Buoi AND k3.Tiet = slot.Tiet
              )
              AND NOT EXISTS ( -- Lop ranh
                  SELECT 1 FROM tblTKB_KetQuaXep k4
                  WHERE k4.RunID = @RunID AND k4.MaLop = uv.MaLop AND k4.Thu = slot.Thu AND k4.Buoi = slot.Buoi AND k4.Tiet = slot.Tiet
              )
        ) AS SoSlotTrongThat,
        0, uv.LyDoGop
    FROM @UngVien uv;

    UPDATE @KetQua SET DaGo = 1 WHERE SoSlotTrongThat > 0;

    -- Ap dung: go that (xoa khoi Khoa va khoi KetQuaXep) cho dung nhung dong xac minh con cho —
    -- PCGD tuong ung se tu dong "lo ra" thanh NhuCau o lan goi spAPI_TkbChayAutoPhanConLai tiep theo.
    DELETE FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID IN (SELECT ID FROM @KetQua WHERE DaGo = 1);
    DELETE FROM tblTKB_KetQuaXep WHERE ID IN (SELECT ID FROM @KetQua WHERE DaGo = 1);

    SELECT * FROM @KetQua ORDER BY XoayTroCu DESC;
END
