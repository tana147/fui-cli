-- ============================================================
-- SCRIPT KHÔI PHỤC DỮ LIỆU NGUYỄN HỮU THỊNH (925000005)
-- Sử dụng để Revert về trạng thái nguyên bản trước khi test
-- ============================================================

-- 1. Khôi phục trạng thái bảng HoiDong (ID: 2712)
UPDATE HoiDong
SET Is_Xoa = 0,
    LyDoHuy = NULL,
    ThoiGianBaoVe = '2026-10-30',
    Decision_ID = 4392,
    HoiDong_Status = 1,
    KetQuaHoiDong = 0,
    DiemHoiDong = NULL,
    Updated_By = 'NV0001176',
    Updated_At = '2026-10-19T16:14:24.920'
WHERE HoiDongID = 2712;

-- 2. Khôi phục 5 thành viên trong HoiDongThanhVien
UPDATE HoiDongThanhVien
SET Is_Xoa = 0,
    Updated_By = 'NV0001176',
    Updated_At = '2026-10-19T16:14:24.923'
WHERE HoiDongID = 2712;

-- 3. Khôi phục trạng thái Flow (Task 5: Hoàn thành 'C', Task 6: Đang làm 'P')
UPDATE Flow
SET Flow_Status = 'C',
    Updated_By = 'NV0001176',
    Updated_At = '2026-10-24T08:20:40.593'
WHERE Flow_ID = 25594; -- Task 5: Duyệt Luận Văn (ThS04)

UPDATE Flow
SET Flow_Status = 'P',
    Updated_By = 'NV0001176',
    Updated_At = '2026-10-24T08:20:40.610'
WHERE Flow_ID = 25595; -- Task 6: Bảo vệ luận Văn (ThS05)

-- 4. Khôi phục Flow_Detail của Task 5 (Duyệt Luận Văn)
-- QDThanhLapHoiDongConfirm (Flow_Detail_ID: 218135)
UPDATE Flow_Detail
SET Text_Content = '2036/QĐ-ĐHLH',
    Flow_Detail_Status = 'C',
    Updated_By = 'NV0001176',
    Updated_At = '2026-10-24T08:20:38.160'
WHERE Flow_Detail_ID = 218135;

-- QDThanhLapHoiDong_No (Flow_Detail_ID: 218136)
UPDATE Flow_Detail
SET Text_Content = '2036/QĐ-ĐHLH',
    Flow_Detail_Status = 'C',
    Updated_By = 'NV0001176',
    Updated_At = '2026-10-24T08:20:38.823'
WHERE Flow_Detail_ID = 218136;

-- QDThanhLapHoiDong_ThoiGian (Flow_Detail_ID: 218137)
UPDATE Flow_Detail
SET Text_Content = '2026-10-30',
    Flow_Detail_Status = 'C',
    Updated_By = 'NV0001176',
    Updated_At = '2026-10-24T08:20:39.490'
WHERE Flow_Detail_ID = 218137;

-- HoiDongID (Flow_Detail_ID: 218138)
UPDATE Flow_Detail
SET Text_Content = '2712',
    Flow_Detail_Status = 'C',
    Updated_By = 'NV0001176',
    Updated_At = '2026-10-24T08:20:40.147'
WHERE Flow_Detail_ID = 218138;

-- 5. Khôi phục Flow_Detail của Task 6 (Bảo vệ luận Văn)
-- FileMeetingID (Flow_Detail_ID: 218139)
UPDATE Flow_Detail
SET Flow_Detail_Status = 'P',
    Updated_By = 'auto_next_nckh',
    Updated_At = '2026-10-24T08:20:40.417'
WHERE Flow_Detail_ID = 218139;

SELECT 1 AS Restored, N'Đã khôi phục dữ liệu Nguyễn Hữu Thịnh thành công' AS Message;
