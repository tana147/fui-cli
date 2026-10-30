CREATE PROC spAPI_AUTH_NhanXet_GVCN_GetBy_NienKhoa_LopID
 @NienKhoa int,
 @LopID INT
as
begin
	select 
		nxt.HocSinhID,
		Ho + ' ' + Ten as HoTen,
		NhanXetGVCN
	from tblNhanXetThang nxt
		inner join tblNhanXetThang_Lop nxt_l on nxt_l.Lop_NhanXetThangID = nxt.Lop_NhanXetThangID and nxt_l.NienKhoa = @NienKhoa and nxt_l.Enable = 1
		inner join tblHocSinh hs on hs.HocSinhID = nxt.HocSinhID 
	where nxt.Enable = 1
	and nxt_l.Thang = 5 
	and Is_HienThiPhuHuynh = 1
	and LopID = @LopID
end




