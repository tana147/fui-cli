CREATE PROC [dbo].[spAPI_MonHoc_QLD_GetByKhoi]
@NienKhoa INT,
@KhoiID int
AS 
BEGIN
    IF (@KhoiID >= 10)
    BEGIN
        SELECT DISTINCT
               mh.MonHocID
             , mh.MonHocName
			 , mh.MonHocCode
			 , mh.Sort
        FROM
               dbo.tblMonHocLop         AS mhl
               INNER JOIN dbo.tblLop    AS l ON l.LopID      = mhl.LopNhomID AND l.NienKhoa = @NienKhoa
                                            AND l.Enable     = 1
                                            AND l.KhoiID     = @KhoiID
               INNER JOIN dbo.tblMonHoc AS mh ON mh.MonHocID = mhl.MonHocID
        WHERE
               mhl.Enable  = 1
          AND  mhl.NienKhoa = @NienKhoa
        UNION
        SELECT DISTINCT
               mh.MonHocID
             , mh.MonHocName
			 , mh.MonHocCode
			 , mh.Sort
        FROM
               dbo.tblMonHocLop         AS mhl
               LEFT JOIN dbo.tblLop     AS l ON l.LopID      = mhl.LopNhomID AND l.NienKhoa = @NienKhoa
                                            AND l.Enable     = 1
                                            AND l.KhoiID     = @KhoiID
               INNER JOIN dbo.tblMonHoc AS mh ON mh.MonHocID = mhl.MonHocID
        WHERE
               mhl.Enable     = 1
          AND  mhl.ChiaTheoLop = 0
          AND  mhl.NienKhoa    = @NienKhoa
		  ORDER BY mh.Sort

    END;
    ELSE
    BEGIN
        SELECT DISTINCT
               mh.MonHocID
             , mh.MonHocName
			 , mh.MonHocCode
			 , mh.Sort

        FROM
               dbo.tblMonHocLop         AS mhl
               INNER JOIN dbo.tblLop    AS l ON l.LopID      = mhl.LopNhomID AND l.NienKhoa = @NienKhoa
                                            AND l.Enable     = 1
                                            AND l.KhoiID     = @KhoiID
               INNER JOIN dbo.tblMonHoc AS mh ON mh.MonHocID = mhl.MonHocID
        WHERE
               mhl.Enable     = 1
          AND  mhl.NienKhoa    = @NienKhoa
		  ORDER BY mh.Sort
    END;
END
