CREATE PROCEDURE [dbo].[Pro_GetMark]
    @formular NVARCHAR(MAX),
	@giaTriCotDiem NVARCHAR(50),
    @studentId VARCHAR(50),
    @lopid VARCHAR(10),
    @monhoclopid INT,
	@templatebangdiemid INT,
    @Result NVARCHAR(MAX) OUTPUT,
	@ResultFormular NVARCHAR(MAX) OUTPUT
AS
BEGIN
    DECLARE @ResultString NVARCHAR(MAX) = @formular;
	DECLARE @SQL NVARCHAR(MAX);

	-- Tách chuỗi và thay thế các giá trị 
	SELECT @ResultString = REPLACE(@ResultString, MaCotDiem, CAST(KetQuaDanhGia_VI AS NVARCHAR(30)))
	FROM  (
				SELECT 
					b.MaCotDiem,
					ISNULL(CAST(a.KetQuaDanhGia_VI AS decimal(10,2)) * 1.0, 0) AS KetQuaDanhGia_VI,
					b.GiaTriCotDiem
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
					CHARINDEX(b.MaCotDiem, @formular) > 0
			) kq  

	PRINT @ResultString;

	-- Kiểm tra giá trị cột điểm và xây dựng câu SQL phù hợp
	IF @GiaTriCotDiem = 'number'
	BEGIN
		PRINT 'NUMBER'
		-- Thêm epsilon trực tiếp vào @ResultString
		SET @ResultString = @ResultString + ' + 0.00001';

		-- Sử dụng nó trong câu lệnh SQL
		SET @SQL = 'SELECT @Result = ROUND(' + @ResultString + ', 1)';
	END
	ELSE
	BEGIN
		PRINT 'TEXT'
		SET @SQL = 'SELECT @Result = ' + @ResultString;
	END

	PRINT @SQL;
	SET @ResultFormular = @SQL;
	SET @Result = 0;

	-- Thực thi câu lệnh SQL động
    EXEC sp_executesql @SQL, N'@Result NVARCHAR(MAX) OUTPUT', @Result OUTPUT;
END
