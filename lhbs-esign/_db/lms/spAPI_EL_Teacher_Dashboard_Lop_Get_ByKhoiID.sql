CREATE PROC [dbo].[spAPI_EL_Teacher_Dashboard_Lop_Get_ByKhoiID]
    @KhoiID          INT
	, @HocKi INT
  , @NienKhoa        INT
  , @SYS_USERID      VARCHAR(9)
  , @SYS_SYSTEMRIGHT INT
AS
BEGIN

    SELECT @SYS_USERID      = SYS_USERID
         , @SYS_SYSTEMRIGHT = SYS_SystemRight
    FROM
           dbo.Table_GetUser_LMS(@SYS_USERID, @SYS_SYSTEMRIGHT);

	DECLARE @Table_MonHocID TABLE(MonHocID INT)
	DECLARE @Table_LopID TABLE(LopID VARCHAR(20))

	INSERT INTO @Table_MonHocID
	SELECT DISTINCT MonHocID FROM dbo.tblEL_GiaoVienLop
	WHERE GiaoVienID = @SYS_USERID AND Enable = 1 AND NienKhoa  = @NienKhoa AND HocKy = @HocKi
	UNION
	SELECT DISTINCT MonHocID FROM dbo.tblGiaoVienLop
	WHERE GiaoVienID = @SYS_USERID AND Enable = 1 AND NienKhoa  = @NienKhoa AND HocKy = @HocKi
    UNION
    SELECT rtp.MonHocID FROM tblEL_Resoucre_TeacherPermissions rtp
    WHERE rtp.Enable = 1 AND GiaoVienID = @SYS_USERID

	INSERT INTO @Table_LopID
	SELECT DISTINCT LopID FROM dbo.tblEL_GiaoVienLop
	WHERE GiaoVienID = @SYS_USERID AND Enable = 1 AND NienKhoa  = @NienKhoa AND HocKy = @HocKi
	UNION
	SELECT DISTINCT LopID FROM dbo.tblGiaoVienLop
	WHERE GiaoVienID = @SYS_USERID AND Enable = 1 AND NienKhoa  = @NienKhoa AND HocKy = @HocKi
    UNION
    SELECT mhl.LopNhomID FROM tblEL_Resoucre_TeacherPermissions rtp
    INNER JOIN tblEL_AssignToClass atc on atc.AssignToClassID = rtp.AssignToClassID and atc.IsDeleted = 0
    INNER JOIN tblMonHocLop mhl on atc.MonHocLopID = mhl.MonHocLopID and mhl.Enable =1
    WHERE rtp.Enable = 1 AND GiaoVienID = @SYS_USERID
    UNION
    SELECT DISTINCT mhl.LopNhomID
    FROM tblEL_Resoucre_TeacherPermissions rtp
    INNER JOIN tblMonHocLop mhl ON mhl.MonHocID = rtp.MonHocID
                               AND mhl.NienKhoa = @NienKhoa
                               AND mhl.Enable = 1
    WHERE rtp.Enable = 1
      AND rtp.GiaoVienID = @SYS_USERID
      AND rtp.PermissionScope = 'SUBJECT'
      AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa)

    -- Tính toán status cho từng assignment trước
    ;WITH AssignmentStatus AS (
        SELECT 
            atc.AssignToClassID,
            atc.AssignmentID,
            mhl.LopNhomID,
            atc.DueDate,
            CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM dbo.tblEL_Submissions s 
                    WHERE s.AssignToClassID = atc.AssignToClassID 
                      AND s.SubmissionStatus = 2 
                      AND s.Score IS NULL
                      AND s.IsDeleted = 0
                ) THEN 1 
                ELSE 0 
            END AS HasPendingSubmission
        FROM dbo.tblEL_AssignToClass atc
        INNER JOIN dbo.tblEL_Assignments asm 
            ON asm.AssignmentID = atc.AssignmentID
           AND ISNULL(asm.IsDev, 0) <> 1
           AND asm.IsDeleted = 0
        INNER JOIN dbo.tblMonHocLop mhl 
            ON mhl.MonHocLopID = atc.MonHocLopID
           AND mhl.NienKhoa = @NienKhoa
           AND mhl.MonHocID IN (SELECT MonHocID FROM @Table_MonHocID)
           AND mhl.LopNhomID IN (SELECT LopID FROM @Table_LopID)
           AND mhl.Enable = 1
        LEFT JOIN dbo.tblLop l 
            ON l.LopID = mhl.LopNhomID
           AND l.NienKhoa = @NienKhoa
           AND l.Enable = 1
        LEFT JOIN dbo.tblNhom n 
            ON n.NhomID = mhl.LopNhomID
           AND n.NienKhoa = @NienKhoa
           AND n.Enable = 1
           AND n.MonHocID = mhl.MonHocID
        WHERE atc.IsDeleted = 0 
          AND (
              atc.CreateUser = @SYS_USERID
              OR @SYS_SYSTEMRIGHT IN (3, 5, 9)
              OR EXISTS (
                  SELECT 1 
                  FROM tblEL_Resoucre_TeacherPermissions 
                  WHERE Enable = 1 
                    AND GiaoVienID = @SYS_USERID
                    AND AssignToClassID = atc.AssignToClassID
              )
              OR EXISTS (
                  -- Quyền SUBJECT mở quyền xem tổng hợp theo môn/niên khóa.
                  SELECT 1
                  FROM tblEL_Resoucre_TeacherPermissions rtp
                  WHERE rtp.Enable = 1
                    AND rtp.GiaoVienID = @SYS_USERID
                    AND rtp.PermissionScope = 'SUBJECT'
                    AND rtp.MonHocID = mhl.MonHocID
                    AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa)
              )
          )
          AND (l.KhoiID = @KhoiID OR n.KhoiID = @KhoiID)
    )
    SELECT 
        a.LopNhomID,
        ISNULL(l.TenLop, n.TenNhom) AS TenLop,
        COUNT(DISTINCT a.AssignmentID) AS TongBT,
        SUM(CASE 
            WHEN a.HasPendingSubmission = 1 AND a.DueDate > GETDATE() 
            THEN 1 
            ELSE 0 
        END) AS BaiTapCanCham_PendingGrading,
        SUM(CASE 
            WHEN a.DueDate < GETDATE() 
            THEN 1 
            ELSE 0 
        END) AS BaiTapQuaHan_Overdue,
        SUM(CASE 
            WHEN a.DueDate >= GETDATE() AND a.HasPendingSubmission = 0
            THEN 1 
            ELSE 0 
        END) AS BaiTapSapToi_Upcoming
    FROM AssignmentStatus a
    LEFT JOIN dbo.tblLop l 
        ON l.LopID = a.LopNhomID
       AND l.NienKhoa = @NienKhoa
       AND l.Enable = 1
    LEFT JOIN dbo.tblNhom n 
        ON n.NhomID = a.LopNhomID
       AND n.NienKhoa = @NienKhoa
       AND n.Enable = 1
    GROUP BY a.LopNhomID, ISNULL(l.TenLop, n.TenNhom);
END;
