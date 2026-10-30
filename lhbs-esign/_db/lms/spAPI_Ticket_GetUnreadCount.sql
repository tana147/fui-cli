
-- =============================================
-- 9. GET UNREAD COUNT
-- =============================================
CREATE   PROC [dbo].[spAPI_Ticket_GetUnreadCount]
    @TicketID INT,
    @IsIT BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF (@IsIT = 1)
    BEGIN
        SELECT COUNT(*) AS UnreadCount
        FROM TicketComments
        WHERE TicketID = @TicketID AND IsSeenByIT = 0;
    END
    ELSE
    BEGIN
        SELECT COUNT(*) AS UnreadCount
        FROM TicketComments
        WHERE TicketID = @TicketID
          AND IsSeenByUser = 0
          AND IsInternal = 0;
    END
END
