CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetTeacherPermissions_ByAssignment]
    @AssignmentID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT
           tp.GiaoVienID,
           CONCAT(gv.HoGV, ' ', gv.TenGV) AS HoTenGV,
           tp.AssignToClassID,
           tp.AssignToStudentID
    FROM dbo.tblEL_Resoucre_TeacherPermissions tp
    LEFT JOIN dbo.tblEL_AssignToClass atc ON atc.AssignToClassID = tp.AssignToClassID AND atc.IsDeleted = 0
    LEFT JOIN dbo.tblEL_AssignToStudent ats ON ats.AssignToStudentID = tp.AssignToStudentID AND ats.IsDeleted = 0
    LEFT JOIN dbo.tblGiaoVien gv ON gv.GiaoVienID = tp.GiaoVienID
    WHERE (atc.AssignmentID = @AssignmentID OR ats.AssignmentID = @AssignmentID)
      AND (tp.Enable IS NULL OR tp.Enable = 1);
END;