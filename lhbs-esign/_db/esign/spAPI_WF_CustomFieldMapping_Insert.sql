-- ------------------------------------------------------------
-- 3. INSERT
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[spAPI_WF_CustomFieldMapping_Insert]
    @sys_UserID    VARCHAR(9),
    @CategoryID    INT,
    @FieldName     NVARCHAR(100),
    @FieldLabel    NVARCHAR(255),
    @FieldType     NVARCHAR(50),
    @FieldOptions  NVARCHAR(MAX)  = NULL,
    @IsRequired    INT            = 0,
    @DefaultValue  NVARCHAR(MAX)  = NULL,
    @SortOrder     INT            = 0,
    @NewID         INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate CategoryID tồn tại và đang active
    IF NOT EXISTS (
        SELECT 1 FROM dbo.tblWF_Category
        WHERE CategoryID = @CategoryID AND [Enable] = 1
    )
    BEGIN
        RAISERROR('CategoryID không hợp lệ hoặc đã bị xoá.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.tblWF_CustomFieldMapping
        (CategoryID, FieldName, FieldLabel, FieldType, FieldOptions,
         IsRequired, DefaultValue, SortOrder,
         CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable])
    VALUES
        (@CategoryID, @FieldName, @FieldLabel, @FieldType, @FieldOptions,
         @IsRequired, @DefaultValue, @SortOrder,
         @sys_UserID, GETDATE(),
         @sys_UserID, GETDATE(),
         0);

    SET @NewID = SCOPE_IDENTITY();
END
