
-- =============================================
-- 7. GET DETAIL
-- =============================================
CREATE   PROC [dbo].[spAPI_Ticket_GetDetail]
    @TicketID INT,
    @IsIT BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM Tickets WHERE TicketID = @TicketID AND IsDeleted = 0;

    -- Result set 2: ticket-level attachments only (CommentID IS NULL)
    SELECT * FROM TicketAttachments
    WHERE TicketID = @TicketID AND CommentID IS NULL AND IsDeleted = 0;

    -- Result set 3: comments
    SELECT * FROM TicketComments
    WHERE TicketID = @TicketID
      AND IsDeleted = 0
      AND (@IsIT = 1 OR IsInternal = 0)
    ORDER BY CreateTime ASC;

    -- Result set 4: logs (IT only — always emitted to keep result-set index stable)
    IF (@IsIT = 1)
	BEGIN
	     SELECT * FROM TicketLogs
        WHERE TicketID = @TicketID
        ORDER BY CreateTime DESC; 
	END
      
    ELSE
	BEGIN
	    
        SELECT TOP 0 * FROM TicketLogs WHERE 1 = 0;
	END

    -- Result set 5: comment attachments (keyed by CommentID for frontend mapping)
    SELECT ta.*
    FROM TicketAttachments ta
    INNER JOIN TicketComments c ON c.CommentID = ta.CommentID
    WHERE c.TicketID = @TicketID
      AND c.IsDeleted = 0
      AND ta.IsDeleted = 0
      AND (@IsIT = 1 OR c.IsInternal = 0)
    ORDER BY ta.CreateTime ASC;
END
