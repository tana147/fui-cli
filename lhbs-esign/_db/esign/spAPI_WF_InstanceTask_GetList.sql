CREATE PROCEDURE [dbo].[spAPI_WF_InstanceTask_GetList]
    @sys_UserID  VARCHAR(9),
    @InstanceID  BIGINT = NULL,
    @ExecutionID BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        T.TaskID,
        T.ExecutionID,
        T.InstanceID,
        T.StepDefID,
        T.TaskName,
        T.Description,
        T.DueHours,
        T.IsRequired,
        T.Status,
        T.CreateTime,
        T.CreateUser,
        T.UpdateTime,
        T.UpdateUser,
        T.SortOrder,
        -- Thông tin bước để hiển thị nhóm
        S.StepName,
        S.StepOrder
    FROM dbo.tblWF_InstanceTask AS T
    LEFT JOIN dbo.tblWF_StepDefinition AS S
        ON S.StepDefID = T.StepDefID AND S.[Enable] = 1
    WHERE T.[Enable] = 1
      AND (@InstanceID  IS NULL OR T.InstanceID  = @InstanceID)
      AND (@ExecutionID IS NULL OR T.ExecutionID = @ExecutionID)
    ORDER BY S.StepOrder, T.SortOrder, T.TaskID;
END
