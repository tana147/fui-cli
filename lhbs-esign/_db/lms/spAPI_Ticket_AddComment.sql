
-- =============================================
-- 2. ADD COMMENT (actor only)
-- =============================================
CREATE   PROC [dbo].[spAPI_Ticket_AddComment]
    @TicketID INT,
    @Content NVARCHAR(MAX),
    @IsInternal BIT = 0,
    @IsIT BIT = 0,
    @AttachmentJSON NVARCHAR(MAX) = NULL,
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IsSeenByUser BIT = 0;
    DECLARE @IsSeenByIT BIT = 0;
    DECLARE @CommentID INT;

    IF (@IsInternal = 1)
    BEGIN
        SET @IsSeenByUser = 1;
        SET @IsSeenByIT = 1;
    END
    ELSE IF (@IsIT = 1)
    BEGIN
        SET @IsSeenByIT = 1;
        SET @IsSeenByUser = 0;
    END
    ELSE
    BEGIN
        SET @IsSeenByIT = 0;
        SET @IsSeenByUser = 1;
    END

    INSERT INTO TicketComments (
        TicketID, Content, IsInternal,
        IsSeenByUser, IsSeenByIT,
        IsDeleted, CreateUser, CreateTime
    )
    VALUES (
        @TicketID, @Content, @IsInternal,
        @IsSeenByUser, @IsSeenByIT,
        0, @SYS_USERID, GETDATE()
    );

    SET @CommentID = SCOPE_IDENTITY();

	SELECT @AttachmentJSON
	IF(@AttachmentJSON IS NOT NULL AND LTRIM(RTRIM(@AttachmentJSON)) <> '')
	BEGIN
	    SELECT 1
	END
	ELSE
     BEGIN
         SELECT 2
     END

    IF (@AttachmentJSON IS NOT NULL AND LTRIM(RTRIM(@AttachmentJSON)) <> '')
    BEGIN
        INSERT INTO TicketAttachments (
            TicketID, CommentID, FileID, JSON_Annotation, CreateUser, CreateTime
        )
        SELECT @TicketID, @CommentID, FileID, JSON_Annotation, @SYS_USERID, GETDATE()
        FROM OPENJSON(@AttachmentJSON)
        WITH (
            FileID VARCHAR(100) '$.FileID',
            JSON_Annotation NVARCHAR(MAX) '$.Annotation'
        );
    END

    -- LOG (actor)
    INSERT INTO TicketLogs (TicketID, Action, Note, CreateUser, CreateTime)
    VALUES (@TicketID, 'COMMENT', @Content, @SYS_USERID, GETDATE());
END
