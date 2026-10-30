CREATE PROCEDURE spAPI_TkbDoiGVCuThe_XacDinhAnhHuong
    @Tuan       INT,
    @MaGVCu     VARCHAR(15),
    @MaGVMoi    VARCHAR(15),
    @SlotsJson  NVARCHAR(MAX),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-04: doi tu @RunID sang @Tuan — GV cu co the day nhieu khoi (moi khoi 1 RunID rieng cho
    -- cung 1 tuan). Voi moi slot cua GV cu (trong dung RunID cua khoi do), kiem tra GV moi co RANH
    -- KHONG trong CHINH RunID do (conflict phai so trong cung 1 RunID, khac khoi thi khong lien quan).
    ;WITH RunHienHanh AS (
        SELECT Khoi, MAX(RunID) AS RunID
        FROM tblTKB_ChayAutoLog
        WHERE TuanHienTai = @Tuan AND KhaThi = 1 AND Enable = 1
        GROUP BY Khoi
    )
    SELECT k.ID, k.RunID, r.Khoi, k.MaLop, k.MaMon, m.TenMon, k.Thu, k.Buoi, k.Tiet,
        CASE WHEN conflict.ID IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS GVMoiDangBan,
        conflict.MaLop AS GVMoiDangDayLop,
        cm.TenMon AS GVMoiDangDayMon,
        CASE WHEN conflict.ID IS NOT NULL
             THEN N'Bận (' + conflict.MaLop + N' - ' + ISNULL(cm.TenMon, conflict.MaMon) + N')'
             ELSE N'Rảnh — đổi được'
        END AS TrangThaiGVMoi
    FROM RunHienHanh r
    JOIN tblTKB_KetQuaXep k ON k.RunID = r.RunID AND k.MaGV = @MaGVCu
    JOIN OPENJSON(@SlotsJson) WITH (Thu INT '$.Thu', Buoi VARCHAR(10) '$.Buoi', Tiet INT '$.Tiet') s
      ON s.Thu = k.Thu AND s.Buoi = k.Buoi AND s.Tiet = k.Tiet
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = k.MaMon
    OUTER APPLY (
        SELECT TOP 1 c.ID, c.MaLop, c.MaMon
        FROM tblTKB_KetQuaXep c
        WHERE c.RunID = k.RunID AND c.MaGV = @MaGVMoi AND c.Thu = k.Thu AND c.Buoi = k.Buoi AND c.Tiet = k.Tiet
    ) conflict
    LEFT JOIN tblTKB_MonHoc cm ON cm.MaMon = conflict.MaMon
    ORDER BY k.Thu, k.Buoi, k.Tiet;
END
