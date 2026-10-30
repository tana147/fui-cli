CREATE PROC spAPI_GiaoVienLop_Get_By_GiaoVienID @GiaoVienID VARCHAR(9), @NienKhoa INT, @sys_UserID VARCHAR(9), @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    IF (@NienKhoa IS NULL OR @NienKhoa = 0)
    BEGIN
        SET @NienKhoa = dbo.fn_GetNienKhoa_HienTai();
    END;

    IF (@GiaoVienID IS NULL OR @GiaoVienID = '' OR @GiaoVienID = '0')
    BEGIN
        SET @GiaoVienID = dbo.fn_GetUser_LMS(@sys_UserID);
    END;

    ;WITH TeacherClass (
        GVLopID,
        GiaoVienID,
        KhoiID,
        LopID,
        MonHocID,
        MaDonVi,
        Enable,
        VaiTro,
        NienKhoa,
        HocKy,
        ToGiangDayID,
        GhiChu,
        Is_PhanCong_QLDiem,
        CreateUser,
        CreateTime,
        UpdateUser,
        UpdateTime
    ) AS (
        SELECT
            GVLopID,
            GiaoVienID,
            KhoiID,
            LopID,
            MonHocID,
            MaDonVi,
            Enable,
            VaiTro,
            NienKhoa,
            HocKy,
            ToGiangDayID,
            GhiChu,
            Is_PhanCong_QLDiem,
            CreateUser,
            CreateTime,
            UpdateUser,
            UpdateTime
        FROM dbo.tblGiaoVienLop
        WHERE GiaoVienID = @GiaoVienID
          AND Enable = 1
          AND NienKhoa = @NienKhoa
    )
    SELECT gvl.*
         , gv.HoGV + ' ' + gv.TenGV AS HoTen
         , mh.*
         , l.*
         , k.*
         , n.NhomID
         , n.TenNhom
         , n.KhoiID AS NhomKhoiID
         , n.NienKhoa AS NhomNienKhoa
    FROM
           TeacherClass              gvl
           INNER JOIN dbo.tblGiaoVien gv ON gv.GiaoVienID = gvl.GiaoVienID
                                        AND gv.Enable     = 1
           LEFT JOIN dbo.tblMonHoc    mh ON mh.MonHocID   = gvl.MonHocID
                                        AND mh.Enable     = 1
           -- LopID có thể được tái sử dụng giữa các niên khóa; phải giới hạn cùng NienKhoa
           -- để không ghép phân công năm hiện tại với tên lớp của năm cũ.
           LEFT JOIN dbo.tblLop       l ON l.LopID        = gvl.LopID
                                       AND l.NienKhoa     = gvl.NienKhoa
                                       AND l.Enable       = 1
           LEFT JOIN dbo.tblNhom       n ON n.NhomID       = gvl.LopID
                                       AND n.NienKhoa     = gvl.NienKhoa
                                       AND n.Enable       = 1
           LEFT JOIN dbo.tblKhoi       k ON k.KhoiID       = COALESCE(l.KhoiID, n.KhoiID)
                                       AND k.Enable       = 1
    WHERE
           gvl.GiaoVienID = @GiaoVienID
      AND  (l.LopID IS NOT NULL OR n.NhomID IS NOT NULL)
    ORDER BY
           mh.Sort;

END;
