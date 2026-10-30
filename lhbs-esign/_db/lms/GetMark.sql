Create FUNCTION dbo.GetMark ( @formular NVARCHAR(MAX), @studentId varchar(50), @lopid int, @monhoclopid int) 
RETURNS float
AS
begin
	DECLARE @Delimiter CHAR(1) = ' '
	 DECLARE @ResultString NVARCHAR(MAX) = '' 
	 DECLARE @Result FLOAT
	-- Tách chuỗi và thay thế các giá trị 
	SELECT @ResultString = COALESCE(@ResultString + ' ', '') + CASE WHEN s.Item IN ('+', '-',')','(','*','/') THEN s.Item ELSE CAST(ISNULL(kq.KetQuaDanhGia_VI, s.Item) AS NVARCHAR(MAX)) END 
	FROM dbo.SplitString(@formular, ' ') s 
		LEFT JOIN (
					select KetQuaDanhGia_VI, MaCotDiem
						from [tblKetQuaHocTap] a inner join [TemplateBangDiemChiTiet] b on a.CotDiemID = b.CotDiemID /*and b.LoaiCotDiem=N'Nhập'*/ and GiaTriCotDiem='number'
						where a.HocSinhID= @studentId
						   and a.lopid = @lopid
						   and a.monhoclopid = @monhoclopid
			) kq ON kq.MaCotDiem = s.Item

	set @ResultString='select @Result='+@ResultString;

	EXEC sp_executesql @ResultString, N'@Result FLOAT OUTPUT', @Result OUTPUT 
	return @Result;
end