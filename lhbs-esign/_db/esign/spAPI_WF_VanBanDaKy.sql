CREATE PROCEDURE spAPI_WF_VanBanDaKy
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Văn bản mà TÔI đã ký (thống nhất trên model Instance).
    SELECT
        Nguon = 'INSTANCE',
        RecordID = I.InstanceID,
        TieuDe = I.InstanceName,
        ThoiGianKy = MK.NgayKyCuaToi,
        ThoiGianHoanThanh = CASE WHEN I.Status = 'COMPLETED' THEN I.UpdateTime ELSE NULL END,
        NguoiTao = I.CreateUser,
        TrangThaiCode = I.Status,
        TrangThaiText = CASE I.Status
            WHEN 'COMPLETED' THEN N'Hoàn tất'
            WHEN 'RUNNING' THEN N'Đang xử lý'
            WHEN 'WAITING_ME' THEN N'Đang xử lý'
            WHEN 'REJECTED' THEN N'Từ chối'
            WHEN 'CANCELLED' THEN N'Đã huỷ'
            ELSE I.Status END,
        LinkMo = '/wf-user-request-detail?id=' + CAST(I.InstanceID AS varchar(20))
    FROM tblWF_Instance I
    CROSS APPLY (
        SELECT NgayKyCuaToi = MAX(SE.SignedDate)
        FROM tblWF_StepExecution EX
        JOIN tblWF_StepSignerExec SE ON SE.ExecutionID = EX.ExecutionID AND SE.Enable = 1
        WHERE EX.InstanceID = I.InstanceID AND EX.Enable = 1
          AND SE.ResolvedPersonID = @sys_UserID AND SE.Status = 'SIGNED'
    ) MK
    WHERE I.Enable = 1 AND MK.NgayKyCuaToi IS NOT NULL
    ORDER BY ThoiGianKy DESC;
END