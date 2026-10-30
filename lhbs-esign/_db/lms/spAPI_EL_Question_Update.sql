
--------------------------------------------------------------------------------
-- spAPI_EL_Question_Update
--------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spAPI_EL_Question_Update]
  @Id INT,
  @GroupId INT = NULL,
  @SourceId VARCHAR(100) = NULL,
  @Type VARCHAR(60) = NULL,
  @QuestionText NVARCHAR(MAX) = NULL,
  @OrdinalNumber INT = NULL,
  @Points DECIMAL(9,2) = NULL,
  @GradingType VARCHAR(50) = NULL,
  @IsAdvanced BIT = NULL,
  @ConfigJson NVARCHAR(MAX) = NULL,
  @SkillsJson NVARCHAR(MAX) = NULL,
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

    IF NOT EXISTS (SELECT 1 FROM dbo.tblEL_QuestionBank_Question WHERE Id = @Id AND IsDeleted = 0)
    BEGIN
      RAISERROR('Question Id not found or is deleted.', 16, 1);
      ROLLBACK TRANSACTION;
      RETURN;
    END

    IF @GroupId IS NOT NULL
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM dbo.tblEL_QuestionBank_Group WHERE Id = @GroupId AND IsDeleted = 0)
      BEGIN
        RAISERROR('Provided GroupId not found or is deleted.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
      END
    END

    UPDATE dbo.tblEL_QuestionBank_Question
    SET GroupId = ISNULL(@GroupId, GroupId),
        SourceId = @SourceId,
        Type = ISNULL(@Type, Type),
        QuestionText = @QuestionText,
        OrdinalNumber = ISNULL(@OrdinalNumber, OrdinalNumber),
        Points = @Points,
        GradingType = @GradingType,
        IsAdvanced = ISNULL(@IsAdvanced, IsAdvanced),
        ConfigJson = @ConfigJson,
        SkillsJson = @SkillsJson,
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
