CREATE PROCEDURE [dbo].[spAPI_WF_Template_Save]
    @TemplateID BIGINT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TemplateName NVARCHAR(200) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.TemplateName'), N'')));
    DECLARE @FileName NVARCHAR(255) = JSON_VALUE(@sys_RawData, '$.FileName');
    DECLARE @FileUrl NVARCHAR(500) = JSON_VALUE(@sys_RawData, '$.FileUrl');
    DECLARE @FileType VARCHAR(10) = LOWER(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.FileType'), ''))));
    DECLARE @PlaceholderJSON NVARCHAR(MAX) = JSON_QUERY(@sys_RawData, '$.Placeholders');
    DECLARE @SignatureSlotsJSON NVARCHAR(MAX) = JSON_QUERY(@sys_RawData, '$.SignatureSlots');
    DECLARE @Description NVARCHAR(500) = JSON_VALUE(@sys_RawData, '$.Description');
    DECLARE @IsActive BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.IsActive') AS BIT), 1);

    IF ISNULL(@TemplateName, '') = ''
    BEGIN
        RAISERROR(N'Tên template không được để trống.', 16, 1);
        RETURN;
    END

    IF ISNULL(LTRIM(RTRIM(ISNULL(@FileName, ''))), '') = ''
    BEGIN
        RAISERROR(N'Tên file không được để trống.', 16, 1);
        RETURN;
    END

    IF @FileType NOT IN ('docx', 'pdf')
    BEGIN
        RAISERROR(N'Loại file chỉ hỗ trợ docx hoặc pdf.', 16, 1);
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM dbo.tblWF_Template AS T
        WHERE T.[Enable] = 1
          AND T.TemplateName = @TemplateName
          AND T.TemplateID <> @TemplateID
    )
    BEGIN
        RAISERROR(N'Tên template đã tồn tại.', 16, 1);
        RETURN;
    END

    IF @TemplateID = 0
    BEGIN
        INSERT INTO dbo.tblWF_Template
        (
            TemplateName, FileName, FileUrl, FileType, VersionNo, PlaceholderJSON, SignatureSlotsJSON, Description, IsActive,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        VALUES
        (
            @TemplateName, @FileName, @FileUrl, @FileType, 1, @PlaceholderJSON, @SignatureSlotsJSON, @Description, @IsActive,
            @sys_UserID, GETDATE(), NULL, NULL, 1
        );

        SET @TemplateID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.tblWF_Template
        SET TemplateName = @TemplateName,
            FileName = @FileName,
            FileUrl = @FileUrl,
            FileType = @FileType,
            VersionNo = ISNULL(VersionNo, 1) + 1,
            PlaceholderJSON = @PlaceholderJSON,
            SignatureSlotsJSON = @SignatureSlotsJSON,
            Description = @Description,
            IsActive = @IsActive,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE TemplateID = @TemplateID
          AND [Enable] = 1;
    END

    SELECT
        Message = N'Lưu template thành công.',
        TemplateID = @TemplateID;
END
