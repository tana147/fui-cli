-- Đổi tên từ spAPI_HDKH_@2_Field_Save thành spAPI_HDKH_Field_Save
CREATE  PROCEDURE spAPI_HDKH_Field_Save
    @FieldID INT = 0,
    @FormID INT,
    @FieldName VARCHAR(50),
    @FieldLabel NVARCHAR(255),
    @FieldType VARCHAR(20),
    @FieldGroup NVARCHAR(100) = NULL,
    @DataSource VARCHAR(255) = NULL,
    @SortOrder INT,
    @IsRequired BIT,
    @IsUsedForRule BIT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    IF (@FormID IS NULL OR ISNULL(@FieldName, '') = '' OR ISNULL(@FieldLabel, '') = '' OR ISNULL(@FieldType, '') = '')
    BEGIN
        RAISERROR(N'FormID, FieldName, FieldLabel và FieldType là bắt buộc.', 16, 1);
        RETURN;
    END

    MERGE tblHDKH_Field_Definition AS T
    USING (SELECT @FieldID AS FieldID) AS S
    ON (T.FieldID = S.FieldID AND S.FieldID > 0)
    WHEN MATCHED THEN
        UPDATE SET
            FormID = @FormID, FieldName = @FieldName, FieldLabel = @FieldLabel, FieldType = @FieldType, 
            FieldGroup = @FieldGroup, DataSource = @DataSource, SortOrder = @SortOrder, 
            IsRequired = @IsRequired, IsUsedForRule = @IsUsedForRule,
            UpdateTime = GETDATE(), UpdateUser = @sys_UserID
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (FormID, FieldName, FieldLabel, FieldType, FieldGroup, DataSource, SortOrder, IsRequired, IsUsedForRule, CreateUser)
        VALUES (@FormID, @FieldName, @FieldLabel, @FieldType, @FieldGroup, @DataSource, @SortOrder, @IsRequired, @IsUsedForRule, @sys_UserID);

    SELECT Message = N'Lưu Field thành công.';
END;
