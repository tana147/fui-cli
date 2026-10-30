
--------------------------------------------------------------------------------
-- spAPI_EL_QuestionGroup_Update
--------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spAPI_EL_QuestionGroup_Update]
  @Id INT,
  @SourceId VARCHAR(100) = NULL,
  @KhoiID INT = NULL,
  @MonHocID INT = NULL,
  @Title NVARCHAR(255) = NULL,
  @Description NVARCHAR(MAX) = NULL,
  @OrdinalNumber INT = NULL,
  @MediaJson NVARCHAR(MAX) = NULL,
  @RawJson NVARCHAR(MAX) = NULL,
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
      RAISERROR('Group Id not found or is deleted.', 16, 1);
      ROLLBACK TRANSACTION;
      RETURN;
    END

    UPDATE dbo.tblEL_QuestionBank_Group
    SET SourceId = @SourceId,
        KhoiID = ISNULL(@KhoiID, KhoiID),
        MonHocID = ISNULL(@MonHocID, MonHocID),
        Title = @Title,
        Description = @Description,
        OrdinalNumber = @OrdinalNumber,
        MediaJson = @MediaJson,
        RawJson = @RawJson,
        UpdateUser = @User,
        UpdateTime = GETDATE()
    WHERE Id = @Id;

    COMMIT TRANSACTION;

    SELECT @Id AS Id, 'Updated' AS Action;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0
      ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END
