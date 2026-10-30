CREATE PROC [dbo].[spAPI_MonHoc_Get_ByLopID]
	@NienKhoa INT   
	, @HocKi INT
	,  @LopID           VARCHAR(10)
  , @SYS_USERID      VARCHAR(9)
  , @sys_SystemRight INT
AS
BEGIN
    IF @sys_SystemRight IN (3, 5, 9)
    BEGIN
        SELECT DISTINCT
               [MHL].[MonHocLopID]
             , MH.[MonHocID]
             , MH.MonHocCode
             , MH.TenMonDuLieuNganh
             , MH.MonHocGroup
             , MH.TenMonDuLieuNganh
             , MHL.LopNhomID AS LopID
             , [MHL].[NienKhoa]
             , [MHL].[GVGiangDay1]
             , [MHL].[GVGiangDay2]
             , [MHL].[TemplateBangDiemID]
             , [MHL].[TemplateReportHTML]
             , [MHL].[TemplateReportPDF]
             , MH.Is_MonHoc_BoTro
             , MH.TenMonHoc_HienThi
             , MH.List_MonHoc_NLPC_ID
             , MH.MonHocName
             , MH.IsThiTapTrung
			 , Sort
        --, gvl.GiaoVienID
        FROM
               dbo.tblMonHocLop              MHL
               INNER JOIN dbo.tblMonHoc      MH ON MHL.MonHocID  = MH.MonHocID
                                               AND MH.Enable     = 1
               --INNER JOIN dbo.tblGiaoVienLop gvl ON gvl.MonHocID = MH.MonHocID
               --                                 --AND gvl.GiaoVienID                 = (CASE
               --                                 --                                           WHEN @SYS_USERID = 'NA0000022' THEN gvl.GiaoVienID
               --                                 --                                           ELSE @SYS_USERID
               --                                 --                                      END
               --                                 --                                     )
               --                                 -- AND gvl.GiaoVienID = @SYS_USERID
               --                                 AND gvl.LopID    = MHL.LopNhomID
               --                                 AND gvl.VaiTro IN (1, 3)
               --                                 AND gvl.Enable   = 1
        WHERE
               MHL.NienKhoa = @NienKhoa
          AND  MHL.[Enable]  = 1
          AND  MHL.LopNhomID = @LopID
          AND  MH.MonHocID NOT IN (   14 --Phẩm chất
                                         --23	, --Phẩm chất-Yêu nước
                                         --24	, --Phẩm chất-Nhân ái
                                         --25	, --Phẩm chất-Chăm chỉ
                                         --26	, --Phẩm chất-Trung thực
                                         --27	, --Phẩm chất-Trách nhiệm
                                    , 13 --Năng lực
                                         --20	, --Năng lực-Tự chủ và tự học
                                         --21	, --Năng lực-Giao tiếp và hợp tác
                                         --22	, --Năng lực-Giải quyết vấn đề và sáng tạo
                                    , 28 --Năng lực-Ngôn ngữ
                                    , 29 --Năng lực-Tính toán
                                    , 30 --Năng lực-Khoa học
                                    , 31 --Năng lực-Công nghệ
                                    , 32 --Năng lực-Tin học
                                    , 33 --Năng lực-Thẩm mĩ
                                    , 34 --Năng lực-Thể chất
                                  )
        ORDER BY
                MH.Sort;
    END;
    ELSE
    BEGIN 
        IF EXISTS
        (
            SELECT TOP 1
                   *
            FROM
                   dbo.tblLop
            WHERE
                   GVCN    = @SYS_USERID
				   AND LopID = @LopID
              AND  NienKhoa = @NienKhoa
              AND  Enable   = 1
        )
        BEGIN
           SELECT [MHL].[MonHocLopID]
                 , MH.[MonHocID]
                 , MH.MonHocCode
                 , MH.TenMonDuLieuNganh
                 , MH.MonHocGroup
                 , MH.TenMonDuLieuNganh
                 , MHL.LopNhomID AS LopID
                 , [MHL].[NienKhoa]
                 , [MHL].[GVGiangDay1]
                 , [MHL].[GVGiangDay2]
                 , [MHL].[TemplateBangDiemID]
                 , [MHL].[TemplateReportHTML]
                 , [MHL].[TemplateReportPDF]
                 , MH.Is_MonHoc_BoTro
                 , MH.TenMonHoc_HienThi
                 , MH.List_MonHoc_NLPC_ID
                 , MH.MonHocName
                 , MH.IsThiTapTrung
                 --, gvl.GiaoVienID
            FROM
                   dbo.tblMonHocLop              MHL
                   INNER JOIN dbo.tblMonHoc      MH ON MHL.MonHocID    = MH.MonHocID
                                                   AND MH.Enable       = 1
                   --INNER JOIN dbo.tblGiaoVienLop gvl ON gvl.MonHocID   = MH.MonHocID
                   --                                 --AND gvl.GiaoVienID                 = (CASE
                   --                                 --                                           WHEN @SYS_USERID = 'NA0000022' THEN gvl.GiaoVienID
                   --                                 --                                           ELSE @SYS_USERID
                   --                                 --                                      END
                   --                                 --                                     )
                   --                                 --AND gvl.GiaoVienID = @SYS_USERID
                   --                                 AND gvl.LopID      = MHL.LopNhomID
                   --                                 --AND gvl.VaiTro IN (1, 3)
                   --                                 AND gvl.Enable     = 1
            WHERE
                   MHL.NienKhoa = @NienKhoa
              AND  MHL.[Enable]  = 1
              AND  MHL.LopNhomID = @LopID
              AND  MH.MonHocID NOT IN (   14 --Phẩm chất
                                             --23	, --Phẩm chất-Yêu nước
                                             --24	, --Phẩm chất-Nhân ái
                                             --25	, --Phẩm chất-Chăm chỉ
                                             --26	, --Phẩm chất-Trung thực
                                             --27	, --Phẩm chất-Trách nhiệm
                                        , 13 --Năng lực
                                             --20	, --Năng lực-Tự chủ và tự học
                                             --21	, --Năng lực-Giao tiếp và hợp tác
                                             --22	, --Năng lực-Giải quyết vấn đề và sáng tạo
                                        , 28 --Năng lực-Ngôn ngữ
                                        , 29 --Năng lực-Tính toán
                                        , 30 --Năng lực-Khoa học
                                        , 31 --Năng lực-Công nghệ
                                        , 32 --Năng lực-Tin học
                                        , 33 --Năng lực-Thẩm mĩ
                                        , 34 --Năng lực-Thể chất
                                      )
            ORDER BY
                   MH.Sort;
        END;
        ELSE
        BEGIN
            SELECT [MHL].[MonHocLopID]
                 , MH.[MonHocID]
                 , MH.MonHocCode
                 , MH.TenMonDuLieuNganh
                 , MH.MonHocGroup
                 , MH.TenMonDuLieuNganh
                 , MHL.LopNhomID AS LopID
                 , [MHL].[NienKhoa]
                 , [MHL].[GVGiangDay1]
                 , [MHL].[GVGiangDay2]
                 , [MHL].[TemplateBangDiemID]
                 , [MHL].[TemplateReportHTML]
                 , [MHL].[TemplateReportPDF]
                 , MH.Is_MonHoc_BoTro
                 , MH.TenMonHoc_HienThi
                 , MH.List_MonHoc_NLPC_ID
                 , MH.MonHocName
                 , MH.IsThiTapTrung
                 , gvl.GiaoVienID
            FROM
                   dbo.tblMonHocLop              MHL
                   INNER JOIN dbo.tblMonHoc      MH ON MHL.MonHocID    = MH.MonHocID
                                                   AND MH.Enable       = 1
                   INNER JOIN dbo.tblGiaoVienLop gvl ON gvl.MonHocID   = MH.MonHocID
                                                    --AND gvl.GiaoVienID                 = (CASE
                                                    --                                           WHEN @SYS_USERID = 'NA0000022' THEN gvl.GiaoVienID
                                                    --                                           ELSE @SYS_USERID
                                                    --                                      END
                                                    --                                     )
                                                    AND gvl.GiaoVienID = @SYS_USERID
                                                    AND gvl.LopID      = MHL.LopNhomID
                                                    AND gvl.VaiTro IN (1, 3)
                                                    AND gvl.Enable     = 1
													and gvl.NienKhoa = @NienKhoa
													AND gvl.HocKy = @HocKi
            WHERE
                   MHL.NienKhoa = @NienKhoa
              AND  MHL.[Enable]  = 1
              AND  MHL.LopNhomID = @LopID
              AND  MH.MonHocID NOT IN (   14 --Phẩm chất
                                             --23	, --Phẩm chất-Yêu nước
                                             --24	, --Phẩm chất-Nhân ái
                                             --25	, --Phẩm chất-Chăm chỉ
                                             --26	, --Phẩm chất-Trung thực
                                             --27	, --Phẩm chất-Trách nhiệm
                                        , 13 --Năng lực
                                             --20	, --Năng lực-Tự chủ và tự học
                                             --21	, --Năng lực-Giao tiếp và hợp tác
                                             --22	, --Năng lực-Giải quyết vấn đề và sáng tạo
                                        , 28 --Năng lực-Ngôn ngữ
                                        , 29 --Năng lực-Tính toán
                                        , 30 --Năng lực-Khoa học
                                        , 31 --Năng lực-Công nghệ
                                        , 32 --Năng lực-Tin học
                                        , 33 --Năng lực-Thẩm mĩ
                                        , 34 --Năng lực-Thể chất
                                      )
            ORDER BY
                     MH.Sort;
        END;



    END;
END;
