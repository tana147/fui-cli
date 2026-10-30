CREATE FUNCTION [dbo].[fn_GetUser_LMS]
(
    @SYS_USERID VARCHAR(9)
)
RETURNS VARCHAR(9)
AS
BEGIN
    -- Chuẩn hóa các tài khoản proxy về một tài khoản nghiệp vụ thống nhất.
    -- Không hard-code việc này ở từng API vì sẽ làm cùng một giáo viên có
    -- CreateUser/UpdateUser/GradedByTeacherID khác nhau tùy đường đi.
    IF @SYS_USERID IN ('NA0000022', 'NV0000134')
    BEGIN
        DECLARE @userid VARCHAR(9) = '';
        SELECT @userid = SYS_USERID
        FROM
               tblEL_User_Assign
        WHERE IsActive = 1
        ORDER BY SYS_USERID;

        SET @SYS_USERID = @userid;
    END
    ELSE IF @SYS_USERID = 'NV0000888'
    BEGIN
        -- Giữ tương thích với các API cũ đã coi NV0000888 là NV0000677.
        SET @SYS_USERID = 'NV0000677';
    END;

    RETURN @SYS_USERID;
END;
