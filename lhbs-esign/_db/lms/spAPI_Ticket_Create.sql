-- =============================================
-- FINAL VERSION (Correct Actor vs Owner)
-- Actor = @SYS_USERID
-- Owner = AssignedTo
-- =============================================

-- =============================================
-- 1. ALTER TICKET
-- =============================================
CREATE   PROC [dbo].[spAPI_Ticket_Create]
    @Title NVARCHAR(255),
    @Description NVARCHAR(MAX),
    @Url NVARCHAR(1000),
    @Browser NVARCHAR(255),
    @Os NVARCHAR(255),
    @AttachmentJSON NVARCHAR(MAX),
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TicketID INT;

    INSERT INTO Tickets (
        Title, Description, Status,
        Url, Browser, Os,
        CreateUser, CreateTime
    )
    VALUES (
        @Title, @Description, 'OPEN',
        @Url, @Browser, @Os,
        @SYS_USERID, GETDATE()
    );

    SET @TicketID = SCOPE_IDENTITY();

    IF (@AttachmentJSON IS NOT NULL AND LTRIM(RTRIM(@AttachmentJSON)) <> '')
    BEGIN
        INSERT INTO TicketAttachments (
            TicketID, FileID, JSON_Annotation, CreateUser, CreateTime
        )
        SELECT @TicketID, FileID, JSON_Annotation, @SYS_USERID, GETDATE()
        FROM OPENJSON(@AttachmentJSON)
        WITH (
            FileID VARCHAR(100) '$.FileID',
            JSON_Annotation NVARCHAR(MAX) '$.Annotation'
        );
    END

    -- LOG (actor = SYS_USERID)
    INSERT INTO TicketLogs (TicketID, Action, NewValue, CreateUser, CreateTime)
    VALUES (@TicketID, 'CREATE', @Title, @SYS_USERID, GETDATE());

    -- Báo cho toàn bộ System Admin trong System Hub; UserRight = 9 là mã vai trò,
    -- còn người tạo ticket vẫn được lưu riêng ở CreateUser để admin truy vết đúng actor.
    INSERT INTO tblAlert (
        TypeAlert, ContentAlert, DateAlert, CapID, NienKhoa, Enable,
        CreateUser, CreateTime, UpdateUser, UpdateTime, UserRight
    )
    VALUES (
        'ALERT',
        LEFT(N'Báo lỗi mới từ ' + ISNULL(@SYS_USERID, '') + N': ' + ISNULL(@Title, N''), 100),
        GETDATE(), 0, 0, 1,
        @SYS_USERID, GETDATE(), @SYS_USERID, GETDATE(), '9'
    );

    SELECT @TicketID AS TicketID;
END
