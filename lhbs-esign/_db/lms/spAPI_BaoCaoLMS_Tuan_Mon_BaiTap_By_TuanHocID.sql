--[dbo].[spAPI_BaoCaoLMS_Tuan_Mon_BaiTap_By_TuanHocID]
-- 165,
-- 220,
-- 2
CREATE PROC [dbo].[spAPI_BaoCaoLMS_Tuan_Mon_BaiTap_By_TuanHocID]
  @CapID           INT
  , @Thang		INT
  , @Nam		INT
  , @NienKhoa	INT
AS
BEGIN
    -- Tổng số bài tập theo tuần
    SELECT asm.TuanHocID
              , N'Tuần ' + CAST(th.Tuan AS VARCHAR(2))+ N' - Tháng ' + CAST(th.ThangHoc AS VARCHAR(2) ) AS Tuan_HienThi  --dbo.fnGetTuanHoc_HienThi(th.Tuan, th.ThangHoc, th.NgayBatDau, th.NgayKetThuc) AS Tuan_HienThi
         , COUNT(asm.AssignmentID)                                                       AS SoLuongBaiTap
    FROM
           dbo.tblEL_Assignments  asm
           JOIN dbo.tblTuanHocTap th ON th.TuanHocID = asm.TuanHocID
		   AND th.ThangHoc = @Thang
		   AND th.Nam = @Nam
		   AND th.NienKhoa = @NienKhoa
           JOIN dbo.tblKhoi       k ON k.KhoiID      = asm.KhoiID
                                   AND k.CapID       = @CapID
    WHERE
	  ISNULL(asm.IsDev, 0) <> 1
      AND  asm.IsDeleted        = 0
    GROUP BY
           asm.TuanHocID
         , th.Tuan
         , th.ThangHoc
    ORDER BY
           asm.TuanHocID;

    -- Tổng số bài tập theo tuần + môn học
    SELECT asm.TuanHocID
         , asm.MonHocID
         , mh.TenMonHoc_HienThi
             , N'Tuần ' + CAST(th.Tuan AS VARCHAR(2))+ N' - Tháng ' + CAST(th.ThangHoc AS VARCHAR(2) ) AS Tuan_HienThi
         , COUNT(asm.AssignmentID)                                                       AS SoLuongBaiTap
    FROM
           dbo.tblEL_Assignments  asm
           JOIN dbo.tblMonHoc     mh ON mh.MonHocID  = asm.MonHocID
                                    AND mh.Enable    = 1
           JOIN dbo.tblKhoi       k ON k.KhoiID      = asm.KhoiID
                                   AND k.CapID       = @CapID
           JOIN dbo.tblTuanHocTap th ON th.TuanHocID = asm.TuanHocID
		     AND th.ThangHoc = @Thang
			 AND th.Nam = @Nam
		   AND th.NienKhoa = @NienKhoa
    WHERE
	  ISNULL(asm.IsDev, 0) <> 1
      AND  asm.IsDeleted        = 0
    GROUP BY
           asm.TuanHocID
         , asm.MonHocID
         , mh.TenMonHoc_HienThi
         , th.Tuan
         , th.ThangHoc
    ORDER BY
           asm.TuanHocID
         , asm.MonHocID;
END;
