
--------------------------------------------------------------------------------
-- spAPI_EL_Question_Get
-- Params: provide either @Id or @SourceId (Id preferred). Returns the question row.
--------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spAPI_EL_Question_Get]
  @Id INT = NULL,
  @SourceId VARCHAR(100) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Id IS NULL AND @SourceId IS NULL
  BEGIN
    RAISERROR('Provide either @Id or @SourceId.', 16, 1);
    RETURN;
  END

  IF @Id IS NULL
  BEGIN
    SELECT TOP (1) @Id = Id
    FROM dbo.tblEL_QuestionBank_Question
    WHERE SourceId = @SourceId AND IsDeleted = 0;
  END

  SELECT
    q.Id, q.GroupId, g.SourceId AS GroupSourceId, g.Title AS GroupTitle,
    q.SourceId, q.Type,   q.QuestionText, q.OrdinalNumber, q.Points, q.GradingType,
    q.IsAdvanced, q.ConfigJson, q.SkillsJson, q.RawJson, q.CreateUser, q.CreateTime, q.UpdateUser, q.UpdateTime, q.IsDeleted
  FROM dbo.tblEL_QuestionBank_Question q
  LEFT JOIN dbo.tblEL_QuestionBank_Group g ON g.Id = q.GroupId
  WHERE q.Id = @Id;
END
