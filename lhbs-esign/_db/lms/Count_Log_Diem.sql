CREATE FUNCTION [dbo].[Count_Log_Diem]
(
    @LopID         VARCHAR(10)
  , @MonHocLopID   INT
  , @MaNhomCotDiem VARCHAR(100)
  , @HocSinhID     INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT = 0;
	DECLARE @Count_KQHT INT = 0;
	DECLARE @Count_Log INT = 0;
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();
 
    select @Count_KQHT  = COUNT(*) from tblKetQuaHocTap kqht 
		inner join TemplateBangDiemChiTiet as tbdct on tbdct.CotDiemID = kqht.CotDiemID and tbdct.Enable = 1 and MaNhomCotDiem LIKE '%'+ @MaNhomCotDiem
	where LopID         = @LopID        
		 AND MonHocLopID   = @MonHocLopID  
		 AND MaNhomCotDiem = @MaNhomCotDiem
 		 AND HocSinhID     = @HocSinhID   
		 
	select @Count_Log  = COUNT(*) from tbl_LOG_KetQuaHocTap kqht 
		inner join TemplateBangDiemChiTiet as tbdct on tbdct.CotDiemID = kqht.CotDiemID and tbdct.Enable = 1 and MaNhomCotDiem LIKE '%'+ @MaNhomCotDiem
	where LopID         = @LopID        
		 AND MonHocLopID   = @MonHocLopID  
		 AND MaNhomCotDiem = @MaNhomCotDiem
 		 AND HocSinhID     = @HocSinhID   

	set @Count = @Count_KQHT +  @Count_Log
    RETURN @Count;
END;
