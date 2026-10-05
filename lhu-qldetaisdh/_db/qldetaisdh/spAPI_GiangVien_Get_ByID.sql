CREATE PROC [dbo].[spAPI_GiangVien_Get_ByID]
@GiangVienID INT
AS
BEGIN
	SELECT  [GiangVienID], [HocViHocHam], [HoTenGiangVien], [CoQuanCongTac], [NganhGiangDay], [NganhID],
		'2021' AS Khoa,
		'12/01/2023' AS NgayThucHien
	FROM GiangVien 
	WHERE Is_Xoa = 0
		AND (@GiangVienID = 0 OR GiangVienID = @GiangVienID)

	SELECT 6 AS TT,
		'22CQ911' AS LopID,
		'922000029' AS MaHV,
		N'Nguyễn Mạnh' AS Ho,
		N'Hùng' AS Ten,
		'04/10/1991' AS NgaySinh,
		'0916375858' AS DienThoai,
		'manhhungnguyen0911@gmail.com' AS Email,
		N'Giải pháp chuyển đổi số toàn diện của ngân hàng TMCP Quân Đội - Chi nhánh Đồng Nai' AS DeTaiDangKy,
		N'TS. Nguyễn Văn Tân' AS GVHD_1,
		N'' AS  GVHD_2

	UNION ALL

		SELECT 10 AS TT,
		'22CQ911' AS LopID,
		'922000048' AS MaHV,
		N'Bùi Hảo' AS Ho,
		N'Quang' AS Ten,
		'30/04/1999' AS NgaySinh,
		'0344932239' AS DienThoai,
		'HaoQuang3004@gmail.com' AS Email,
		N'Một số giải pháp hoàn thiện quản trị nguồn nhân lực của Công ty Techcom' AS DeTaiDangKy,
		N'TS. Nguyễn Văn Tân' AS GVHD_1,
		N'' AS  GVHD_2

		UNION ALL

		SELECT 14 AS TT,
		'22CQ911' AS LopID,
		'922000022' AS MaHV,
		N'Trần Ngọc' AS Ho,
		N'Vĩ' AS Ten,
		'26/01/1985' AS NgaySinh,
		'0949863940' AS DienThoai,
		'tranngocvi.dusta@gmail.com' AS Email,
		N'Giải pháp hoàn thiện nguồn nhân lực tại Công ty Biên Hòa SCM' AS DeTaiDangKy,
		N'TS. Nguyễn Văn Tân' AS GVHD_1,
		N'' AS  GVHD_2

		UNION ALL

		SELECT 1 AS TT,
		'22CQ911' AS LopID,
		'921000015' AS MaHV,
		N'Hoàng Tuấn' AS Ho,
		N'Anh' AS Ten,
		'04/09/1990' AS NgaySinh,
		'0935249316' AS DienThoai,
		'tuananhnkpro@gmail.com' AS Email,
		N'Giải pháp hoàn thiện hệ thống quản lý chất lượng tại Công ty Tân Phú Việt Nam tại chi nhánh Long An' AS DeTaiDangKy,
		N'PGS. TS. Nguyễn Thanh Lâm' AS GVHD_1,
		N'TS. Lý Ngọc Toàn' AS  GVHD_2

		UNION ALL

		SELECT 2 AS TT,
		'22CQ911' AS LopID,
		'921000028' AS MaHV,
		N'Lê Thị Kim' AS Ho,
		N'Dung' AS Ten,
		'24/07/1984' AS NgaySinh,
		'0917648929' AS DienThoai,
		'kimdungstc84@gmail.com' AS Email,
		N'Một số giải pháp nâng cao chất lượng dịch vụ hành chính công tại Sở Nội vụ tỉnh Đồng Nai' AS DeTaiDangKy,
		N'TS. Mai Thị Ánh Tuyết' AS GVHD_1,
		N'TS. Lý Ngọc Toàn' AS  GVHD_2
		UNION ALL

		SELECT 3 AS TT,
		'22CQ911' AS LopID,
		'921000010' AS MaHV,
		N'Nguyễn Thanh' AS Ho,
		N'Hà' AS Ten,
		'04/06/1990' AS NgaySinh,
		'0912438191' AS DienThoai,
		'tonyhacoi@gmail.com' AS Email,
		N'Các nhan tố ảnh hưởng đến giá trị tài sản thương hiệu tại Ngân hàng thương mại Cổ phần Phát triển thành phố Hồ Chí Minh (HD Bank) chi nhánh Đồng Nai' AS DeTaiDangKy,
		N'TS. Nguyễn Văn Dũng' AS GVHD_1,
		N'TS. Lý Ngọc Toàn' AS  GVHD_2
END