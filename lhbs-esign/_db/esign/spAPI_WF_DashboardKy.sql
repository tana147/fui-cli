CREATE PROCEDURE spAPI_WF_DashboardKy
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Tập văn bản đang chờ TÔI ký tại bước hiện tại (model Instance).
    SELECT
        I.InstanceID, I.InstanceName, I.CreateTime, I.CreateUser, I.CurrentStepOrder,
        I.ContractProvider,
        NhomKy = CASE
            WHEN I.ContractProvider IS NOT NULL THEN 'PHAPLY'
            WHEN EXISTS (SELECT 1 FROM tblWF_StepDefinition sd JOIN tblWF_StepExecution ex ON ex.StepDefID=sd.StepDefID WHERE ex.InstanceID=I.InstanceID AND ex.StepOrder=I.CurrentStepOrder AND sd.SignSystem='smartca')
                THEN 'PHAPLY' ELSE 'NOIBO' END
    INTO #ChoToi
    FROM tblWF_Instance I
    WHERE I.Enable = 1 AND I.Status IN ('RUNNING','WAITING_ME')
      AND EXISTS (
          SELECT 1 FROM tblWF_StepExecution EX
          JOIN tblWF_StepSignerExec SE ON SE.ExecutionID = EX.ExecutionID AND SE.Enable = 1
          WHERE EX.InstanceID = I.InstanceID AND EX.StepOrder = I.CurrentStepOrder
            AND EX.Status IN ('ACTIVE','SIGNING') AND SE.Status IN ('WAITING','PENDING')
            AND SE.ResolvedPersonID = @sys_UserID);

    -- (1) Thống kê
    SELECT
        ChoKyHomNay = (SELECT COUNT(*) FROM #ChoToi),
        DaKyTuanNay = (SELECT COUNT(DISTINCT EX.InstanceID)
            FROM tblWF_StepExecution EX
            JOIN tblWF_StepSignerExec SE ON SE.ExecutionID = EX.ExecutionID AND SE.Enable = 1
            WHERE EX.Enable = 1 AND SE.ResolvedPersonID = @sys_UserID AND SE.Status = 'SIGNED'
              AND SE.SignedDate >= DATEADD(day, -7, GETDATE())),
        KyNoiBo = (SELECT COUNT(*) FROM #ChoToi WHERE NhomKy = 'NOIBO'),
        KyPhapLy = (SELECT COUNT(*) FROM #ChoToi WHERE NhomKy = 'PHAPLY');

    -- (2) Danh sách chờ tôi ký
    SELECT
        RecordID = c.InstanceID,
        TieuDe = c.InstanceName,
        HinhThucKyText = CASE
            WHEN c.NhomKy = 'PHAPLY' AND c.ContractProvider IS NOT NULL THEN N'HĐ điện tử VNPT'
            WHEN c.NhomKy = 'PHAPLY' THEN N'VNPT SmartCA'
            ELSE N'Ký nội bộ' END,
        NhomKy = c.NhomKy,
        CreateTime = c.CreateTime,
        SoNgayCho = DATEDIFF(day, c.CreateTime, GETDATE()),
        LoaiHoSo = N'Trong quy trình',
        LinkMo = '/wf-user-request-detail?id=' + CAST(c.InstanceID AS varchar(20))
    FROM #ChoToi c
    ORDER BY c.CreateTime ASC;

    DROP TABLE #ChoToi;
END