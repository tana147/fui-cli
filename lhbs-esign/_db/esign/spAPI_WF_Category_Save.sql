CREATE PROCEDURE [dbo].[spAPI_WF_Category_Save]
    @sys_UserID    VARCHAR(9),
    @CategoryID    INT = 0,
    @Code          NVARCHAR(50),
    @Name          NVARCHAR(255),
    @Icon          NVARCHAR(100) = NULL,
    @Color         NVARCHAR(50) = NULL,
    @SortOrder     INT = 0,
    @Description   NVARCHAR(500) = NULL, -- Virtual parameter to avoid SAPI mapping error
    @IsActive      BIT = 1               -- Maps directly to Enable column
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate fields
    IF ISNULL(@Code, '') = '' BEGIN RAISERROR(N'Mã category không được để trống.', 16, 1); RETURN; END
    IF ISNULL(@Name, '') = '' BEGIN RAISERROR(N'Tên category không được để trống.', 16, 1); RETURN; END

    -- Check for duplicate Code (only among active ones: Enable=1)
    IF EXISTS (SELECT 1 FROM dbo.tblWF_Category WHERE [Enable] = 1 AND Code = @Code AND CategoryID <> @CategoryID)
    BEGIN 
        RAISERROR(N'Mã category đã tồn tại.', 16, 1); 
        RETURN; 
    END

    -- Route to INSERT or UPDATE
    IF @CategoryID = 0
    BEGIN
        INSERT INTO dbo.tblWF_Category
            (Code, Name, Icon, Color, SortOrder, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable])
        VALUES
            (@Code, @Name, @Icon, @Color, @SortOrder,
             @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), @IsActive);

        SET @CategoryID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.tblWF_Category
        SET Code        = @Code,
            Name        = @Name,
            Icon        = @Icon,
            Color       = @Color,
            SortOrder   = @SortOrder,
            UpdateUser  = @sys_UserID,
            UpdateTime  = GETDATE(),
            [Enable]    = @IsActive
        WHERE CategoryID = @CategoryID;
    END

    SELECT Message = N'Lưu nhóm thành công.', CategoryID = @CategoryID;
END
