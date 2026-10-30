CREATE PROC [dbo].[spAPI_HocSinhLop_GetByLopIDList]
    @AssignmentID INT
  , @DSLopID      NVARCHAR(MAX)
  , @NienKhoa     INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @NienKhoa IS NULL OR @NienKhoa = 0
    BEGIN
        SET @NienKhoa = dbo.fn_GetNienKhoa_HienTai();
    END;

    DECLARE @DSLop TABLE
    (
        LopID NVARCHAR(20)
    );
    INSERT INTO @DSLop
    (
        LopID
    )
    SELECT Value
    FROM
           OPENJSON(@DSLopID);

    SELECT *
    FROM
           (
               SELECT hsl.HSLopID
                    , hsl.HocSinhID
                    , hsl.LopID AS LopID
                    , hsl.SoDanhBo
                    , hsl.Enable
                    , hs.Ho
                    , hs.Ten
                    , hs.TinhTrang
                    , hs.TenTinhTrang
                    , hs.EnglishName
                    , l.TenLop
                    , CASE
                           WHEN EXISTS
                                (
                                    SELECT 1
                                    FROM
                                           dbo.tblEL_AssignToStudent
                                    WHERE
                                           AssignmentID = @AssignmentID
                                      AND  HocSinhID     = hsl.HocSinhID
                                      AND  IsDeleted     = 0
                                ) THEN 1
                           ELSE 0
                      END       AS Is_Assigned
					  , CAST(0 AS bit) as IsNhom 
               FROM
                      dbo.tblHocSinhLop         hsl
                      INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID
                      INNER JOIN dbo.tblLop     l ON l.LopID       = hsl.LopID
                                                 AND l.Enable      = 1
                                                 AND l.NienKhoa    = @NienKhoa
               AND hsl.NienKhoa = l.NienKhoa
        WHERE
                      CAST(hsl.LopID AS NVARCHAR(20))IN
                      (
                          SELECT LopID
                          FROM
                                 @DSLop
                      )
                 AND  hsl.NienKhoa = @NienKhoa
                 AND  hsl.Enable   = 1
                 AND  hs.TinhTrang = 0
               UNION
               SELECT hsn.HSNhomID
                    , hsn.HocSinhID
                    , hsn.NhomID AS LopID
                    , hsn.SoDanhBo
                    , hsn.Enable
                    , hs.Ho
                    , hs.Ten
                    , hs.TinhTrang
                    , hs.TenTinhTrang
                    , hs.EnglishName
                    , n.TenNhom  AS TenLop
                    , CASE
                           WHEN EXISTS
                                (
                                    SELECT 1
                                    FROM
                                           dbo.tblEL_AssignToStudent
                                    WHERE
                                           AssignmentID = @AssignmentID
                                      AND  HocSinhID     = hsn.HocSinhID
                                      AND  IsDeleted     = 0
                                ) THEN 1
                           ELSE 0
                      END        AS Is_Assigned
					  , CAST(1 AS bit) as IsNhom 
               FROM
                      dbo.tblHocSinhNhom        hsn
                      INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsn.HocSinhID
                      INNER JOIN dbo.tblNhom    n ON n.NhomID      = hsn.NhomID
                                                 AND n.Enable      = 1
                                                 AND n.NienKhoa    = @NienKhoa
               WHERE
                      CAST(hsn.NhomID AS NVARCHAR(20))IN
                      (
                          SELECT LopID
                          FROM
                                 @DSLop
                      )
                 AND  hsn.Enable   = 1
                 AND  hs.TinhTrang = 0
           ) AS x
    ORDER BY
           x.TenLop
         , x.SoDanhBo
         , x.Ten;
END;