--[dbo].[spAPI_ChiTieu_C1_Get] 2025
CREATE PROC [dbo].[spAPI_ChiTieu_C2_C3_Get] @NienKhoa INT
AS
BEGIN
    DECLARE @Table_MonHocID TABLE
    (
        KhoiID    INT
      , MonHocID  INT
      , CapID INT
    );

    INSERT @Table_MonHocID
    SELECT DISTINCT
           l.KhoiID
         , mhl.MonHocID
		 , l.CapID
      
    FROM
           dbo.tblMonHocLop      mhl
           INNER JOIN dbo.tblLop l ON l.Enable   = mhl.Enable
                                  AND l.CapID    IN (2,3)
                                  AND l.NienKhoa = @NienKhoa
    WHERE
           mhl.Enable  = 1
      AND  mhl.NienKhoa = @NienKhoa
      AND  mhl.MonHocID IN (   
		56,
		47,
		73,
		74,
		72,
		46,
		55,
		71,
		65,
		65,
		60,
		52 ,
		91  ,
		88	,
		97	,
		103	,
		104	,
		102	,
		76	,
		86	,
		101	,
		85	,
		100	,
		79	,
		84,
		58	, --16	2	JA	JA
		105 --16	3	JA	JA
	 )

    SELECT ISNULL(ct.ChiTieuID, 0)        AS ChiTieuID
         , t.KhoiID
         , t.MonHocID
         , mh.TenMonHoc_HienThi
         , ISNULL(ct.NienKhoa, @NienKhoa) AS NienKhoa
         , ct.ChiTieu_Tot
         , ct.ChiTieu_Kha
         , ct.ChiTieu_Dat
         , ct.ChiTieu_ChuaDat
		 , t.CapID
    FROM
           @Table_MonHocID             AS t
           INNER JOIN dbo.tblMonHoc    AS mh ON mh.MonHocID = t.MonHocID
                                            AND mh.Enable   = 1
           INNER JOIN dbo.tblChiTieu_C2 AS ct ON t.MonHocID  = ct.MonHocID
                                            AND t.KhoiID    = ct.KhoiID
                                            AND ct.NienKhoa = @NienKhoa
    ORDER BY
           t.KhoiID
         , mh.Sort;
END;










