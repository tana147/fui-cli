-- FILE: spAPI_EL_Teacher_GetAssignmentsByClass.sql
-- =================================================================================
-- Description:    Lấy danh sách các bài tập đã được giao cho một lớp cụ thể.
--                 Sử dụng cho bộ lọc trên trang Tình trạng nộp bài.
-- API Endpoint:   POST lms/el_teacher_getassignmentsbyclass
-- Ví dụ Body:     { "LopID": "10A1" }
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetAssignmentsByClass_OLD]
    @sys_UserID VARCHAR(9),
    @LopID VARCHAR(10),
	@MonHocID INT
AS
BEGIN
    IF @sys_UserID = 'NA0000022'
	BEGIN
		SET @sys_UserID = 'NV0000907'
	END
    DECLARE @NienKhoa_HienTai INT = dbo.fn_GetNienKhoa_HienTai();

    -- === Kiểm tra quyền: Giáo viên có thực sự dạy lớp này không? ===
    IF NOT EXISTS (
        SELECT 1 
        FROM dbo.tblGiaoVienLop 
        WHERE GiaoVienID = @sys_UserID 
          AND LopID = @LopID 
          AND NienKhoa = @NienKhoa_HienTai 
          AND Enable = 1
    )
    BEGIN
        -- Trả về tập rỗng nếu không có quyền
        RETURN;
    END

    -- === Lấy danh sách các lần giao bài ===
    SELECT 
        atc.AssignToClassID,
        a.Title AS AssignmentTitle
    FROM 
        dbo.tblEL_AssignToClass atc
    JOIN 
        dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    JOIN 
        dbo.tblEL_Assignments a ON atc.AssignmentID = a.AssignmentID
    WHERE 
        mhl.LopNhomID = @LopID
		AND mhl.MonHocID = @MonHocID
        AND atc.IsDeleted = 0
        AND a.IsDeleted = 0
        -- Chỉ lấy các bài tập do chính giáo viên này tạo để tăng cường bảo mật
        AND a.CreateUser = @sys_UserID 
    ORDER BY 
        atc.CreateTime DESC;

END
