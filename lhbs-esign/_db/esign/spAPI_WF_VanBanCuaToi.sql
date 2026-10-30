CREATE PROCEDURE spAPI_WF_VanBanCuaToi
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Văn bản do TÔI tạo (thống nhất trên model Instance).
    SELECT
        Nguon = 'INSTANCE',
        RecordID = I.InstanceID,
        TieuDe = I.InstanceName,
        ChoKy = NS.ResolvedPersonName,
        ThoiGianTao = I.CreateTime,
        ThoiGianHoanThanh = CASE WHEN I.Status = 'COMPLETED' THEN I.UpdateTime ELSE NULL END,
        TrangThaiCode = I.Status,
        TrangThaiText = CASE I.Status
            WHEN 'COMPLETED' THEN N'Hoàn tất'
            WHEN 'RUNNING' THEN N'Đang chờ ký'
            WHEN 'WAITING_ME' THEN N'Đang chờ ký'
            WHEN 'REJECTED' THEN N'Từ chối'
            WHEN 'CANCELLED' THEN N'Đã huỷ'
            ELSE I.Status END,
        LinkMo = '/wf-user-request-detail?id=' + CAST(I.InstanceID AS varchar(20))
    FROM tblWF_Instance I
    OUTER APPLY (
        SELECT TOP 1 SE.ResolvedPersonName
        FROM tblWF_StepExecution EX
        JOIN tblWF_StepSignerExec SE ON SE.ExecutionID = EX.ExecutionID AND SE.Enable = 1 AND SE.Status IN ('WAITING','PENDING')
        WHERE EX.InstanceID = I.InstanceID AND EX.StepOrder = I.CurrentStepOrder AND EX.Enable = 1
        ORDER BY SE.SignerOrder
    ) NS
    WHERE I.Enable = 1 AND I.CreateUser = @sys_UserID
    ORDER BY ThoiGianTao DESC;
END