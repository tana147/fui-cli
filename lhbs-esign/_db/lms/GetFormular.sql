CREATE FUNCTION [dbo].[GetFormular] ( @formular NVARCHAR(MAX), @studentId varchar(50), @lopid int, @monhoclopid int) 
RETURNS NVARCHAR(MAX)
AS
begin 
	 DECLARE @ResultString NVARCHAR(MAX) = @formular 
	 DECLARE @Result FLOAT
	-- Tách chuỗi và thay thế các giá trị 
	SELECT @ResultString = replace(@ResultString,MaCotDiem,cast(KetQuaDanhGia_VI as nvarchar))
	FROM  (
					select cast(KetQuaDanhGia_VI as float) KetQuaDanhGia_VI, MaCotDiem
						from [tblKetQuaHocTap] a inner join [TemplateBangDiemChiTiet] b on a.CotDiemID = b.CotDiemID /*and b.LoaiCotDiem=N'Nhập'*/ and GiaTriCotDiem='number'
						where a.HocSinhID= @studentId
						   and a.lopid = @lopid
						   and a.monhoclopid = @monhoclopid
						   and charindex(MaCotDiem,@formular) >0
			) kq  

	RETURN @ResultString
	--exec dbo.CallFormulaString @ResultString,@Result OUTPUT
	--return @ResultString +'='+ cast(@Result as nvarchar);
	 
end