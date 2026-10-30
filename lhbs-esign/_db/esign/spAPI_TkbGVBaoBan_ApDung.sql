CREATE PROCEDURE spAPI_TkbGVBaoBan_ApDung
    @Tuan       INT,
    @MaGV       VARCHAR(MAX),
    @SlotsJson  NVARCHAR(MAX),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-04: doi tu @RunID sang @Tuan (xem XacDinhAnhHuong cung ten) — ap dung tren TAT CA RunID
    -- kha thi gan nhat cua MOI khoi cho dung tuan nay (1 GV co the day nhieu khoi). SP nay CHI ghi du
    -- lieu (xoa khoa, xoa tiet, cam GVCamTuyetDoi) — KHONG tu goi solver nua (goi 1 RunID/1 lan HTTP
    -- dong bo, khong the set-based cho nhieu RunID cung luc). Tra ve danh sach RunID THAT SU bi anh
    -- huong (co tiet bi xoa) de FE tu xep hang doi, goi spAPI_TkbChayAutoPhanConLai tuan tu tung RunID
    -- (SP do giu nguyen, khong doi).
    -- @MaGV nhan danh sach CACH NHAU BOI DAU PHAY (2026-09-04, ho tro bao ban NHIEU GV cung luc trong
    -- 1 cau chatbot) — van tuong thich nguoc voi UI Sua tay chi truyen 1 ma GV don.

    DECLARE @GVList TABLE (MaGV VARCHAR(15) PRIMARY KEY);
    INSERT INTO @GVList (MaGV)
    SELECT DISTINCT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@MaGV, ',') WHERE LTRIM(RTRIM(value)) <> '';

    DECLARE @RunIDs TABLE (RunID INT PRIMARY KEY, Khoi VARCHAR(50));
    INSERT INTO @RunIDs (RunID, Khoi)
    SELECT MAX(RunID), Khoi
    FROM tblTKB_ChayAutoLog
    WHERE TuanHienTai = @Tuan AND KhaThi = 1 AND Enable = 1
    GROUP BY Khoi;

    DECLARE @Slots TABLE (Thu INT, Buoi VARCHAR(10), Tiet INT);
    INSERT INTO @Slots (Thu, Buoi, Tiet)
    SELECT Thu, Buoi, Tiet FROM OPENJSON(@SlotsJson) WITH (Thu INT '$.Thu', Buoi VARCHAR(10) '$.Buoi', Tiet INT '$.Tiet');

    -- Cam TUYET DOI tung GV trong danh sach cho MOI RunID DA TON TAI cua tuan nay x MOI slot da chon
    -- — KE CA slot dang trong (bao ban nghia la cam ca nhung o dang trong luon, khong chi xoa cai da co).
    INSERT INTO tblTKB_GVCamTuyetDoi (RunID, MaGV, Thu, Buoi, Tiet, LyDo, CreateUser, CreateTime)
    SELECT r.RunID, gv.MaGV, s.Thu, s.Buoi, s.Tiet, N'GV báo bận', @sys_UserID, GETDATE()
    FROM @RunIDs r CROSS JOIN @GVList gv CROSS JOIN @Slots s
    WHERE NOT EXISTS (
        SELECT 1 FROM tblTKB_GVCamTuyetDoi g
        WHERE g.RunID = r.RunID AND g.MaGV = gv.MaGV AND g.Thu = s.Thu AND g.Buoi = s.Buoi AND g.Tiet = s.Tiet
    );

    -- 2026-09-04 (fix bug thuc te: bao ban 1 tuan CHUA tung chay Auto lan nao thi bi mat trang vi
    -- @RunIDs rong) — LUON ghi vao bang theo TUAN (khong phu thuoc RunID nao co san hay chua).
    -- spAPI_TkbChayAuto se tu doc bang nay theo @TuanHienTai o MOI lan chay (ke ca lan DAU TIEN) cua
    -- tuan nay, bat ke luc bao ban tuan da co lich hay chua.
    INSERT INTO tblTKB_GVCamTuyetDoi_Tuan (Tuan, MaGV, Thu, Buoi, Tiet, LyDo, CreateUser, CreateTime)
    SELECT @Tuan, gv.MaGV, s.Thu, s.Buoi, s.Tiet, N'GV báo bận', @sys_UserID, GETDATE()
    FROM @GVList gv CROSS JOIN @Slots s
    WHERE NOT EXISTS (
        SELECT 1 FROM tblTKB_GVCamTuyetDoi_Tuan g
        WHERE g.Tuan = @Tuan AND g.MaGV = gv.MaGV AND g.Thu = s.Thu AND g.Buoi = s.Buoi AND g.Tiet = s.Tiet
    );

    DECLARE @AnhHuong TABLE (RunID INT, KetQuaXepID INT);
    INSERT INTO @AnhHuong (RunID, KetQuaXepID)
    SELECT k.RunID, k.ID
    FROM tblTKB_KetQuaXep k
    JOIN @RunIDs r ON r.RunID = k.RunID
    JOIN @GVList gv ON gv.MaGV = k.MaGV
    JOIN @Slots s ON s.Thu = k.Thu AND s.Buoi = k.Buoi AND s.Tiet = k.Tiet;

    -- GV bao ban GHI DE ca khoa tay — GV that su khong day duoc thi khong the giu nguyen slot cu.
    DELETE FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID IN (SELECT KetQuaXepID FROM @AnhHuong);
    DELETE FROM tblTKB_KetQuaXep WHERE ID IN (SELECT KetQuaXepID FROM @AnhHuong);

    SELECT r.RunID, r.Khoi FROM @RunIDs r WHERE r.RunID IN (SELECT DISTINCT RunID FROM @AnhHuong) ORDER BY r.Khoi;
END
