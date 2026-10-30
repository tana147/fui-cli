--[dbo].[spAPI_ChiTieu_C1_Get] 2025
CREATE PROC [dbo].[spAPI_ChiTieu_C1_Get] @NienKhoa INT
AS
BEGIN
    DECLARE @Table_MonHocID TABLE
    (
        KhoiID    INT
      , MonHocID  INT
      , Is_MonHoc BIT
    );

    INSERT @Table_MonHocID
    SELECT DISTINCT
           l.KhoiID
         , mhl.MonHocID
         , 1
    FROM
           dbo.tblMonHocLop      mhl
           INNER JOIN dbo.tblLop l ON l.Enable   = mhl.Enable
                                  AND l.CapID    = 1
                                  AND l.NienKhoa = @NienKhoa
    WHERE
           mhl.Enable  = 1
      AND  mhl.NienKhoa = @NienKhoa
      AND  mhl.MonHocID IN (   1  --Tiếng Việt
                             , 2  --Toán
                             , 5  --Ngoại ngữ
                             , 3  --Tự nhiên và Xã hội
                             , 4  --Khoa học
                             , 19 --Lịch sử/Địa lí
                             , 8  --Đạo đức
                             , 9  --Âm nhạc
                             , 10 --Mĩ thuật
                             , 11 --Hoạt động trải nghiệm
                             , 12 --Thể dục
                             , 6  --Tin học và Công nghệ (Tin học)
                             , 35 --Tin học và Công nghệ (Công nghệ)
                           )
    UNION
    SELECT DISTINCT
           l.KhoiID
         , mhl.MonHocID
         , 0
    FROM
           dbo.tblMonHocLop      mhl
           INNER JOIN dbo.tblLop l ON l.Enable   = mhl.Enable
                                  AND l.CapID    = 1
                                  AND l.NienKhoa = @NienKhoa
    WHERE
           mhl.Enable  = 1
      AND  mhl.NienKhoa = @NienKhoa
      AND  mhl.MonHocID IN (   20 --Năng lực-Tự chủ và tự học
                             , 21 --Năng lực-Giao tiếp và hợp tác
                             , 22 --Năng lực-Giải quyết vấn đề và sáng tạo
                             , 23 --Phẩm chất-Yêu nước
                             , 24 --Phẩm chất-Nhân ái
                             , 25 --Phẩm chất-Chăm chỉ
                             , 26 --Phẩm chất-Trung thực
                             , 27 --Phẩm chất-Trách nhiệm
                             , 28 --Năng lực-Ngôn ngữ
                             , 29 --Năng lực-Tính toán
                             , 30 --Năng lực-Khoa học
                             , 31 --Năng lực-Công nghệ
                             , 32 --Năng lực-Tin học
                             , 33 --Năng lực-Thẩm mĩ
                             , 34 --Năng lực-Thể chất

                           );

    SELECT ISNULL(ct.ChiTieuID, 0)        AS ChiTieuID
         , t.KhoiID
         , t.Is_MonHoc
         , t.MonHocID
         , mh.TenMonHoc_HienThi
         , ISNULL(ct.NienKhoa, @NienKhoa) AS NienKhoa
         , ct.ChiTieu_HoanThanhTot
         , ct.ChiTieu_HoanThanh
         , ct.ChiTieu_ChuaHoanThanh
         , ct.ChiTieu_Tot
         , ct.ChiTieu_Dat
         , ct.ChiTieu_CanCoGang
    FROM
           @Table_MonHocID             AS t
           INNER JOIN dbo.tblMonHoc    AS mh ON mh.MonHocID = t.MonHocID
                                            AND mh.Enable   = 1
           LEFT JOIN dbo.tblChiTieu_C1 AS ct ON t.MonHocID  = ct.MonHocID
                                            AND t.KhoiID    = ct.KhoiID
                                            AND ct.NienKhoa = @NienKhoa
    ORDER BY
           t.KhoiID
         , mh.Sort;
END;










