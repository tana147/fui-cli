
CREATE PROCEDURE [dbo].[spAPI_WF_RequestDraft_GetDetail]
    @DraftID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tblWF_RequestDraft WHERE DraftID = @DraftID AND [Enable] = 0)
    BEGIN
        RAISERROR(N'Không tìm thấy draft yêu cầu ký.', 16, 1);
        RETURN;
    END

    SELECT
        DraftID, CreateMode, DefinitionID, CategoryID, DraftName, ReferenceCode, Description,
        ExecutionEngine, ContractProvider, FileMethod, SourceFileID, SourceFileName,
        TemplateID, DueDate, Priority, Sequential, NotifyEmail, RequireOtpConfirm,
        SubmittedInstanceID, Status, CreateUser, CreateTime, UpdateUser, UpdateTime
    FROM dbo.tblWF_RequestDraft
    WHERE DraftID = @DraftID
      AND [Enable] = 0;

    SELECT
        DraftFieldID, DraftID, FieldName, FieldLabel, FieldValue
    FROM dbo.tblWF_RequestDraftField
    WHERE DraftID = @DraftID
      AND [Enable] = 0
    ORDER BY DraftFieldID;

    SELECT
        DraftSignerID, DraftID, SignerOrder, StepOrder, StepName, SignerType, SignerValue,
        PersonName, DepartmentName, SignMethod, ExecutionEngine, ContractProvider
    FROM dbo.tblWF_RequestDraftSigner
    WHERE DraftID = @DraftID
      AND [Enable] = 0
    ORDER BY SignerOrder, DraftSignerID;

    SELECT
        DraftBoxID, DraftID, BoxOrder, PageNo, PosX, PosY, BoxWidth, BoxHeight,
        StepOrder, SignerOrder, SignerType, SignerValue, PersonName, DepartmentName,
        SignMethod, ExecutionEngine, ContractProvider, LabelText
    FROM dbo.tblWF_RequestDraftBox
    WHERE DraftID = @DraftID
      AND [Enable] = 0
    ORDER BY BoxOrder, DraftBoxID;
END
