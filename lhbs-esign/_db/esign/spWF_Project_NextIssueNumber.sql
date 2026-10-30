-- 6.1 Cấp IssueNumber tiếp theo cho 1 project — ATOMIC (chống race)
CREATE   PROCEDURE [dbo].[spWF_Project_NextIssueNumber]
    @ProjectID BIGINT,
    @Next      INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Next = NULL;
    IF @ProjectID IS NULL RETURN;
    -- UPDATE tự khóa dòng: gán @Next = giá trị cũ + 1 (SQL Server dùng giá trị trước update ở vế phải)
    UPDATE dbo.tblWF_Project
    SET IssueSeq = IssueSeq + 1,
        @Next    = IssueSeq + 1
    WHERE ProjectID = @ProjectID AND [Enable] = 1;
END