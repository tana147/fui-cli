 CREATE PROCEDURE [dbo].[spAPI_HDKH_DM_GetAll]
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;


    SELECT 'VaiTro' AS DanhMucCode, ID AS value, TenVaiTro AS title 
    FROM dbo.tblHDKH_DM_VaiTro WHERE IsActive = 1 ORDER BY TenVaiTro;

    SELECT 'NgonNgu' AS DanhMucCode, ID AS value, TenNgonNgu AS title, HeSoNhan
    FROM dbo.tblHDKH_DM_NgonNgu WHERE IsActive = 1 ORDER BY TenNgonNgu;

    SELECT 'DanhMucTapChi' AS DanhMucCode, ID AS value, TenDanhMuc AS title 
    FROM dbo.tblHDKH_DM_DanhMucTapChi WHERE IsActive = 1 ORDER BY ID;

    SELECT 'TheLoaiSach' AS DanhMucCode, ID AS value, TenTheLoai AS title 
    FROM dbo.tblHDKH_DM_TheLoaiSach WHERE IsActive = 1 ORDER BY TenTheLoai;

    SELECT 'ThoiLuong' AS DanhMucCode, ID AS value, TenThoiLuong AS title 
    FROM dbo.tblHDKH_DM_ThoiLuong WHERE IsActive = 1 ORDER BY ID;

    SELECT 'TheLoaiBienSoan' AS DanhMucCode, ID AS value, TenTheLoai AS title 
    FROM dbo.tblHDKH_DM_TheLoaiBienSoan WHERE IsActive = 1 ORDER BY TenTheLoai;

    -- 7. Lấy danh mục Cấp Đề tài
    -- DataSource Code: 'CapDeTai'
    SELECT 'CapDeTai' AS DanhMucCode, ID AS value, TenCapDeTai AS title
    FROM dbo.tblHDKH_DM_CapDeTai WHERE IsActive = 1 ORDER BY ID;
    
    -- 8. Lấy danh mục Loại hình Phản biện
    -- DataSource Code: 'LoaiHinhPhanBien'
    SELECT 'LoaiHinhPhanBien' AS DanhMucCode, ID AS value, TenLoaiHinh AS title
    FROM dbo.tblHDKH_DM_LoaiHinhPhanBien WHERE IsActive = 1 ORDER BY ID;

    -- 9. Lấy danh mục Cấp Cuộc thi
    -- DataSource Code: 'CapCuocThi'
    SELECT 'CapCuocThi' AS DanhMucCode, ID AS value, TenCap AS title
    FROM dbo.tblHDKH_DM_CapCuocThi WHERE IsActive = 1 ORDER BY ID;

    -- 10. Lấy danh mục Kết quả Giải
    -- DataSource Code: 'KetQuaGiai'
    SELECT 'KetQuaGiai' AS DanhMucCode, ID AS value, TenGiai AS title
    FROM dbo.tblHDKH_DM_KetQuaGiai WHERE IsActive = 1 ORDER BY ID;

    -- 11. Lấy danh mục Cấp Hội thảo
    -- DataSource Code: 'CapHoiThao'
    SELECT 'CapHoiThao' AS DanhMucCode, ID AS value, TenCap AS title
    FROM dbo.tblHDKH_DM_CapHoiThao WHERE IsActive = 1 ORDER BY ID;

    -- 12. Lấy danh mục Bậc Đào tạo
    -- DataSource Code: 'BacDaoTao'
    SELECT 'BacDaoTao' AS DanhMucCode, ID AS value, TenBac AS title
    FROM dbo.tblHDKH_DM_BacDaoTao WHERE IsActive = 1 ORDER BY ID;

    -- 13. Lấy danh mục Nhiệm vụ Hội đồng
    -- DataSource Code: 'NhiemVuHoiDong'
    SELECT 'NhiemVuHoiDong' AS DanhMucCode, ID AS value, TenNhiemVu AS title
    FROM dbo.tblHDKH_DM_NhiemVuHoiDong WHERE IsActive = 1 ORDER BY ID;

	 -- DataSource Code: 'PhamVi'
    SELECT 'PhamVi' AS DanhMucCode, ID AS value, TenPhamVi AS title
    FROM dbo.tblHDKH_DM_PhamVi WHERE IsActive = 1 ORDER BY ID;

	SELECT 'LoaiHinhSHTT' AS DanhMucCode, ID AS value, TenLoaiHinh AS title
    FROM dbo.tblHDKH_DM_LoaiHinhSHTT WHERE IsActive = 1 ORDER BY ID;

END;
