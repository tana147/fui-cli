CREATE PROCEDURE spAPI_TkbXuatStk5
    @RunID INT,
    @Loai VARCHAR(10),          -- 'xls' (file Excel 26 sheet mau STK5) | 'stkb' (file du an import vao phan mem sTKB)
    @sys_UserID NVARCHAR(50)
AS
BEGIN
    -- 2026-10-09: Xuat TKB cua 1 lan chay ra file dung mau phan mem TKB cua truong (STK5.0 / sTKB).
    -- SP gom o TKB + lich hop cua RunID, goi dich vu TKB (TkbApi /api/export/stk5) qua dbo.httpCall, tra ve
    -- 1 dong {TenFile, Base64, CanhBao} — trang TKB giai base64 thanh file de tai ve (dbo.httpCall chi
    -- nhan/tra chuoi nen file di dang base64). Ten file theo mau file that: "<tuan>.TKBHK1_dd-mm-yyyy.<duoi>".
    SET NOCOUNT ON;
    SET @Loai = CASE WHEN LOWER(ISNULL(@Loai, '')) = 'stkb' THEN 'stkb' ELSE 'xls' END;

    DECLARE @Tuan INT = (SELECT TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID);
    IF @Tuan IS NULL
    BEGIN
        SELECT CAST('' AS NVARCHAR(200)) AS TenFile, CAST('' AS NVARCHAR(MAX)) AS Base64,
               N'Không tìm thấy lần chạy ' + CAST(@RunID AS NVARCHAR(20)) + N' hoặc lần chạy chưa gắn tuần' AS ThongBao;
        RETURN;
    END
    DECLARE @NgayBD DATE = (SELECT TOP 1 NgayBatDau FROM tblTKB_Tuan WHERE TuanTrongNam = @Tuan ORDER BY NamHoc DESC);
    DECLARE @Ngay NVARCHAR(10) = ISNULL(FORMAT(@NgayBD, 'dd/MM/yyyy'), FORMAT(GETDATE(), 'dd/MM/yyyy'));
    DECLARE @Ten NVARCHAR(200) = CAST(@Tuan AS NVARCHAR(10)) + N'.TKBHK1_' + REPLACE(@Ngay, '/', '-');

    DECLARE @Cells NVARCHAR(MAX) = (
        SELECT k.MaLop, k.Thu, k.Buoi, k.Tiet,
               -- 2026-10-16: HD giao duc bo tro tieu hoc (HDGD): file Excel giu ma HDGD (tu them vao danh muc); file .STKB (khuon
               -- chua co HDGD, chua dong vao) doi theo khoi sang mon co san.
               CASE WHEN @Loai = 'stkb' AND k.MaMon = 'HDGD' THEN CASE LEFT(k.MaLop, 2) WHEN '01' THEN 'BR' WHEN '02' THEN 'MN1' WHEN '03' THEN 'CLB' WHEN '04' THEN 'HE28' ELSE 'HE20' END
                    ELSE k.MaMon END AS MaMon,
               k.MaGV, k.MaPhong
        FROM tblTKB_KetQuaXep k
        WHERE k.RunID = @RunID AND k.MaLop <> 'HOP' AND k.MaMon NOT IN ('HOP', 'KHOAPHONG')
        FOR JSON PATH);
    DECLARE @Hop NVARCHAR(MAX) = (
        SELECT DISTINCT k.MaGV, k.Thu, k.Buoi, k.Tiet
        FROM tblTKB_KetQuaXep k
        WHERE k.RunID = @RunID AND (k.MaLop = 'HOP' OR k.MaMon = 'HOP') AND k.MaGV IS NOT NULL
        FOR JSON PATH);

    DECLARE @Body NVARCHAR(MAX) = N'{"NgayApDung":"' + @Ngay + N'","Loai":"' + @Loai + N'","TenFile":"' + @Ten
        + N'","Cells":' + ISNULL(@Cells, N'[]') + N',"Hop":' + ISNULL(@Hop, N'[]')
        -- 2026-10-16: ten mon cua he thong cho mon chua co trong danh muc khuon Excel (vd HDGD)
        + N',"MonMoi":' + ISNULL((SELECT m.MaMon, m.TenMon FROM tblTKB_MonHoc m WHERE m.MaMon IN (SELECT DISTINCT MaMon FROM tblTKB_KetQuaXep WHERE RunID = @RunID) FOR JSON PATH), N'[]') + N'}';
    DECLARE @Resp NVARCHAR(MAX) = dbo.httpCall('POST', 'http://192.168.100.249:7778/api/export/stk5', 'Content-Type: application/json', @Body);

    IF ISJSON(@Resp) = 0
    BEGIN
        SELECT CAST('' AS NVARCHAR(200)) AS TenFile, CAST('' AS NVARCHAR(MAX)) AS Base64,
               N'Dịch vụ xuất file không phản hồi: ' + LEFT(ISNULL(@Resp, N'(rỗng)'), 300) AS ThongBao;
        RETURN;
    END
    SELECT r.TenFile, r.Base64,
           CASE WHEN ISNULL(r.Base64, '') = '' THEN N'Không tạo được file' ELSE N'' END
           + ISNULL((SELECT STRING_AGG(value, N'; ') FROM OPENJSON(r.CanhBao)), N'') AS ThongBao
    FROM OPENJSON(@Resp) WITH (TenFile NVARCHAR(200) '$.tenFile', Base64 NVARCHAR(MAX) '$.base64', CanhBao NVARCHAR(MAX) '$.canhBao' AS JSON) r;
END