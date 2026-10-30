-- FILE: spAPI_EL_Teacher_GetSubjectsByClass.sql
-- =================================================================================
-- Description:    Lấy danh sách các môn học mà giáo viên dạy trong một lớp cụ thể.
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetSubjectsByClass_OLD]
    @sys_UserID VARCHAR(9),
    @LopID VARCHAR(10)
AS
BEGIN
	IF @sys_UserID = 'NA0000022'
	BEGIN
		SET @sys_UserID = 'NV0000907'
	END
    DECLARE @NienKhoa_HienTai INT = dbo.fn_GetNienKhoa_HienTai();

    SELECT DISTINCT
        gvl.MonHocID,
        mh.MonHocName
    FROM dbo.tblGiaoVienLop gvl
    JOIN dbo.tblMonHoc mh ON gvl.MonHocID = mh.MonHocID
    WHERE gvl.GiaoVienID = @sys_UserID
      AND gvl.LopID = @LopID
      AND gvl.NienKhoa = @NienKhoa_HienTai
      AND gvl.Enable = 1
    ORDER BY mh.MonHocName;
END
