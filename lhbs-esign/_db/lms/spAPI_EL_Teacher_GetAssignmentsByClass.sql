CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetAssignmentsByClass] 
    @sys_UserID			VARCHAR(9),
	@HocKi INT,
	@sys_SystemRight	INT,
    @LopID VARCHAR(20), -- Đây có thể là LopID hoặc NhomID
	@MonHocID INT,
	@NienKhoa INT
AS
BEGIN
 
	select 
		@sys_UserID			= SYS_USERID,
		@sys_SystemRight	= SYS_SystemRight 
	from Table_GetUser_LMS(@sys_UserID, @sys_SystemRight)

    IF (@NienKhoa IS NULL OR @NienKhoa = 0)
        SET @NienKhoa = dbo.fn_GetNienKhoa_HienTai();

    -- CTE 1: Các môn học của giáo viên dạy
    DECLARE @MonHocLopIDs TABLE (MonHocLopID INT);
    INSERT INTO @MonHocLopIDs (MonHocLopID)
    SELECT MonHocLopID FROM tblGiaoVienLop gvl 
		inner join tblMonHocLop mhl on mhl.MonHocID = gvl.MonHocID and mhl.LopNhomID = gvl.LopID and gvl.NienKhoa = @NienKhoa
    WHERE GiaoVienID = @sys_UserID  AND gvl.Enable = 1 AND gvl.HocKy = @HocKi

    -- Lấy danh sách các lần giao bài một cách trực tiếp và chính xác
    ;WITH CTE  AS (SELECT 
        atc.AssignToClassID,
        a.Title AS AssignmentTitle,
		atc.AssignmentConfig,
        atc.LimitAssigned,
        atc.CreateTime,
        atc.AssignmentID,
		atc.Is_Full_Quiz
    FROM 
        dbo.tblEL_AssignToClass atc
    JOIN 
        dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    JOIN 
        dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID
    WHERE 
        mhl.LopNhomID = @LopID
		AND ISNULL(a.MonHocID, mhl.MonHocID) = @MonHocID
        AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR mhl.NienKhoa = @NienKhoa)
        AND atc.ResourceType = 'ASSIGNMENT'
        AND atc.IsDeleted = 0
        AND a.IsDeleted = 0
        -- Vẫn giữ điều kiện lọc theo giáo viên tạo để tăng cường bảo mật
        AND (atc.CreateUser = @sys_UserID 
                OR @sys_SystemRight in (3,5,9)
                 -- GV dạy lơp thây được bài được giao cho lớp từ GV khác
                OR 
                atc.MonHocLopID in (SELECT * FROM @MonHocLopIDs)
                OR 
                atc.AssignToClassID in (SELECT AssignToClassID FROM tblEL_Resoucre_TeacherPermissions where Enable = 1 AND GiaoVienID = @sys_UserID)
                OR EXISTS (
                    -- Quyền SUBJECT mở quyền xem các bài thuộc môn trong niên khóa,
                    -- kể cả bài được tạo sau thời điểm phân quyền.
                    SELECT 1
                    FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
                    WHERE rtp.Enable = 1
                      AND rtp.GiaoVienID = @sys_UserID
                      AND rtp.PermissionScope = 'SUBJECT'
                      AND rtp.MonHocID = ISNULL(a.MonHocID, mhl.MonHocID)
                      AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa)
                )
             )
   )

        SELECT * FROM CTE ORDER BY CreateTime DESC;
END
