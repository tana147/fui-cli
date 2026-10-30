CREATE PROCEDURE dbo.spAPI_SoGVCN_LichSuChinhSua_SyncAll
    @NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Xóa toàn bộ log của niên khóa để sync lại sạch sẽ 100%
    DELETE FROM dbo.tblSoGVCN_LichSuChinhSua WHERE NienKhoa = @NienKhoa;

    -- 1. Kế hoạch năm học - classStatistics
    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT 
        s.SoGVCNID,
        s.NienKhoa,
        l.KhoiID,
        LEFT(s.LopID, 20),
        'ke-hoach-nam-hoc',
        N'KH CHỦ NHIỆM NĂM HỌC',
        'thong-ke-tinh-hinh',
        N'1. Thống kê tình hình lớp học',
        N'I. ĐẶC ĐIỂM TÌNH HÌNH',
        LEFT(N'Bảng thống kê: ' + ISNULL(JSON_VALUE(cs.value, '$.ThoiDiem'), N'Đầu năm'), 200),
        N'Tổng số: ' + ISNULL(JSON_VALUE(cs.value, '$.TongSo'), '0') +
        N' | Nữ: ' + ISNULL(JSON_VALUE(cs.value, '$.Nu'), '0') +
        N' | Dân tộc: ' + ISNULL(JSON_VALUE(cs.value, '$.DanToc'), '0') +
        N' | Lưu ban: ' + ISNULL(JSON_VALUE(cs.value, '$.LuuBan'), '0') +
        N' | Cần quan tâm: ' + ISNULL(JSON_VALUE(cs.value, '$.CanQuanTam'), '0') +
        N' | Con thương binh: ' + ISNULL(JSON_VALUE(cs.value, '$.ConThuongBinh'), '0') +
        N' | Con liệt sĩ: ' + ISNULL(JSON_VALUE(cs.value, '$.ConLietSi'), '0') +
        N' | Hộ nghèo: ' + ISNULL(JSON_VALUE(cs.value, '$.HoNgheo'), '0') +
        N' | Hộ cận nghèo: ' + ISNULL(JSON_VALUE(cs.value, '$.HoCanNgheo'), '0'),
        NULL,
        NULL,
        LEFT(ISNULL(l.GVCN, ISNULL(kh.UpdateUser, s.CreateUser)), 50),
        LEFT(ISNULL(RTRIM(gv.HoGV) + ' ' + RTRIM(gv.TenGV), N'Giáo viên'), 100),
        ISNULL(kh.UpdateTime, kh.CreateTime),
        1
    FROM dbo.tblSoGVCNKeHoachNamHoc kh
    JOIN dbo.tblSoGVCN s ON kh.SoGVCNID = s.SoGVCNID
    JOIN dbo.tblLop l ON s.LopID = l.LopID AND l.NienKhoa = s.NienKhoa
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    CROSS APPLY OPENJSON(kh.JsonData, '$.classStatistics') cs
    WHERE s.NienKhoa = @NienKhoa 
      AND kh.Enable = 1
      AND JSON_VALUE(cs.value, '$.TongSo') IS NOT NULL
      AND JSON_VALUE(cs.value, '$.TongSo') <> '';

    -- 2. Kế hoạch năm học - Thuận lợi & Khó khăn
    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT 
        s.SoGVCNID,
        s.NienKhoa,
        l.KhoiID,
        LEFT(s.LopID, 20),
        'ke-hoach-nam-hoc',
        N'KH CHỦ NHIỆM NĂM HỌC',
        'thuan-loi-kho-khan',
        N'2. Thuận lợi & 3. Khó khăn',
        N'I. ĐẶC ĐIỂM TÌNH HÌNH',
        N'2. Thuận lợi',
        JSON_VALUE(kh.JsonData, '$.advantages'),
        NULL,
        NULL,
        LEFT(ISNULL(l.GVCN, ISNULL(kh.UpdateUser, s.CreateUser)), 50),
        LEFT(ISNULL(RTRIM(gv.HoGV) + ' ' + RTRIM(gv.TenGV), N'Giáo viên'), 100),
        ISNULL(kh.UpdateTime, kh.CreateTime),
        1
    FROM dbo.tblSoGVCNKeHoachNamHoc kh
    JOIN dbo.tblSoGVCN s ON kh.SoGVCNID = s.SoGVCNID
    JOIN dbo.tblLop l ON s.LopID = l.LopID AND l.NienKhoa = s.NienKhoa
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    WHERE s.NienKhoa = @NienKhoa 
      AND kh.Enable = 1
      AND JSON_VALUE(kh.JsonData, '$.advantages') IS NOT NULL
      AND JSON_VALUE(kh.JsonData, '$.advantages') <> '';

    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT 
        s.SoGVCNID,
        s.NienKhoa,
        l.KhoiID,
        LEFT(s.LopID, 20),
        'ke-hoach-nam-hoc',
        N'KH CHỦ NHIỆM NĂM HỌC',
        'thuan-loi-kho-khan',
        N'2. Thuận lợi & 3. Khó khăn',
        N'I. ĐẶC ĐIỂM TÌNH HÌNH',
        N'3. Khó khăn',
        JSON_VALUE(kh.JsonData, '$.difficulties'),
        NULL,
        NULL,
        LEFT(ISNULL(l.GVCN, ISNULL(kh.UpdateUser, s.CreateUser)), 50),
        LEFT(ISNULL(RTRIM(gv.HoGV) + ' ' + RTRIM(gv.TenGV), N'Giáo viên'), 100),
        ISNULL(kh.UpdateTime, kh.CreateTime),
        1
    FROM dbo.tblSoGVCNKeHoachNamHoc kh
    JOIN dbo.tblSoGVCN s ON kh.SoGVCNID = s.SoGVCNID
    JOIN dbo.tblLop l ON s.LopID = l.LopID AND l.NienKhoa = s.NienKhoa
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    WHERE s.NienKhoa = @NienKhoa 
      AND kh.Enable = 1
      AND JSON_VALUE(kh.JsonData, '$.difficulties') IS NOT NULL
      AND JSON_VALUE(kh.JsonData, '$.difficulties') <> '';

    -- 3. Kế hoạch năm học - Duy trì số lượng (Chỉ tiêu & Biện pháp)
    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT 
        s.SoGVCNID,
        s.NienKhoa,
        l.KhoiID,
        LEFT(s.LopID, 20),
        'ke-hoach-nam-hoc',
        N'KH CHỦ NHIỆM NĂM HỌC',
        'duy-tri-so-luong',
        N'1. Duy trì số lượng',
        N'II. NỘI DUNG KẾ HOẠCH',
        N'Chỉ tiêu phấn đấu',
        JSON_VALUE(kh.JsonData, '$.attendanceTarget'),
        NULL,
        NULL,
        LEFT(ISNULL(l.GVCN, ISNULL(kh.UpdateUser, s.CreateUser)), 50),
        LEFT(ISNULL(RTRIM(gv.HoGV) + ' ' + RTRIM(gv.TenGV), N'Giáo viên'), 100),
        ISNULL(kh.UpdateTime, kh.CreateTime),
        1
    FROM dbo.tblSoGVCNKeHoachNamHoc kh
    JOIN dbo.tblSoGVCN s ON kh.SoGVCNID = s.SoGVCNID
    JOIN dbo.tblLop l ON s.LopID = l.LopID AND l.NienKhoa = s.NienKhoa
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    WHERE s.NienKhoa = @NienKhoa 
      AND kh.Enable = 1
      AND JSON_VALUE(kh.JsonData, '$.attendanceTarget') IS NOT NULL
      AND JSON_VALUE(kh.JsonData, '$.attendanceTarget') <> '';

    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT 
        s.SoGVCNID,
        s.NienKhoa,
        l.KhoiID,
        LEFT(s.LopID, 20),
        'ke-hoach-nam-hoc',
        N'KH CHỦ NHIỆM NĂM HỌC',
        'duy-tri-so-luong',
        N'1. Duy trì số lượng',
        N'II. NỘI DUNG KẾ HOẠCH',
        N'Biện pháp thực hiện',
        JSON_VALUE(kh.JsonData, '$.attendanceSolution'),
        NULL,
        NULL,
        LEFT(ISNULL(l.GVCN, ISNULL(kh.UpdateUser, s.CreateUser)), 50),
        LEFT(ISNULL(RTRIM(gv.HoGV) + ' ' + RTRIM(gv.TenGV), N'Giáo viên'), 100),
        ISNULL(kh.UpdateTime, kh.CreateTime),
        1
    FROM dbo.tblSoGVCNKeHoachNamHoc kh
    JOIN dbo.tblSoGVCN s ON kh.SoGVCNID = s.SoGVCNID
    JOIN dbo.tblLop l ON s.LopID = l.LopID AND l.NienKhoa = s.NienKhoa
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    WHERE s.NienKhoa = @NienKhoa 
      AND kh.Enable = 1
      AND JSON_VALUE(kh.JsonData, '$.attendanceSolution') IS NOT NULL
      AND JSON_VALUE(kh.JsonData, '$.attendanceSolution') <> '';

    -- 4. Kế hoạch năm học - Chất lượng giáo dục (Biện pháp)
    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT 
        s.SoGVCNID,
        s.NienKhoa,
        l.KhoiID,
        LEFT(s.LopID, 20),
        'ke-hoach-nam-hoc',
        N'KH CHỦ NHIỆM NĂM HỌC',
        'chat-luong-giao-duc',
        N'2. Chất lượng giáo dục',
        N'II. NỘI DUNG KẾ HOẠCH',
        N'Biện pháp nâng cao chất lượng',
        JSON_VALUE(kh.JsonData, '$.qualitySolution'),
        NULL,
        NULL,
        LEFT(ISNULL(l.GVCN, ISNULL(kh.UpdateUser, s.CreateUser)), 50),
        LEFT(ISNULL(RTRIM(gv.HoGV) + ' ' + RTRIM(gv.TenGV), N'Giáo viên'), 100),
        ISNULL(kh.UpdateTime, kh.CreateTime),
        1
    FROM dbo.tblSoGVCNKeHoachNamHoc kh
    JOIN dbo.tblSoGVCN s ON kh.SoGVCNID = s.SoGVCNID
    JOIN dbo.tblLop l ON s.LopID = l.LopID AND l.NienKhoa = s.NienKhoa
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    WHERE s.NienKhoa = @NienKhoa 
      AND kh.Enable = 1
      AND JSON_VALUE(kh.JsonData, '$.qualitySolution') IS NOT NULL
      AND JSON_VALUE(kh.JsonData, '$.qualitySolution') <> '';

    -- 5. Kế hoạch năm học - Hoạt động khác
    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT 
        s.SoGVCNID,
        s.NienKhoa,
        l.KhoiID,
        LEFT(s.LopID, 20),
        'ke-hoach-nam-hoc',
        N'KH CHỦ NHIỆM NĂM HỌC',
        'hoat-dong-khac',
        N'3. Phong trào vở sạch chữ đẹp & HĐ khác',
        N'II. NỘI DUNG KẾ HOẠCH',
        N'Hoạt động phong trào ngoài giờ',
        JSON_VALUE(kh.JsonData, '$.extracurricularSolution'),
        NULL,
        NULL,
        LEFT(ISNULL(l.GVCN, ISNULL(kh.UpdateUser, s.CreateUser)), 50),
        LEFT(ISNULL(RTRIM(gv.HoGV) + ' ' + RTRIM(gv.TenGV), N'Giáo viên'), 100),
        ISNULL(kh.UpdateTime, kh.CreateTime),
        1
    FROM dbo.tblSoGVCNKeHoachNamHoc kh
    JOIN dbo.tblSoGVCN s ON kh.SoGVCNID = s.SoGVCNID
    JOIN dbo.tblLop l ON s.LopID = l.LopID AND l.NienKhoa = s.NienKhoa
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    WHERE s.NienKhoa = @NienKhoa 
      AND kh.Enable = 1
      AND JSON_VALUE(kh.JsonData, '$.extracurricularSolution') IS NOT NULL
      AND JSON_VALUE(kh.JsonData, '$.extracurricularSolution') <> '';

    -- 6. TỔ CHỨC LỚP - Cán bộ lớp
    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT 
        s.SoGVCNID,
        s.NienKhoa,
        l.KhoiID,
        LEFT(s.LopID, 20),
        'to-chuc-lop',
        N'TỔ CHỨC LỚP',
        'can-bo-lop',
        N'Cán bộ lớp',
        N'TỔ CHỨC LỚP HỌC',
        LEFT(cb.HocSinh + N' (' + cb.ChucVu + N')', 200),
        N'Chức vụ: ' + cb.ChucVu + N' | Mã HS: ' + ISNULL(cb.MaHocSinh, '') + 
        CASE WHEN ISNULL(cb.GhiChu, '') <> '' THEN N' | Ghi chú: ' + cb.GhiChu ELSE N'' END,
        NULL,
        NULL,
        LEFT(ISNULL(l.GVCN, 'NV0000001'), 50),
        LEFT(ISNULL(RTRIM(gv.HoGV) + ' ' + RTRIM(gv.TenGV), N'Giáo viên'), 100),
        ISNULL(cb.UpdateTime, cb.CreateTime),
        1
    FROM dbo.tblSoGVCNCanBoLop cb
    JOIN dbo.tblSoGVCN s ON cb.SoGVCNID = s.SoGVCNID
    JOIN dbo.tblLop l ON s.LopID = l.LopID AND l.NienKhoa = s.NienKhoa
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    WHERE s.NienKhoa = @NienKhoa 
      AND cb.Enable = 1
      AND ISNULL(cb.ChucVu, '') <> '';

    -- 7. TỔ CHỨC LỚP - Ban đại diện CMHS
    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT 
        s.SoGVCNID,
        s.NienKhoa,
        l.KhoiID,
        LEFT(s.LopID, 20),
        'to-chuc-lop',
        N'TỔ CHỨC LỚP',
        'ban-dai-dien-cmhs',
        N'Ban đại diện CMHS',
        N'TỔ CHỨC LỚP HỌC',
        LEFT(cm.HocSinh + N' (' + cm.NhiemVu + N')', 200),
        N'Nhiệm vụ: ' + cm.NhiemVu + 
        N' | Phụ huynh: ' + ISNULL(cm.ChaMe, N'—') + 
        N' | ĐT: ' + ISNULL(cm.DienThoai, N'—') + 
        N' | Nghề nghiệp: ' + ISNULL(cm.NgheNghiep, N'—'),
        NULL,
        NULL,
        LEFT(ISNULL(l.GVCN, 'NV0000001'), 50),
        LEFT(ISNULL(RTRIM(gv.HoGV) + ' ' + RTRIM(gv.TenGV), N'Giáo viên'), 100),
        ISNULL(cm.UpdateTime, cm.CreateTime),
        1
    FROM dbo.tblSoGVCNBanDaiDienCMHS cm
    JOIN dbo.tblSoGVCN s ON cm.SoGVCNID = s.SoGVCNID
    JOIN dbo.tblLop l ON s.LopID = l.LopID AND l.NienKhoa = s.NienKhoa
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    WHERE s.NienKhoa = @NienKhoa 
      AND cm.Enable = 1
      AND ISNULL(cm.NhiemVu, '') <> '';

    -- 8. THEO DÕI SĨ SỐ HS THEO THÁNG
    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT 
        s.SoGVCNID,
        s.NienKhoa,
        l.KhoiID,
        LEFT(s.LopID, 20),
        'theo-doi-si-so',
        N'THEO DÕI SĨ SỐ HS THEO THÁNG',
        'theo-doi-si-so',
        N'Theo dõi sĩ số tháng',
        N'SĨ SỐ HỌC SINH',
        LEFT(ISNULL(ss.ThoiDiem, N'Tháng'), 200),
        N'Tổng số: ' + ISNULL(ss.TongSo, '0') + 
        N' | Nữ: ' + ISNULL(ss.Nu, '0') + 
        N' | Đội viên: ' + ISNULL(ss.DoiVien, '0') + 
        N' | Nhi đồng: ' + ISNULL(ss.NhiDong, '0') + 
        N' | Khuyết tật có ĐG: ' + ISNULL(ss.KhuyetTatCoDanhGia, '0') + 
        N' | Hộ nghèo: ' + ISNULL(ss.HoNgheo, '0') + 
        CASE WHEN ISNULL(ss.TangGiamLiDo, '') <> '' THEN N' | Lý do biến động: ' + ss.TangGiamLiDo ELSE N'' END,
        NULL,
        NULL,
        LEFT(ISNULL(l.GVCN, ISNULL(ss.UpdateUser, 'NV0000001')), 50),
        LEFT(ISNULL(RTRIM(gv.HoGV) + ' ' + RTRIM(gv.TenGV), N'Giáo viên'), 100),
        ISNULL(ss.UpdateTime, ss.CreateTime),
        1
    FROM dbo.tblSoGVCNTheoDoiSiSoThang ss
    JOIN dbo.tblSoGVCN s ON ss.SoGVCNID = s.SoGVCNID
    JOIN dbo.tblLop l ON s.LopID = l.LopID AND l.NienKhoa = s.NienKhoa
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    WHERE s.NienKhoa = @NienKhoa 
      AND ss.Enable = 1
      AND (ss.TongSo IS NOT NULL OR ss.Nu IS NOT NULL);

    -- 9. NỘI DUNG HỌP PHHS
    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT 
        s.SoGVCNID,
        s.NienKhoa,
        l.KhoiID,
        LEFT(s.LopID, 20),
        'noi-dung-hop-phhs',
        N'NỘI DUNG HỌP PHHS',
        'noi-dung-hop',
        LEFT(ISNULL(hp.DotHop, N'Nội dung họp PHHS'), 255),
        N'HỌP PHỤ HUYNH',
        N'Nội dung chính cuộc họp',
        hp.NoiDungChinh,
        NULL,
        NULL,
        LEFT(ISNULL(l.GVCN, ISNULL(hp.UpdateUser, 'NV0000001')), 50),
        LEFT(ISNULL(RTRIM(gv.HoGV) + ' ' + RTRIM(gv.TenGV), N'Giáo viên'), 100),
        ISNULL(hp.UpdateTime, hp.CreateTime),
        1
    FROM dbo.tblSoGVCNNoiDungHopPHHS hp
    JOIN dbo.tblSoGVCN s ON hp.SoGVCNID = s.SoGVCNID
    JOIN dbo.tblLop l ON s.LopID = l.LopID AND l.NienKhoa = s.NienKhoa
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    WHERE s.NienKhoa = @NienKhoa 
      AND hp.Enable = 1
      AND ISNULL(hp.NoiDungChinh, '') <> '';

    -- 10. CÔNG TÁC CHỦ NHIỆM THÁNG (tblSoGVCNKeHoachThang)
    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT 
        s.SoGVCNID,
        s.NienKhoa,
        l.KhoiID,
        LEFT(s.LopID, 20),
        'cong-tac-cn',
        N'CÔNG TÁC CHỦ NHIỆM THÁNG',
        'ke-hoach-thang',
        LEFT(N'Kế hoạch trọng tâm tháng ' + CAST(kt.Thang AS VARCHAR(10)), 255),
        N'CÔNG TÁC CHỦ NHIỆM',
        LEFT(N'Đánh giá tháng ' + CAST(kt.Thang AS VARCHAR(10)), 200),
        kt.DanhGia,
        NULL,
        NULL,
        LEFT(ISNULL(l.GVCN, ISNULL(kt.UpdateUser, 'NV0000001')), 50),
        LEFT(ISNULL(RTRIM(gv.HoGV) + ' ' + RTRIM(gv.TenGV), N'Giáo viên'), 100),
        ISNULL(kt.UpdateTime, kt.CreateTime),
        1
    FROM dbo.tblSoGVCNKeHoachThang kt
    JOIN dbo.tblSoGVCN s ON kt.SoGVCNID = s.SoGVCNID
    JOIN dbo.tblLop l ON s.LopID = l.LopID AND l.NienKhoa = s.NienKhoa
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    WHERE s.NienKhoa = @NienKhoa 
      AND kt.Enable = 1
      AND ISNULL(kt.DanhGia, '') <> '';

    -- 11. HS CẦN QUAN TÂM
    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT 
        s.SoGVCNID,
        s.NienKhoa,
        l.KhoiID,
        LEFT(s.LopID, 20),
        'hs-can-quan-tam',
        N'HS CẦN QUAN TÂM',
        'hs-can-quan-tam',
        N'Hồ sơ HS cần quan tâm',
        N'THEO DÕI HỌC SINH',
        LEFT(ISNULL(hs.HocSinh, N'Học sinh') + N' (' + CAST(cq.HocSinhID AS VARCHAR(20)) + N')', 200),
        N'Nội dung cần hỗ trợ: ' + ISNULL(NULLIF(cq.CanHoTroDacBiet, ''), N'Theo dõi thường xuyên') +
        CASE WHEN ISNULL(cq.Thang9, '') <> '' THEN N' | T9: ' + cq.Thang9 ELSE N'' END +
        CASE WHEN ISNULL(cq.Thang10, '') <> '' THEN N' | T10: ' + cq.Thang10 ELSE N'' END,
        NULL,
        NULL,
        LEFT(ISNULL(l.GVCN, ISNULL(cq.UpdateUser, 'NV0000001')), 50),
        LEFT(ISNULL(RTRIM(gv.HoGV) + ' ' + RTRIM(gv.TenGV), N'Giáo viên'), 100),
        ISNULL(cq.UpdateTime, cq.CreateTime),
        1
    FROM dbo.tblSoGVCNHocSinhCanQuanTam cq
    JOIN dbo.tblSoGVCN s ON cq.SoGVCNID = s.SoGVCNID
    JOIN dbo.tblLop l ON s.LopID = l.LopID AND l.NienKhoa = s.NienKhoa
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    OUTER APPLY (
        SELECT TOP 1 RTRIM(ISNULL(Ho, '')) + ' ' + RTRIM(ISNULL(Ten, '')) AS HocSinh
        FROM dbo.tblHocSinh
        WHERE HocSinhID = cq.HocSinhID
    ) hs
    WHERE s.NienKhoa = @NienKhoa 
      AND cq.Enable = 1
      AND (ISNULL(cq.CanHoTroDacBiet, '') <> '' OR ISNULL(cq.Thang9, '') <> '' OR ISNULL(cq.Thang10, '') <> '');

    SELECT COUNT(*) AS TotalSyncedRows FROM dbo.tblSoGVCN_LichSuChinhSua WHERE NienKhoa = @NienKhoa;
END;