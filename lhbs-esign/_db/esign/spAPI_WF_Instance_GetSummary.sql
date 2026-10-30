
    CREATE PROCEDURE [dbo].[spAPI_WF_Instance_GetSummary]
        @sys_UserID VARCHAR(9)
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            AllCount = COUNT(1),
            WaitingMeCount = SUM(CASE WHEN I.Status = 'WAITING_ME' THEN 1 ELSE 0 END),
            RunningCount = SUM(CASE WHEN I.Status = 'RUNNING' THEN 1 ELSE 0 END),
            CompletedCount = SUM(CASE WHEN I.Status = 'COMPLETED' THEN 1 ELSE 0 END)
        FROM dbo.tblWF_Instance AS I
        WHERE I.[Enable] = 1; -- Sửa lỗi Enable = 0 thành Enable = 1
    END
    