CREATE PROC [dbo].[spAPI_EL_Teacher_GetTeacherByMonHocID] 
    @MonHocID     INT
  , @AssignmentID INT
  , @HocKi        INT
  , @Sys_UserID   VARCHAR(9)
AS
BEGIN
    SET @Sys_UserID = dbo.fn_GetUser_LMS(@Sys_UserID);
    SELECT DISTINCT
           gv.GiaoVienID
         , CONCAT(gv.HoGV, ' ', gv.TenGV) AS HoTenGV
    FROM
           tblGiaoVienLop         gvl
           INNER JOIN tblGiaoVien gv ON gv.GiaoVienID = gvl.GiaoVienID
                                    AND gv.Enable     = 1
    WHERE
           MonHocID      = @MonHocID
      AND  NienKhoa       = dbo.fn_GetNienKhoa_HienTai()
      AND  gvl.Enable     = 1
      AND  gvl.GiaoVienID <> @Sys_UserID
      AND  gvl.HocKy      = @HocKi
      AND  (gvl.GiaoVienID NOT IN
           (
               SELECT GiaoVienID
               FROM
                      tblEL_Resoucre_TeacherPermissions
               WHERE
                      Enable = 1
                 AND 
                        AssignToClassID NOT IN
                                                 (
                                                     SELECT AssignToClassID
                                                     FROM
                                                            tblEL_AssignToClass
                                                     WHERE
                                                            AssignmentID = @AssignmentID
                                                       AND  IsDeleted     = 0
                                                 )
                    
           ) 
           OR
            -- Nếu chưa có AssignToClass nào cho AssignmentID này
        NOT EXISTS
        (
            SELECT 1
            FROM tblEL_AssignToClass
            WHERE AssignmentID = @AssignmentID
              AND IsDeleted = 0
        )
           
           );
END;
