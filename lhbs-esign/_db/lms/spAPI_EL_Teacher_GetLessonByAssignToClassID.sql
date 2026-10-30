CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetLessonByAssignToClassID]
	  @AssignToClassID BIGINT,
    @sys_UserID VARCHAR(9),
    @sys_SystemRight int
AS
BEGIN
    DECLARE @NienKhoa INT;
	SELECT @sys_UserID = SYS_USERID, @sys_SystemRight= SYS_SystemRight FROM dbo.Table_GetUser_LMS(@sys_UserID,@sys_SystemRight)
      DECLARE @LopHoacNhomID VARCHAR(100);
	 DECLARE @LessonID_Check INT; 

    -- Bước 1: Lấy ID của Lớp/Nhóm và kiểm tra quyền 
    SELECT 
        @LessonID_Check = atc.ResourceID, 
        @LopHoacNhomID = mhl.LopNhomID,
        @NienKhoa = mhl.NienKhoa
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    WHERE atc.AssignToClassID = @AssignToClassID AND (atc.CreateUser = @sys_UserID OR @sys_SystemRight in (3,5,9)) and atc.IsDeleted = 0;

    DECLARE @TenLopNhom VARCHAR(20);

SELECT TOP 1 @TenLopNhom = TenLopNhom
FROM (
    SELECT TenLop AS TenLopNhom FROM tblLop WHERE LopID = @LopHoacNhomID AND NienKhoa = @NienKhoa
    UNION ALL
    SELECT TenNhom as TenLopNhom FROM tblNhom WHERE NhomID = @LopHoacNhomID AND NienKhoa = @NienKhoa
) t;

    IF @LessonID_Check IS NULL
    BEGIN
        RAISERROR(N'[Unauthorized] Không tìm thấy lần giao bài hoặc bạn không có quyền xem.', 16, 1);
        RETURN;
    END
   SELECT *,@TenLopNhom AS TenLopNhom  FROM tblEL_Lessons where (CreateUser = @sys_UserID OR @sys_SystemRight in (3,5,9)) and IsDeleted = 0 and LessonID = @LessonID_Check
END