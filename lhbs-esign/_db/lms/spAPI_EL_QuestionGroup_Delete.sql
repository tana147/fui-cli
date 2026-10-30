
--------------------------------------------------------------------------------
-- spAPI_EL_QuestionGroup_Delete (hard delete; also deletes related questions)
--------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spAPI_EL_QuestionGroup_Delete]
  @Id INT,
  @User VARCHAR(9)
AS
BEGIN
  SET NOCOUNT ON;
  IF @Id IS NULL
  BEGIN
    RAISERROR('Parameter @Id is required.', 16, 1);
    RETURN;
  END

  BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM dbo.tblEL_QuestionBank_Group WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
      RAISERROR('Group Id not found or already deleted.', 16, 1);
      ROLLBACK TRANSACTION;
      RETURN;
    END

    -- FK GroupId không bật cascade; xóa câu hỏi con trước để tránh vi phạm ràng buộc.
    DELETE FROM dbo.tblEL_QuestionBank_Question
    WHERE GroupId = @Id;

    -- Nhóm và toàn bộ câu hỏi thuộc nhóm được xóa vật lý khỏi Content Hub.
    DELETE FROM dbo.tblEL_QuestionBank_Group
    WHERE Id = @Id;

    COMMIT TRANSACTION;

    SELECT @Id AS Id, 'Deleted' AS Action;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0
      ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END
