CREATE PROCEDURE spAPI_TkbCumTachMarkerSync
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-11: tu dong hoa quy tac "marker cum tach nhom" (truoc gio Claude lam tay bang SQL rieng
    -- moi lan, chi ghi lai trong memory, chua he co trong DB/code). Marker la 1 dong tblTKB_KetQuaXep
    -- tren LopNguon voi MaMon = MaCumTach (vd '11B-CD') de UI hien thi "dang tach nhom chuyen de" —
    -- ban than CP-SAT (R23 trong TkbCpSatSolver.cs) chi can LopNguon "ban" trong constraint noi bo,
    -- KHONG tu sinh dong nay cho UI, nen phai chay SP nay sau moi lan sua tay/giai lai de dong bo lai.
    --
    -- Quy tac: 1 slot (LopNguon, Thu, Buoi, Tiet) CAN co marker khi va chi khi CO IT NHAT 1 NhomCon
    -- dang hoat dong that (co dong KetQuaXep) tai dung slot do, VA LopNguon CHUA co dong nao khac o do.
    -- Neu LopNguon da co san 1 mon that (VD ben it tiet hon cua 1 cap R24 da "tan hoc, ve hoc lop me")
    -- thi KHONG chen marker de tranh de len mon that — day chinh la truong hop "tach mot phan" da ghi
    -- trong memory tkb-solver-cumtach-thpt.md.

    ;WITH HoatDongThat AS (
        SELECT DISTINCT ln.MaLop AS LopNguon, ct.MaCumTach, k.Thu, k.Buoi, k.Tiet
        FROM tblTKB_CumTach ct
        INNER JOIN tblTKB_CumTach_LopNguon ln ON ln.CumTachID = ct.ID
        INNER JOIN tblTKB_CumTach_NhomCon nc ON nc.CumTachID = ct.ID
        INNER JOIN tblTKB_KetQuaXep k ON k.MaLop = nc.MaLop AND k.RunID = @RunID
        WHERE ct.Enable = 1
          AND k.MaMon NOT IN (SELECT MaCumTach FROM tblTKB_CumTach WHERE Enable = 1)
    )
    SELECT LopNguon, MaCumTach, Thu, Buoi, Tiet
    INTO #HoatDongThat
    FROM HoatDongThat;

    SELECT k.ID, k.MaLop AS LopNguon, k.MaMon AS MaCumTach, k.Thu, k.Buoi, k.Tiet
    INTO #MarkerHienTai
    FROM tblTKB_KetQuaXep k
    INNER JOIN tblTKB_CumTach ct ON ct.MaCumTach = k.MaMon AND ct.Enable = 1
    WHERE k.RunID = @RunID;

    DECLARE @XoaIDs TABLE (ID INT PRIMARY KEY);
    INSERT INTO @XoaIDs (ID)
    SELECT mh.ID FROM #MarkerHienTai mh
    WHERE NOT EXISTS (
        SELECT 1 FROM #HoatDongThat hd
        WHERE hd.LopNguon = mh.LopNguon AND hd.MaCumTach = mh.MaCumTach
          AND hd.Thu = mh.Thu AND hd.Buoi = mh.Buoi AND hd.Tiet = mh.Tiet
    );

    -- 1) Don marker rac (khong con NhomCon nao hoat dong that o slot do nua)
    DELETE FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID IN (SELECT ID FROM @XoaIDs);
    DELETE FROM tblTKB_KetQuaXep WHERE ID IN (SELECT ID FROM @XoaIDs);

    DECLARE @SoDaChen INT;
    -- 2) Chen marker con thieu (bo qua slot LopNguon da co mon that - truong hop "tach mot phan")
    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
    SELECT @RunID, hd.LopNguon, hd.Thu, hd.Buoi, hd.Tiet, hd.MaCumTach, hd.MaCumTach, NULL
    FROM #HoatDongThat hd
    WHERE NOT EXISTS (
        SELECT 1 FROM tblTKB_KetQuaXep k2
        WHERE k2.RunID = @RunID AND k2.MaLop = hd.LopNguon
          AND k2.Thu = hd.Thu AND k2.Buoi = hd.Buoi AND k2.Tiet = hd.Tiet
    );
    SET @SoDaChen = @@ROWCOUNT;

    -- 3) Khoa lai toan bo marker cua cac cum dang co trong RunID nay (dong bo trang thai khoa)
    INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
    SELECT k.ID FROM tblTKB_KetQuaXep k
    INNER JOIN tblTKB_CumTach ct ON ct.MaCumTach = k.MaMon AND ct.Enable = 1
    WHERE k.RunID = @RunID
      AND NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep_Khoa kh WHERE kh.KetQuaXepID = k.ID);

    SELECT (SELECT COUNT(*) FROM @XoaIDs) AS SoMarkerDaXoa,
           @SoDaChen AS SoMarkerDaChen;

    DROP TABLE #HoatDongThat;
    DROP TABLE #MarkerHienTai;
END
