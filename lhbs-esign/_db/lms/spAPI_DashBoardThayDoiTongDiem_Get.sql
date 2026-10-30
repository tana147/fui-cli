-- [spAPI_DashBoardThayDoiTongDiem_Get] 2024, 12, 'N241202', 76
CREATE PROCEDURE [dbo].[spAPI_DashBoardThayDoiTongDiem_Get]
    @NienKhoa INT
  , @KhoiID   INT
  , @LopID    VARCHAR(10)
  , @MonHocID INT
AS
BEGIN
    DECLARE @IsNumber BIT;

    SET @IsNumber = CASE WHEN TRY_CAST(@LopID AS INT) IS NOT NULL THEN 1 ELSE 0 END;
    IF (@IsNumber = 1)
    BEGIN
        SELECT tl.LopID
             , tl.TenLop
             , ths.HocSinhID
             , ths.Ho + ' ' + ths.Ten AS HoTen
             , tmh.MonHocName
             , tmh.MonHocID
             -- Điểm giữa kỳ
             , MAX(   CASE
                           WHEN tbdct.MaCotDiem = 'S1_Mid_Total_Point' THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                           ELSE NULL
                      END
                  )                   AS DiemGK1
             -- Điểm cuối kỳ
             , MAX(   CASE
                           WHEN tbdct.MaCotDiem = 'S1_Final_Total_Point' THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                           ELSE NULL
                      END
                  )                   AS DiemCK1
             -- Chênh lệch điểm
             , MAX(   CASE
                           WHEN tbdct.MaCotDiem = 'S1_Final_Total_Point' THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                           ELSE NULL
                      END
                  ) - MAX(   CASE
                                  WHEN tbdct.MaCotDiem = 'S1_Mid_Total_Point' THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                                  ELSE NULL
                             END
                         )            AS ChenhLechDiem
        FROM
               dbo.tblKetQuaHocTap                    tkqht
               INNER JOIN dbo.tblHocSinh              ths ON ths.HocSinhID     = tkqht.HocSinhID
               INNER JOIN dbo.tblHocSinhLop           thsl ON ths.HocSinhID    = thsl.HocSinhID
               INNER JOIN dbo.tblLop                  tl ON tl.LopID           = tkqht.LopID AND tl.NienKhoa = @NienKhoa
               INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
               INNER JOIN dbo.tblMonHocLop            tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
               INNER JOIN dbo.tblMonHoc               tmh ON tmh.MonHocID      = tmhl.MonHocID
        WHERE
               tkqht.NienKhoa = @NienKhoa
          AND  tl.KhoiID       = @KhoiID
          AND
               (
                   @LopID IS NULL
              OR   tl.LopID        = @LopID
               )
          AND
               (
                   @MonHocID IS NULL
              OR   tmh.MonHocID    = @MonHocID
               )
          AND  tbdct.MaCotDiem IN ('S1_Mid_Total_Point', 'S1_Final_Total_Point', 'S2_Mid_Total_Point', 'S2_Final_Total_Point')
          AND  tkqht.KetQuaDanhGia_VI IS NOT NULL
          AND  tkqht.Enable    = 1
        GROUP BY
               tl.LopID
             , tl.TenLop
             , ths.HocSinhID
             , ths.Ho
             , ths.Ten
             , tmh.MonHocName
             , tmh.MonHocID
        HAVING
            -- Đảm bảo có điểm giữa kỳ và cuối kỳ
               MAX(CASE WHEN tbdct.MaCotDiem = 'S1_Mid_Total_Point' THEN 1 ELSE 0 END)   > 0
           AND MAX(CASE WHEN tbdct.MaCotDiem = 'S1_Final_Total_Point' THEN 1 ELSE 0 END) > 0
        ORDER BY
               tmh.MonHocName
             , ChenhLechDiem DESC;
    END;
    ELSE
    BEGIN
        SELECT n.NhomID               AS LopID
             , n.TenNhom              AS TenLop
             , ths.HocSinhID
             , ths.Ho + ' ' + ths.Ten AS HoTen
             , tmh.MonHocName
             , tmh.MonHocID
             -- Điểm giữa kỳ
             , MAX(   CASE
                           WHEN tbdct.MaCotDiem = 'S1_Mid_Total_Point' THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                           ELSE NULL
                      END
                  )                   AS DiemGK1
             -- Điểm cuối kỳ
             , MAX(   CASE
                           WHEN tbdct.MaCotDiem = 'S1_Final_Total_Point' THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                           ELSE NULL
                      END
                  )                   AS DiemCK1
             -- Chênh lệch điểm
             , MAX(   CASE
                           WHEN tbdct.MaCotDiem = 'S1_Final_Total_Point' THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                           ELSE NULL
                      END
                  ) - MAX(   CASE
                                  WHEN tbdct.MaCotDiem = 'S1_Mid_Total_Point' THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                                  ELSE NULL
                             END
                         )            AS ChenhLechDiem
        FROM
               dbo.tblKetQuaHocTap                    tkqht
               INNER JOIN dbo.tblHocSinh              ths ON ths.HocSinhID     = tkqht.HocSinhID
               INNER JOIN dbo.tblHocSinhNhom          thsn ON ths.HocSinhID    = thsn.HocSinhID and thsn.Enable = 1
               INNER JOIN dbo.tblNhom                 n ON n.NhomID            = tkqht.LopID and n.IsNhomLMS_GiaoBai = 0
               INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
               INNER JOIN dbo.tblMonHocLop            tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
               INNER JOIN dbo.tblMonHoc               tmh ON tmh.MonHocID      = tmhl.MonHocID
        WHERE
               tkqht.NienKhoa = @NienKhoa
          AND  n.KhoiID        = @KhoiID
          AND
               (
                   @LopID IS NULL
              OR   n.NhomID        = @LopID
               )
          AND
               (
                   @MonHocID IS NULL
              OR   tmh.MonHocID    = @MonHocID
               )
          AND  tbdct.MaCotDiem IN ('S1_Mid_Total_Point', 'S1_Final_Total_Point', 'S2_Mid_Total_Point', 'S2_Final_Total_Point')
          AND  tkqht.KetQuaDanhGia_VI IS NOT NULL
          AND  tkqht.Enable    = 1
        GROUP BY
               n.NhomID
             , n.TenNhom
             , ths.HocSinhID
             , ths.Ho
             , ths.Ten
             , tmh.MonHocName
             , tmh.MonHocID
        HAVING
            -- Đảm bảo có điểm giữa kỳ và cuối kỳ
               MAX(CASE WHEN tbdct.MaCotDiem = 'S1_Mid_Total_Point' THEN 1 ELSE 0 END)   > 0
           or MAX(CASE WHEN tbdct.MaCotDiem = 'S1_Final_Total_Point' THEN 1 ELSE 0 END) > 0
        ORDER BY
               tmh.MonHocName
             , ChenhLechDiem DESC;
    END;

END;