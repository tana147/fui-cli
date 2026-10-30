CREATE PROCEDURE spAPI_TkbKetQuaXepList
    @RunID INT,
    @MaLop VARCHAR(10) = '',
    @MaGV VARCHAR(10) = '',
    @MaPhong VARCHAR(10) = '',
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- @MaLop/@MaGV/@MaPhong la tham so tuy chon — cac trang chi loc theo 1 chieu (vd tkb-theo-giaovien
    -- chi gui RunID+MaGV) se KHONG gui kem cac key con lai trong JSON body. tAPI bind key vang mat
    -- thanh NULL thay vi dung default '' cua SQL, nen dieu kien (@MaLop = '') se la UNKNOWN thay vi
    -- TRUE khi @MaLop=NULL, loc sach toan bo ket qua — phai coalesce ve '' truoc khi so sanh.
    SET @MaLop = ISNULL(@MaLop, '');
    SET @MaGV = ISNULL(@MaGV, '');
    SET @MaPhong = ISNULL(@MaPhong, '');

    SELECT k.ID, k.RunID, k.MaLop, k.Thu, k.Buoi, k.Tiet, k.MaMon, m.TenMon, k.MaGV, gv.HoTen AS TenGV, k.MaPhong,
           CAST(CASE WHEN kh.KetQuaXepID IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS DaKhoa, k.XoayTro
    FROM tblTKB_KetQuaXep k
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = k.MaMon
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = k.MaGV
    LEFT JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
    WHERE k.RunID = @RunID
      AND (@MaLop = '' OR k.MaLop = @MaLop)
      AND (@MaGV = '' OR k.MaGV = @MaGV)
      AND (@MaPhong = '' OR k.MaPhong = @MaPhong)
    ORDER BY k.MaLop, k.Thu, k.Buoi, k.Tiet;
END