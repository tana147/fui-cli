
-- =============================================
-- 8. MARK AS SEEN
-- =============================================
CREATE   PROC [dbo].[spAPI_Ticket_MarkAsSeen]
    @TicketID INT,
    @IsIT BIT,
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF (@IsIT = 1)
    BEGIN
        UPDATE TicketComments
        SET IsSeenByIT = 1
        WHERE TicketID = @TicketID AND IsSeenByIT = 0;
    END
    ELSE
    BEGIN
        UPDATE TicketComments
        SET IsSeenByUser = 1
        WHERE TicketID = @TicketID
          AND IsSeenByUser = 0
          AND IsInternal = 0;
    END
END
