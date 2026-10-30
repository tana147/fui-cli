CREATE PROCEDURE spAPI_WF_GoiKy_GetDetail
    @url1_GoiKyID bigint,
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- data[0]: thông tin gói ký (1 dòng)
    SELECT
        g.GoiKyID, g.TieuDe, g.HinhThucKy,
        HinhThucKyText = CASE g.HinhThucKy
            WHEN 'CA_NOIBO' THEN N'Ký nội bộ'
            WHEN 'SMARTCA' THEN N'VNPT SmartCA'
            WHEN 'VNPT_ECONTRACT' THEN N'HĐ điện tử VNPT'
            ELSE g.HinhThucKy END,
        g.FileGocID, g.TenFileGoc, g.FileDaKyID, g.TenFileDaKy,
        FileUrl = CASE WHEN g.FileGocID IS NOT NULL THEN 'https://file.zentea.vn/iotdev/FileData/' + CAST(g.FileGocID AS varchar(50)) ELSE '' END,
        g.TrangThai,
        TrangThaiText = CASE g.TrangThai
            WHEN 'MOI' THEN N'Mới tạo' WHEN 'CHO_KY' THEN N'Đang chờ ký'
            WHEN 'DA_KY' THEN N'Hoàn tất' WHEN 'TU_CHOI' THEN N'Từ chối' ELSE g.TrangThai END,
        g.CreateUser, g.CreateTime,
        LaLuotCuaToi = CASE WHEN EXISTS (
            SELECT 1 FROM tblWF_NguoiKy nk WHERE nk.GoiKyID = g.GoiKyID AND nk.Enable = 1
              AND nk.TrangThai = 'CHO' AND nk.GiaTriNguoiKy = @sys_UserID
        ) THEN 1 ELSE 0 END
    FROM tblWF_GoiKy g
    WHERE g.GoiKyID = @url1_GoiKyID;

    -- data[1]: danh sách người ký
    SELECT nk.NguoiKyID, nk.ThuTuKy, nk.TenNguoiKy, nk.PhongBan,
        nk.PhuongThucKy, nk.TrangThai,
        TrangThaiText = CASE nk.TrangThai
            WHEN 'CHO' THEN N'Chờ ký' WHEN 'DA_KY' THEN N'Đã ký'
            WHEN 'TU_CHOI' THEN N'Từ chối' ELSE nk.TrangThai END,
        nk.NgayKy,
        LaToi = CASE WHEN nk.GiaTriNguoiKy = @sys_UserID THEN 1 ELSE 0 END
    FROM tblWF_NguoiKy nk
    WHERE nk.GoiKyID = @url1_GoiKyID AND nk.Enable = 1
    ORDER BY nk.ThuTuKy;

    -- data[2]: vị trí box ký (map sang shape canvas)
    SELECT InstanceSignBoxID = vt.ViTriKyID,
        PageNo = vt.SoTrang, PosX = vt.ToaDoX, PosY = vt.ToaDoY,
        BoxWidth = vt.ChieuRong, BoxHeight = vt.ChieuCao,
        LabelText = vt.NhanHienThi, vt.TrangThai
    FROM tblWF_ViTriKy vt
    WHERE vt.GoiKyID = @url1_GoiKyID AND vt.Enable = 1
    ORDER BY vt.ThuTuBox;
END