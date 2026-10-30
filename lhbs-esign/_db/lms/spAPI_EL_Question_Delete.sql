
--------------------------------------------------------------------------------
-- spAPI_EL_Question_Delete (soft delete)
--------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spAPI_EL_Question_Delete]
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

    IF NOT EXISTS (SELECT 1 FROM dbo.tblEL_QuestionBank_Question WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
      RAISERROR('Question Id not found or already deleted.', 16, 1);
      ROLLBACK TRANSACTION;
      RETURN;
    END

    UPDATE dbo.tblEL_QuestionBank_Question
    SET IsDeleted = 1,
        UpdateUser = @User,
        UpdateTime = GETDATE()
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
