CREATE PROCEDURE spAPI_TkbNgayNghi_XacDinhAnhHuong
    @Tuan       INT,
    @PhamVi     VARCHAR(10),
    @MaLop      VARCHAR(15) = NULL,
    @Khoi       VARCHAR(10) = NULL,
    @SlotsJson  NVARCHAR(MAX),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-04: doi tu @RunID sang @Tuan — pham vi Khoi/Truong tu nhien co the trai nhieu RunID
    -- (moi khoi 1 RunID rieng cho cung 1 tuan). Lay RunID KHA THI GAN NHAT cua MOI khoi cho dung tuan.
    ;WITH RunHienHanh AS (
        SELECT Khoi, MAX(RunID) AS RunID
        FROM tblTKB_ChayAutoLog
        WHERE TuanHienTai = @Tuan AND KhaThi = 1 AND Enable = 1
        GROUP BY Khoi
    )
    SELECT k.ID, k.RunID, r.Khoi, k.MaLop, k.MaMon, m.TenMon, k.MaGV, gv.HoTen AS TenGV, k.Thu, k.Buoi, k.Tiet
    FROM RunHienHanh r
    JOIN tblTKB_Lop l ON l.Khoi = r.Khoi AND l.Enable = 1
    JOIN tblTKB_KetQuaXep k ON k.RunID = r.RunID AND k.MaLop = l.MaLop
    JOIN OPENJSON(@SlotsJson) WITH (Thu INT '$.Thu', Buoi VARCHAR(10) '$.Buoi', Tiet INT '$.Tiet') s
      ON s.Thu = k.Thu AND s.Buoi = k.Buoi AND s.Tiet = k.Tiet
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = k.MaMon
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = k.MaGV
    WHERE (
        (@PhamVi = 'LOP' AND l.MaLop = @MaLop)
        OR (@PhamVi = 'KHOI' AND l.Khoi = @Khoi)
        OR (@PhamVi = 'TRUONG')
      )
    ORDER BY k.Thu, k.Buoi, k.Tiet, k.MaLop;
END
