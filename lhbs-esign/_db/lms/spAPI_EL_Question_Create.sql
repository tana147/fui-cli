
--------------------------------------------------------------------------------
-- spAPI_EL_Question_Create
--------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spAPI_EL_Question_Create]
  @GroupId INT,
  @SourceId VARCHAR(100) = NULL,
  @Type VARCHAR(60),
  @QuestionText NVARCHAR(MAX) = NULL,
  @OrdinalNumber INT = NULL,
  @Points DECIMAL(9,2) = NULL,
  @GradingType VARCHAR(50) = NULL,
  @IsAdvanced BIT = 0,
  @ConfigJson NVARCHAR(MAX) = NULL,
  @SkillsJson NVARCHAR(MAX) = NULL,
  @RawJson NVARCHAR(MAX) = NULL,
  @User VARCHAR(9)
AS
BEGIN
  SET NOCOUNT ON;
  IF @GroupId IS NULL
  BEGIN
    RAISERROR('Parameter @GroupId is required.', 16, 1);
    RETURN;
  END
  IF @Type IS NULL OR LEN(@Type) = 0
  BEGIN
    RAISERROR('Parameter @Type is required.', 16, 1);
    RETURN;
  END

  BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM dbo.tblEL_QuestionBank_Group WHERE Id = @GroupId AND IsDeleted = 0)
    BEGIN
      RAISERROR('GroupId not found or deleted.', 16, 1);
      ROLLBACK TRANSACTION;
      RETURN;
    END

    -- Auto-calculate OrdinalNumber if not provided
    IF @OrdinalNumber IS NULL
      SELECT @OrdinalNumber = ISNULL(MAX(OrdinalNumber), 0) + 1
      FROM dbo.tblEL_QuestionBank_Question
      WHERE GroupId = @GroupId AND IsDeleted = 0;

    INSERT INTO dbo.tblEL_QuestionBank_Question
      (GroupId, SourceId, Type, QuestionText, OrdinalNumber, Points, GradingType, IsAdvanced, ConfigJson, SkillsJson, RawJson, CreateUser, CreateTime, IsDeleted)
    VALUES
      (@GroupId, @SourceId, @Type, @QuestionText, @OrdinalNumber, @Points, @GradingType, @IsAdvanced, @ConfigJson, @SkillsJson, @RawJson, @User, GETDATE(), 0);

    DECLARE @NewId INT = SCOPE_IDENTITY();

    COMMIT TRANSACTION;

    SELECT @NewId AS Id, 'Inserted' AS Action;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0
      ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END
