-- [dbo].[spAPI_Unit_Get_By_MonID_Khoi] 1, '-3'
CREATE   PROC [dbo].[spAPI_Unit_Get_By_MonID_Khoi]
    @MonHocID INT
  , @KhoiID   INT
  , @NienKhoa INT
AS
BEGIN
    SELECT DISTINCT
           U.UnitID
         , U.UnitCode
         , U.UnitName
         , CONVERT(VARCHAR(10), U.ThoiGianDayBD, 103) ThoiGianDayBD_DMY
         , CONVERT(VARCHAR(10), U.ThoiGianDayKT, 103) ThoiGianDayKT_DMY
         , U.ThoiGianDayBD
         , U.ThoiGianDayKT
         , STUFF((
                     SELECT ', ' + B.MucTieuCode
                     FROM
                            dbo.tblMucTieuUnit B
                     WHERE
                            B.UnitID = MTU.UnitID
                       AND  B.Enable  = 1
                      order by B.Sort
                     FOR XML PATH('')
                 ), 1, 2, ''
                )                                     AS MT
         , U.TinhTrang
         , CASE
                WHEN U.TinhTrang = 0 THEN N'Đang mở'
                WHEN U.TinhTrang = 1 THEN N'Đã kết thúc'
           END                                        AS MoTaTinhTrang
         , CAST(U.Sort AS INT)                        AS Sort
    FROM
           dbo.tblUnit                  U
           LEFT JOIN dbo.tblMucTieuUnit MTU ON U.UnitID   = MTU.UnitID
                                           AND MTU.Enable = 1
    WHERE
           U.MonHocID = @MonHocID
      AND  U.KhoiID    = @KhoiID
      AND  U.NienKhoa  = @NienKhoa
      AND  U.Enable    = 1
    ORDER BY
           CAST(U.Sort AS INT);
END;
