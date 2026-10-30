CREATE PROCEDURE [dbo].[Pro_GetMark_backup]
    @formular NVARCHAR(MAX),
    @studentId VARCHAR(50),
    @lopid INT,
    @monhoclopid INT,
	@templatebangdiemid INT,
    @Result FLOAT OUTPUT,
	@ResultFormular NVARCHAR(MAX) OUTPUT
AS
BEGIN
     DECLARE @ResultString NVARCHAR(MAX) = @formular;
	 DECLARE @SQL  NVARCHAR(MAX);
	-- Tách chuỗi và thay thế các giá trị 
	
	SELECT @ResultString = replace(@ResultString,MaCotDiem,cast(KetQuaDanhGia_VI as nvarchar(30)))
	FROM  (
					SELECT 
						b.MaCotDiem,
						ISNULL(CAST(a.KetQuaDanhGia_VI AS FLOAT) * 1.0, 0) AS KetQuaDanhGia_VI
					FROM 
						TemplateBangDiemChiTiet b
					LEFT JOIN 
						tblKetQuaHocTap a ON a.CotDiemID = b.CotDiemID
							AND a.HocSinhID = @studentId
							AND a.LopID = @lopid
							AND a.MonHocLopID = @monhoclopid
					INNER JOIN 
						TemplateBangDiem tbd ON b.TemplateBangDiemID = tbd.TemplateBangDiemID AND tbd.TemplateBangDiemID = @templatebangdiemid
					WHERE 
						b.GiaTriCotDiem = 'number'
						AND CHARINDEX(b.MaCotDiem, @formular) > 0

			) kq  

	print @ResultString
    SET @SQL = 'SELECT @Result = round(' + @ResultString+',2)';
	print @SQL
	set @ResultFormular = @SQL;
	set @Result=0;
    EXEC sp_executesql @SQL, N'@Result FLOAT OUTPUT', @Result OUTPUT
END
