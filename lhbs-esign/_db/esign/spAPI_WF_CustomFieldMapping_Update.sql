-- ------------------------------------------------------------
-- 4. UPDATE
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[spAPI_WF_CustomFieldMapping_Update]
    @sys_UserID    VARCHAR(9),
    @MappingID     INT,
    @CategoryID    INT,
    @FieldName     NVARCHAR(100),
    @FieldLabel    NVARCHAR(255),
    @FieldType     NVARCHAR(50),
    @FieldOptions  NVARCHAR(MAX)  = NULL,
    @IsRequired    INT            = 0,
    @DefaultValue  NVARCHAR(MAX)  = NULL,
    @SortOrder     INT            = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate CategoryID
    IF NOT EXISTS (
        SELECT 1 FROM dbo.tblWF_Category
        WHERE CategoryID = @CategoryID AND [Enable] = 1
    )
    BEGIN
        RAISERROR('CategoryID không hợp lệ hoặc đã bị xoá.', 16, 1);
        RETURN;
    END

    UPDATE dbo.tblWF_CustomFieldMapping
    SET
        CategoryID   = @CategoryID,
        FieldName    = @FieldName,
        FieldLabel   = @FieldLabel,
        FieldType    = @FieldType,
        FieldOptions = @FieldOptions,
        IsRequired   = @IsRequired,
        DefaultValue = @DefaultValue,
        SortOrder    = @SortOrder,
        UpdateUser   = @sys_UserID,
        UpdateTime   = GETDATE()
    WHERE MappingID = @MappingID
      AND [Enable]  = 0;
END
