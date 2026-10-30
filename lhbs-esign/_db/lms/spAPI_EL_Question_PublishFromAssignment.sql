CREATE PROCEDURE [dbo].[spAPI_EL_Question_PublishFromAssignment]
  @GroupId INT,
  @SourceId VARCHAR(100),
  @Type VARCHAR(60),
  @QuestionText NVARCHAR(MAX),
  @OrdinalNumber INT,
  @Points DECIMAL(9,2),
  @GradingType VARCHAR(50),
  @IsAdvanced BIT,
  @ConfigJson NVARCHAR(MAX),
  @SkillsJson NVARCHAR(MAX),
  @RawJson NVARCHAR(MAX),
  @User VARCHAR(9)
AS
BEGIN
  SET NOCOUNT ON;

  IF @GroupId IS NULL
  BEGIN
    RAISERROR('Parameter @GroupId is required.', 16, 1);
    RETURN;
  END
  IF NULLIF(LTRIM(RTRIM(@SourceId)), '') IS NULL
  BEGIN
    RAISERROR('Parameter @SourceId is required.', 16, 1);
    RETURN;
  END
  IF @Type IS NULL OR LEN(LTRIM(RTRIM(@Type))) = 0
  BEGIN
    RAISERROR('Parameter @Type is required.', 16, 1);
    RETURN;
  END
  IF NULLIF(LTRIM(RTRIM(@QuestionText)), N'') IS NULL
  BEGIN
    RAISERROR('QuestionText is required.', 16, 1);
    RETURN;
  END
  IF @ConfigJson IS NULL OR ISJSON(@ConfigJson) <> 1
  BEGIN
    RAISERROR('ConfigJson must be valid JSON.', 16, 1);
    RETURN;
  END
  IF @SkillsJson IS NOT NULL AND ISJSON(@SkillsJson) <> 1
  BEGIN
    RAISERROR('SkillsJson must be valid JSON.', 16, 1);
    RETURN;
  END

  IF @Type NOT IN (
    'QUIZ_SINGLE_CHOICE',
    'QUIZ_MULTIPLE_CHOICE',
    'QUIZ_TRUE_FALSE',
    'QUIZ_MULTIPLE_TRUE_FALSE',
    'QUIZ_FILL_IN_BLANK',
    'QUIZ_MATCHING'
  )
  BEGIN
    RAISERROR('This question type is not supported by Content Hub publishing.', 16, 1);
    RETURN;
  END

  BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (
      SELECT 1
      FROM dbo.tblEL_QuestionBank_Group
      WHERE Id = @GroupId AND IsDeleted = 0
    )
    BEGIN
      RAISERROR('GroupId not found or deleted.', 16, 1);
      ROLLBACK TRANSACTION;
      RETURN;
    END

    /*
      The assignment builder sends ASSIGNMENT_FP_<fingerprint> as SourceId.
      This makes retries and concurrent clicks idempotent without inserting
      another copy of the same canonical question.
    */
    DECLARE @ExistingId INT;
    DECLARE @ExistingGroupId INT;

    SELECT TOP (1)
      @ExistingId = Id,
      @ExistingGroupId = GroupId
    FROM dbo.tblEL_QuestionBank_Question WITH (UPDLOCK, HOLDLOCK)
    WHERE SourceId = @SourceId
      AND IsDeleted = 0
    ORDER BY Id ASC;

    IF @ExistingId IS NOT NULL
    BEGIN
      COMMIT TRANSACTION;
      SELECT @ExistingId AS Id, @ExistingGroupId AS GroupId, 'AlreadyExists' AS Action;
      RETURN;
    END

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

    SELECT @NewId AS Id, @GroupId AS GroupId, 'Inserted' AS Action;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0
      ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END