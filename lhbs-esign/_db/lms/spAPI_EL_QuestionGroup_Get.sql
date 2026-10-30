
--------------------------------------------------------------------------------
-- spAPI_EL_QuestionGroup_Get
-- Params: provide either @Id or @SourceId (Id preferred). Returns one row with QuestionsJson (array)
--------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spAPI_EL_QuestionGroup_Get]
  @Id INT = NULL,
  @SourceId VARCHAR(100) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @GroupId INT = @Id;

  IF @GroupId IS NULL AND @SourceId IS NOT NULL
  BEGIN
    SELECT TOP (1) @GroupId = Id
    FROM dbo.tblEL_QuestionBank_Group
    WHERE SourceId = @SourceId AND IsDeleted = 0;
  END

  IF @GroupId IS NULL
  BEGIN
    -- no group found: return empty result set
    SELECT CAST(NULL AS INT) AS Id, CAST(NULL AS VARCHAR(100)) AS SourceId, CAST(NULL AS NVARCHAR(255)) AS Title,
           CAST(NULL AS NVARCHAR(MAX)) AS Description, CAST(NULL AS INT) AS OrdinalNumber,
           CAST(NULL AS NVARCHAR(MAX)) AS MediaJson, CAST(NULL AS NVARCHAR(MAX)) AS RawJson,
           CAST(NULL AS VARCHAR(9)) AS CreateUser, CAST(NULL AS DATETIME) AS CreateTime,
           CAST(NULL AS VARCHAR(9)) AS UpdateUser, CAST(NULL AS DATETIME) AS UpdateTime,
           CAST(NULL AS BIT) AS IsDeleted, CAST(NULL AS NVARCHAR(MAX)) AS QuestionsJson
    WHERE 1 = 0; -- return no rows
    RETURN;
  END

  -- Return group columns + nested questions as JSON array (QuestionsJson)
  SELECT
    g.Id, g.SourceId, g.Title, g.Description, g.OrdinalNumber, g.MediaJson, g.RawJson,
    g.CreateUser, g.CreateTime, g.UpdateUser, g.UpdateTime, g.IsDeleted,
    (
      SELECT
        q.Id, q.SourceId, q.Type,   q.QuestionText, q.OrdinalNumber, q.Points, q.GradingType,
        q.IsAdvanced, q.ConfigJson, q.SkillsJson, q.RawJson, q.CreateUser, q.CreateTime, q.UpdateUser, q.UpdateTime, q.IsDeleted
      FROM dbo.tblEL_QuestionBank_Question q
      WHERE q.GroupId = g.Id AND q.IsDeleted = 0
      ORDER BY q.OrdinalNumber, q.Id
      FOR JSON PATH
    ) AS QuestionsJson
  FROM dbo.tblEL_QuestionBank_Group g
  WHERE g.Id = @GroupId;
END
