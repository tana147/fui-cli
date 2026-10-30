--exec [dbo].[spAPI_DashboardDiemTrungBinh_Get] 2024,6,46
--exec [dbo].[spAPI_DashboardDiem_Mean_Get] 2024,6,46
CREATE PROCEDURE [dbo].[spAPI_DashboardDiem_Mean_Get] -- 2024,6,46
    @NienKhoa INT
  , @KhoiID   INT
  , @MonHocID INT
AS
BEGIN;
    WITH DataWithRanks AS
    (
        SELECT tl.LopID
             , tl.TenLop
             , tmh.MonHocName
             , tmh.MonHocCode
             , tbdct.MaCotDiem
             , CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) AS KetQuaDanhGia
             , ROW_NUMBER() OVER (PARTITION BY tl.LopID
                                             , tbdct.MaCotDiem
                                  ORDER BY
                                      CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                                 )                            AS RowNum
             , COUNT(*) OVER (PARTITION BY tl.LopID
                                         , tbdct.MaCotDiem
                             )                                AS TotalRows
        FROM
               dbo.tblKetQuaHocTap                    tkqht
               INNER JOIN dbo.tblLop                  tl ON tl.LopID           = tkqht.LopID AND tl.NienKhoa = @NienKhoa
               INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
               INNER JOIN dbo.tblMonHocLop            tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
               INNER JOIN dbo.tblMonHoc               tmh ON tmh.MonHocID      = tmhl.MonHocID
        WHERE
               tkqht.NienKhoa                   = @NienKhoa
          AND  tl.KhoiID                         = @KhoiID
          AND  tmh.MonHocID                      = @MonHocID
          AND  tbdct.MaCotDiem IN ('S1_Mid_Total_Point', 'S1_Final_Total_Point', 'DiemTB_HK1')
          AND  ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1
          AND  tkqht.Enable                      = 1
    )
    SELECT LopID
         , TenLop
         , MonHocName
         , MonHocCode
         , MAX(   CASE
                       WHEN MaCotDiem = 'S1_Mid_Total_Point'
                        AND TotalRows % 2 = 1
                        AND RowNum = (TotalRows + 1) / 2 THEN KetQuaDanhGia
                       WHEN MaCotDiem = 'S1_Mid_Total_Point'
                        AND TotalRows % 2 = 0
                        AND RowNum IN (TotalRows / 2, TotalRows / 2 + 1) THEN KetQuaDanhGia
                       ELSE NULL
                  END
              ) AS DiemGiua_HK1
         , MAX(   CASE
                       WHEN MaCotDiem = 'S1_Final_Total_Point'
                        AND TotalRows % 2 = 1
                        AND RowNum = (TotalRows + 1) / 2 THEN KetQuaDanhGia
                       WHEN MaCotDiem = 'S1_Final_Total_Point'
                        AND TotalRows % 2 = 0
                        AND RowNum IN (TotalRows / 2, TotalRows / 2 + 1) THEN KetQuaDanhGia
                       ELSE NULL
                  END
              ) AS DiemCuoi_HK1
         , MAX(   CASE
                       WHEN MaCotDiem = 'DiemTB_HK1'
                        AND TotalRows % 2 = 1
                        AND RowNum = (TotalRows + 1) / 2 THEN KetQuaDanhGia
                       WHEN MaCotDiem = 'DiemTB_HK1'
                        AND TotalRows % 2 = 0
                        AND RowNum IN (TotalRows / 2, TotalRows / 2 + 1) THEN KetQuaDanhGia
                       ELSE NULL
                  END
              ) AS DiemTB_HK1
    FROM
           DataWithRanks
    GROUP BY
           LopID
         , TenLop
         , MonHocName
         , MonHocCode
    ORDER BY
           LopID;

END;