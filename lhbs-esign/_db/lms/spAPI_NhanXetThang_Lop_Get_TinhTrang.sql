CREATE PROCEDURE spAPI_NhanXetThang_Lop_Get_TinhTrang
	@NienKhoa int,
	@Thang int,
	@CapID int
as
begin
select l.TenLop,
	l.KhoiID,
	l.LopID,
	  dbo.RenderNhanXet_ColorTinhTrang(nxtl.TinhTrang)   AS MauTinhTrang
      , dbo.RenderNhanXet_TinhTrang(nxtl.TinhTrang)      AS TenTinhTrang
	From tblLop l 
		left join tblNhanXetThang_Lop nxtl on nxtl.LopID = l.LopID 
											and nxtl.Thang = @Thang and nxtl.NienKhoa = @NienKhoa 
											and nxtl.Enable = 1 
where l.CapID = @CapID 
	and  l.NienKhoa = @NienKhoa 
	and  l.Enable = 1  
order by l.TenLop
end