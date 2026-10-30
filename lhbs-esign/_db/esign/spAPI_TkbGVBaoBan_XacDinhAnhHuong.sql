CREATE PROCEDURE spAPI_TkbGVBaoBan_XacDinhAnhHuong
    @Tuan       INT,
    @MaGV       VARCHAR(MAX),
    @SlotsJson  NVARCHAR(MAX),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-04: doi tu @RunID sang @Tuan — TKB phai doi chieu theo TUAN (khai niem nghiep vu), RunID
    -- chi la ID ky thuat cua 1 lan chay/1 khoi. 1 GV co the day nhieu khoi (moi khoi co RunID rieng
    -- cho CUNG 1 tuan) — bao ban theo dung 1 RunID se bo sot cac khoi khac. Lay RunID KHA THI GAN NHAT
    -- cua MOI khoi cho dung tuan nay (giong logic da fix o spAPI_TkbKetQuaXepChecklistGV).
    -- @MaGV nhan danh sach CACH NHAU BOI DAU PHAY (2026-09-04, ho tro bao ban NHIEU GV cung luc trong
    -- 1 cau chatbot) — van tuong thich nguoc voi UI Sua tay chi truyen 1 ma GV don (STRING_SPLIT tren
    -- 1 gia tri van tra ve dung 1 dong).
    ;WITH RunHienHanh AS (
        SELECT Khoi, MAX(RunID) AS RunID
        FROM tblTKB_ChayAutoLog
        WHERE TuanHienTai = @Tuan AND KhaThi = 1 AND Enable = 1
        GROUP BY Khoi
    )
    SELECT k.ID, k.RunID, r.Khoi, k.MaLop, k.MaMon, m.TenMon, k.MaGV, gv.HoTen AS TenGV, k.Thu, k.Buoi, k.Tiet
    FROM RunHienHanh r
    JOIN tblTKB_KetQuaXep k ON k.RunID = r.RunID
    JOIN STRING_SPLIT(@MaGV, ',') gvs ON LTRIM(RTRIM(gvs.value)) = k.MaGV
    JOIN OPENJSON(@SlotsJson) WITH (Thu INT '$.Thu', Buoi VARCHAR(10) '$.Buoi', Tiet INT '$.Tiet') s
      ON s.Thu = k.Thu AND s.Buoi = k.Buoi AND s.Tiet = k.Tiet
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = k.MaMon
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = k.MaGV
    ORDER BY k.Thu, k.Buoi, k.Tiet, r.Khoi;
END
