
CREATE FUNCTION [dbo].[Table_GetUser_LMS]
(
		@SYS_USERID			VARCHAR(9)
	,	@SYS_SystemRight	INT
)
RETURNS @Result TABLE
(
    SYS_USERID		VARCHAR(9),
    SYS_SystemRight INT
)
AS
BEGIN
	DECLARE @userid VARCHAR(9) = ''
	DECLARE @sys_right INT = 0
    -- Phải dùng cùng bảng ánh xạ với fn_GetUser_LMS và các API ghi/chấm.
    -- Nếu mỗi API tự đổi mã riêng, dữ liệu quyền và người thao tác sẽ lệch nhau.
    IF @SYS_USERID IN ('NA0000022', 'NV0000134')
    BEGIN
		SELECT 
			@userid			= SYS_USERID			,
			@sys_right	= SYS_SystemRight	
		FROM tblEL_User_Assign
		WHERE IsActive = 1
        ORDER BY SYS_USERID;

		SET @SYS_USERID				 = @userid
		SET	@SYS_SystemRight		 = @sys_right
    END
    ELSE IF @SYS_USERID = 'NV0000888'
    BEGIN
        -- Ánh xạ mã nghiệp vụ, nhưng giữ quyền truyền vào như hành vi cũ.
        SET @SYS_USERID = 'NV0000677';
    END;

    INSERT INTO @Result (SYS_USERID, SYS_SystemRight)
    VALUES (@SYS_USERID, @sys_SystemRight);

    RETURN;
END;
