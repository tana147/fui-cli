-- 6. Cập nhật Procedure spAPI_Alert_Get để loại trừ những thông báo đã đọc và lọc theo UserRight
CREATE   PROCEDURE [dbo].[spAPI_Alert_Get]
    @AlertID            INT,
    @CapID              INT,
    @NienKhoa           INT,
    @TypeAlert          VARCHAR(100),
    @IsAdminQuery       INT,  -- 1: Bỏ qua lọc quyền để admin xem hết quản lý
    @sys_UserID         VARCHAR(20), -- Tự động tiêm từ session backend
    @sys_GroupID        INT,  -- Tự động tiêm từ session backend (1: GV, 2: PH, 3: HS)
    @sys_DepartmentID   VARCHAR(9), -- Tự động tiêm từ session backend
    @sys_SystemRight    INT,  -- Tự động tiêm từ session backend (1, 2, 3, 4, 5, 9)
    @sys_FunctionRight  VARCHAR(2000)  -- Tự động tiêm từ session backend
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.AlertID, a.TypeAlert, a.ContentAlert, a.DateAlert,
        a.CapID, a.NienKhoa, a.Enable,
        a.CreateUser, a.CreateTime,
        a.UpdateUser, a.UpdateTime,
        a.UserRight,
        CASE WHEN r.AlertID IS NOT NULL THEN 1 ELSE 0 END AS IsRead
    FROM tblAlert a
    LEFT JOIN tblAlertRead r ON a.AlertID = r.AlertID AND r.UserID = @sys_UserID
    WHERE
        (ISNULL(@AlertID, 0) = 0 OR a.AlertID = @AlertID)
        -- NienKhoa = 0 là alert dùng chung toàn hệ thống, vẫn phải hiện khi người dùng đang ở niên khóa cụ thể.
        AND (ISNULL(@NienKhoa, 0) = 0 OR a.NienKhoa = @NienKhoa OR a.NienKhoa = 0)
        AND (ISNULL(@TypeAlert, '') = '' OR a.TypeAlert = @TypeAlert)
        AND (ISNULL(@CapID, 0) = 0 OR a.CapID = @CapID OR a.CapID = 0)
        AND a.Enable = 1
        -- Lọc theo đối tượng nhận thông báo (UserRight)
        AND (
            @IsAdminQuery = 1
            OR a.UserRight IS NULL
            OR a.UserRight = ''
            OR a.UserRight = 'ALL'
            OR (a.UserRight = 'STUDENT' AND @sys_GroupID = 3)
            OR (a.UserRight = '3' AND @sys_GroupID = 3)
            OR (a.UserRight = 'TEACHER' AND @sys_GroupID = 1)
            -- Alert nhắm đích danh một tài khoản giáo viên (ví dụ tblLop.GVCN).
            OR (
                NULLIF(LTRIM(RTRIM(@sys_UserID)), '') IS NOT NULL
                AND UPPER(LTRIM(RTRIM(a.UserRight))) = UPPER(LTRIM(RTRIM(@sys_UserID)))
            )
            -- SR4/SR9 là quyền toàn hệ thống, không phụ thuộc GroupID của tài khoản.
            OR (a.UserRight = '4' AND @sys_SystemRight = 4)
            OR (a.UserRight = '9' AND @sys_SystemRight = 9)
            -- Các mã quyền còn lại chỉ áp dụng cho nhóm Giáo viên.
            OR (@sys_GroupID = 1 AND (
                (a.UserRight = '1' AND @sys_SystemRight = 1)
                OR (a.UserRight = '2' AND @sys_SystemRight = 2)
                OR (a.UserRight = '3' AND @sys_SystemRight = 3)
                OR (a.UserRight = '5' AND @sys_SystemRight = 5)
            ))
            -- Phục vụ màn hình quản lý admin-alert (khi không có sys_UserID / sys_GroupID)
            OR (ISNULL(@sys_UserID, '') = '' AND ISNULL(@sys_GroupID, 0) = 0)
        )
    ORDER BY a.DateAlert DESC;
END
