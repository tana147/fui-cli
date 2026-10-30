CREATE PROCEDURE spAPI_WF_VanBanChoKy
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Văn bản đang chờ TÔI ký (thống nhất trên model Instance).
    SELECT
        Nguon = 'INSTANCE',
        RecordID = I.InstanceID,
        TieuDe = I.InstanceName,
        HinhThucKy = ISNULL(I.ExecutionEngine, 'CA_NOIBO'),
        HinhThucKyText = CASE
            WHEN I.ContractProvider IS NOT NULL THEN N'HĐ điện tử VNPT'
            WHEN EXISTS (SELECT 1 FROM tblWF_StepDefinition sd JOIN tblWF_StepExecution ex ON ex.StepDefID=sd.StepDefID WHERE ex.InstanceID=I.InstanceID AND ex.StepOrder=I.CurrentStepOrder AND sd.SignSystem='smartca')
                THEN N'VNPT SmartCA'
            ELSE N'Ký nội bộ' END,
        BuocKy = I.CurrentStepOrder,
        ThoiGianTao = I.CreateTime,
        NguoiTao = I.CreateUser,
        SoNgayCho = DATEDIFF(day, I.CreateTime, GETDATE()),
        LinkMo = '/wf-user-request-detail?id=' + CAST(I.InstanceID AS varchar(20))
    FROM tblWF_Instance I
    WHERE I.Enable = 1
      AND I.Status IN ('RUNNING','WAITING_ME')
      AND EXISTS (
          SELECT 1 FROM tblWF_StepExecution EX
          JOIN tblWF_StepSignerExec SE ON SE.ExecutionID = EX.ExecutionID AND SE.Enable = 1
          WHERE EX.InstanceID = I.InstanceID
            AND EX.StepOrder = I.CurrentStepOrder
            AND EX.Status IN ('ACTIVE','SIGNING')
            AND SE.Status IN ('WAITING','PENDING')
            AND SE.ResolvedPersonID = @sys_UserID
      )
    ORDER BY ThoiGianTao DESC;
END