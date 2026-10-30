CREATE PROCEDURE spAPI_TkbNgayNghi_ApDung
    @Tuan       INT,
    @PhamVi     VARCHAR(10),
    @MaLop      VARCHAR(15) = NULL,
    @Khoi       VARCHAR(10) = NULL,
    @SlotsJson  NVARCHAR(MAX),
    @LyDo       NVARCHAR(200) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-04: doi tu @RunID sang @Tuan (xem XacDinhAnhHuong cung ten). SP nay CHI ghi du lieu —
    -- KHONG tu goi solver (goi 1 RunID/1 lan HTTP dong bo, khong the set-based nhieu RunID cung luc).
    -- Tra ve danh sach RunID THAT SU bi anh huong de FE xep hang doi, tu goi
    -- spAPI_TkbChayAutoPhanConLai tuan tu tung RunID.

    DECLARE @RunIDs TABLE (RunID INT PRIMARY KEY, Khoi VARCHAR(50));
    INSERT INTO @RunIDs (RunID, Khoi)
    SELECT MAX(c.RunID), c.Khoi
    FROM tblTKB_ChayAutoLog c
    WHERE c.TuanHienTai = @Tuan AND c.KhaThi = 1 AND c.Enable = 1
      AND (
        (@PhamVi = 'LOP' AND c.Khoi = (SELECT Khoi FROM tblTKB_Lop WHERE MaLop = @MaLop AND Enable = 1))
        OR (@PhamVi = 'KHOI' AND c.Khoi = @Khoi)
        OR (@PhamVi = 'TRUONG')
      )
    GROUP BY c.Khoi;

    DECLARE @Slots TABLE (Thu INT, Buoi VARCHAR(10), Tiet INT);
    INSERT INTO @Slots (Thu, Buoi, Tiet)
    SELECT Thu, Buoi, Tiet FROM OPENJSON(@SlotsJson) WITH (Thu INT '$.Thu', Buoi VARCHAR(10) '$.Buoi', Tiet INT '$.Tiet');

    -- Ghi ben vao tblTKB_NgayNghi cho TUNG RunID DA TON TAI (da resolve xong tu Tuan+PhamVi) — de
    -- spAPI_TkbChayAuto doc lai dung RunID do o moi lan chay tiep theo. Van luu PhamVi/MaLop/Khoi
    -- goc de audit/hien thi lai.
    INSERT INTO tblTKB_NgayNghi (RunID, PhamVi, MaLop, Khoi, Thu, Buoi, Tiet, LyDo, CreateUser, CreateTime)
    SELECT r.RunID, @PhamVi, @MaLop, @Khoi, s.Thu, s.Buoi, s.Tiet, @LyDo, @sys_UserID, GETDATE()
    FROM @RunIDs r CROSS JOIN @Slots s
    WHERE NOT EXISTS (
        SELECT 1 FROM tblTKB_NgayNghi n
        WHERE n.RunID = r.RunID AND n.Thu = s.Thu AND n.Buoi = s.Buoi AND n.Tiet = s.Tiet
    );

    -- 2026-09-04 (fix bug thuc te: khai bao ngay nghi cho 1 tuan CHUA tung chay Auto lan nao thi bi
    -- mat trang vi @RunIDs rong) — LUON ghi vao bang theo TUAN (khong phu thuoc RunID nao co san hay
    -- chua). spAPI_TkbChayAuto se tu doc bang nay theo @TuanHienTai o MOI lan chay (ke ca lan DAU
    -- TIEN) cua tuan nay.
    INSERT INTO tblTKB_NgayNghi_Tuan (Tuan, PhamVi, MaLop, Khoi, Thu, Buoi, Tiet, LyDo, CreateUser, CreateTime)
    SELECT @Tuan, @PhamVi, @MaLop, @Khoi, s.Thu, s.Buoi, s.Tiet, @LyDo, @sys_UserID, GETDATE()
    FROM @Slots s
    WHERE NOT EXISTS (
        SELECT 1 FROM tblTKB_NgayNghi_Tuan n
        WHERE n.Tuan = @Tuan AND n.PhamVi = @PhamVi
          AND ISNULL(n.MaLop, '') = ISNULL(@MaLop, '') AND ISNULL(n.Khoi, '') = ISNULL(@Khoi, '')
          AND n.Thu = s.Thu AND n.Buoi = s.Buoi AND n.Tiet = s.Tiet
    );

    DECLARE @AnhHuong TABLE (RunID INT, KetQuaXepID INT);
    INSERT INTO @AnhHuong (RunID, KetQuaXepID)
    SELECT k.RunID, k.ID
    FROM tblTKB_KetQuaXep k
    JOIN @RunIDs r ON r.RunID = k.RunID
    JOIN tblTKB_Lop l ON l.MaLop = k.MaLop AND l.Enable = 1
    JOIN @Slots s ON s.Thu = k.Thu AND s.Buoi = k.Buoi AND s.Tiet = k.Tiet
    WHERE (
        (@PhamVi = 'LOP' AND l.MaLop = @MaLop)
        OR (@PhamVi = 'KHOI' AND l.Khoi = @Khoi)
        OR (@PhamVi = 'TRUONG')
      );

    -- Ngay nghi GHI DE ca khoa tay — Lop that su nghi thi khong the giu nguyen slot cu.
    DELETE FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID IN (SELECT KetQuaXepID FROM @AnhHuong);
    DELETE FROM tblTKB_KetQuaXep WHERE ID IN (SELECT KetQuaXepID FROM @AnhHuong);

    SELECT r.RunID, r.Khoi FROM @RunIDs r WHERE r.RunID IN (SELECT DISTINCT RunID FROM @AnhHuong) ORDER BY r.Khoi;
END
