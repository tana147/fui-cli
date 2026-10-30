CREATE PROC spAPI_TienDo_NhapDiem_ChiTiet
@NienKhoa INT					
,@MonHocLopID INT				
,@LopID VARCHAR(20)				
,@MaNhomCotDiem NVARCHAR(200)	
AS
BEGIN
    
;WITH DS_HocSinh AS (
    SELECT DISTINCT hsl.HocSinhID
    FROM dbo.tblHocSinhLop hsl  
		INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID AND hs.TinhTrang = 0
    WHERE hsl.LopID = @LopID
),
DS_CotDiem AS (
	SELECT DISTINCT ct.MaCotDiem 
	FROM dbo.tblMonHocLop mhl
	INNER JOIN dbo.TemplateBangDiemChiTiet ct 
		ON ct.TemplateBangDiemID = mhl.TemplateBangDiemID 
		AND ct.MaNhomCotDiem = @MaNhomCotDiem
		AND ct.Enable = 1
	WHERE mhl.MonHocLopID = @MonHocLopID
)
SELECT 
    c.MaCotDiem AS CotDiem,
    CASE 
        WHEN NOT EXISTS (
            SELECT 1
            FROM DS_HocSinh hs_chk
            LEFT JOIN dbo.tblKetQuaHocTap k_chk 
                   ON k_chk.HocSinhID = hs_chk.HocSinhID
                  AND k_chk.MonHocLopID = @MonHocLopID
                  AND k_chk.NienKhoa = @NienKhoa
                  AND k_chk.Enable = 1
            LEFT JOIN dbo.TemplateBangDiemChiTiet ct_chk 
                   ON ct_chk.CotDiemID = k_chk.CotDiemID
                  AND ct_chk.Enable = 1
                  AND ct_chk.MaCotDiem = c.MaCotDiem
            WHERE k_chk.HocSinhID IS NOT NULL
        )
        THEN N'Chưa có dữ liệu điểm cho cột này'
        
        WHEN EXISTS (
            SELECT 1
            FROM DS_HocSinh hs_chk
            LEFT JOIN dbo.tblKetQuaHocTap k_chk 
                   ON k_chk.HocSinhID = hs_chk.HocSinhID
                  AND k_chk.MonHocLopID = @MonHocLopID
                  AND k_chk.NienKhoa = @NienKhoa
                  AND k_chk.Enable = 1
            LEFT JOIN dbo.TemplateBangDiemChiTiet ct_chk 
                   ON ct_chk.CotDiemID = k_chk.CotDiemID
                  AND ct_chk.Enable = 1
                  AND ct_chk.MaCotDiem = c.MaCotDiem
            WHERE 
                k_chk.HocSinhID IS NULL 
                OR k_chk.KetQuaDanhGia_VI IS NULL 
                OR LTRIM(RTRIM(k_chk.KetQuaDanhGia_VI)) = ''
        )
        THEN 
            N'Thiếu điểm ở học sinh: ' + 
            STUFF((
                SELECT ',' + CAST(hs2.HocSinhID AS NVARCHAR(20))
                FROM DS_HocSinh hs2
                LEFT JOIN dbo.tblKetQuaHocTap k2
                    ON k2.HocSinhID = hs2.HocSinhID
                    AND k2.MonHocLopID = @MonHocLopID
                    AND k2.NienKhoa = @NienKhoa
                    AND k2.Enable = 1
                LEFT JOIN dbo.TemplateBangDiemChiTiet ct2
                    ON ct2.CotDiemID = k2.CotDiemID
                    AND ct2.Enable = 1
                    AND ct2.MaCotDiem = c.MaCotDiem
                WHERE 
                    k2.HocSinhID IS NULL 
                    OR k2.KetQuaDanhGia_VI IS NULL 
                    OR LTRIM(RTRIM(k2.KetQuaDanhGia_VI)) = ''
                FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')
        ELSE 
            N'Tất cả học sinh đã có điểm'
    END AS TinhTrangCotDiem
FROM DS_CotDiem c
ORDER BY c.MaCotDiem;
END

