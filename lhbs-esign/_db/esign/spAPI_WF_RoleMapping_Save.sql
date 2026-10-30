CREATE PROCEDURE [dbo].[spAPI_WF_RoleMapping_Save]
    @RoleMappingID INT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RoleCode VARCHAR(50) = JSON_VALUE(@sys_RawData, '$.RoleCode');
    DECLARE @RoleName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.RoleName');
    DECLARE @DefaultPersonID VARCHAR(9) = JSON_VALUE(@sys_RawData, '$.DefaultPersonID');
    DECLARE @DefaultPersonName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.DefaultPersonName');
    DECLARE @DepartmentName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.DepartmentName');
    DECLARE @IsActive BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.IsActive') AS BIT), 1);

    IF ISNULL(@RoleCode, '') = '' OR ISNULL(@RoleName, '') = ''
    BEGIN
        RAISERROR(N'RoleCode và RoleName không được để trống.', 16, 1);
        RETURN;
    END

    IF @RoleMappingID = 0
    BEGIN
        INSERT INTO dbo.tblWF_RoleMapping
        (
            RoleCode, RoleName, DefaultPersonID, DefaultPersonName, DepartmentName, IsActive,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        VALUES
        (
            @RoleCode, @RoleName, @DefaultPersonID, @DefaultPersonName, @DepartmentName, @IsActive,
            @sys_UserID, GETDATE(), NULL, NULL, 0
        );

        SET @RoleMappingID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.tblWF_RoleMapping
        SET RoleCode = @RoleCode,
            RoleName = @RoleName,
            DefaultPersonID = @DefaultPersonID,
            DefaultPersonName = @DefaultPersonName,
            DepartmentName = @DepartmentName,
            IsActive = @IsActive,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE RoleMappingID = @RoleMappingID
          AND [Enable] = 0;
    END

    SELECT
        Message = N'Lưu role mapping thành công.',
        RoleMappingID = @RoleMappingID;
END
