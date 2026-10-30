

CREATE  PROCEDURE [dbo].[spAPI_UPLOAD_FileData_Base64]
    @sys_UserID VARCHAR(9),
    @FileBase64 NVARCHAR(MAX),
    @FileName NVARCHAR(200),
    @FileContentType VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- ======================================================================
        -- BƯỚC 1: VALIDATE DỮ LIỆU ĐẦU VÀO
        -- ======================================================================
        IF (@FileBase64 IS NULL OR LEN(@FileBase64) = 0)
            THROW 50001, 'FileBase64 is required.', 1;


        IF (@FileName IS NULL OR LTRIM(RTRIM(@FileName)) = N'')
            THROW 50002, 'FileName is required.', 1;

        -- ======================================================================
        -- BƯỚC 2: DECODE CHUỖI BASE64 THÀNH DỮ LIỆU NHỊ PHÂN (VARBINARY)
        -- ======================================================================

        DECLARE @FileBinary VARBINARY(MAX);
        SELECT @FileBinary = CAST('' AS XML).value('xs:base64Binary(sql:variable("@FileBase64"))', 'VARBINARY(MAX)');


        IF (@FileBinary IS NULL OR DATALENGTH(@FileBinary) = 0)
            THROW 50003, 'Failed to decode FileBase64. The string might be empty or invalid.', 1;

        -- ======================================================================
        -- BƯỚC 3: TỰ THỰC HIỆN LOGIC LƯU TRỮ (SAO CHÉP TỪ SP GỐC)
        -- ======================================================================
       DECLARE @FileID VARCHAR(36) = CAST(NEWID() AS VARCHAR(36));

        DECLARE @FileSize INT = DATALENGTH(@FileBinary);


        INSERT INTO [eSignature_File].[dbo].[tblFileData]
        (
            FileID,
            FileName,
            BinaryContent,
            ContentType,
            FileSize
        )
        VALUES
        (
            @FileID,
            @FileName,
            @FileBinary,
            @FileContentType,
            @FileSize
        );

        
        -- ======================================================================
        -- BƯỚC 4: TRẢ VỀ KẾT QUẢ VỚI CẤU TRÚC Y HỆT SP GỐC
        -- ======================================================================

        SELECT 
            FileID = @FileID,
            FileName = @FileName,
            FileContentType = @FileContentType,
            FileSize = @FileSize,
            FileUrl = '/FileData/' + @FileID,
            File_Binary = @FileBinary

    END TRY
    BEGIN CATCH
        -- Xử lý lỗi
        DECLARE
            @ErrMsg   NVARCHAR(4000) = ERROR_MESSAGE(),
            @ErrNum   INT            = ERROR_NUMBER();

        RAISERROR(N'[spAPIFILE_UPLOAD_FileData_Base64] failed. %s (Error %d)', 16, 1, @ErrMsg, @ErrNum);
        RETURN;

    END CATCH

END

