--[dbo].[spAPI_ChiTieu_Get_By_MonHocID] 5, 2025
CREATE PROC [dbo].[spAPI_MucDo_Get_By_MonHocID]
    @MonHocID INT
  , @NienKhoa INT
AS
BEGIN
DECLARE @Table_MucDo_Color TABLE(
		TenMucDo nvarchar(20),
		Mau varchar(20)
   )
	DECLARE @CapID INT = 0
	SET @CapID = ( SELECT TOP 1 mh.CapID  FROM tblMonHoc mh WHERE mh.MonHocID = @MonHocID)
		IF(@CapID = 1)
		BEGIN	
			 INSERT INTO @Table_MucDo_Color VALUES
				(N'Chưa hoàn thành', 'red'),
				(N'Hoàn thành', 'warning'),
				(N'Tốt', 'green')
		END
		ELSE 
		BEGIN
			 INSERT INTO @Table_MucDo_Color VALUES
				(N'Không đạt', 'red'),
				(N'Đạt', 'yellow'),
				(N'Khá', 'blue'),
				(N'Tốt', 'green')
		END

    SELECT ct.MucDo_ID
         , mhl.MonHocLopID
         , ct.DiemMin
         , ct.DiemMax
         , ct.Prefix
         , ct.Suffix
         , mhl.LopNhomID
         , l.TenLop
         , tbc.TenMucDo
		 , tbc.Mau
    FROM
           tblMonHocLop            AS mhl
		   
           LEFT JOIN dbo.tbl_MucDo AS ct ON mhl.MonHocLopID = ct.MonHocLopID
                                         AND ct.Enable       = 1
			CROSS JOIN @Table_MucDo_Color tbc
           INNER JOIN dbo.tblLop    AS l ON mhl.LopNhomID    = l.LopID
                                        AND l.NienKhoa       = @NienKhoa
                                        AND l.Enable         = 1
    WHERE
           mhl.Enable  = 1
      AND  mhl.MonHocID = @MonHocID
    ORDER BY
           l.TenLop, tbc.Mau;
END;