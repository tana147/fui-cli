
--------------------------------------------------------------------------------
-- spAPI_EL_Question_List
-- Params:
--   @GroupId INT = NULL (optional)
--   @Type VARCHAR(60) = NULL (optional)
--   @Search NVARCHAR(400) = NULL  -- simple substring search on Label or QuestionText
--   @IncludeDeleted BIT = 0
--   @PageNumber INT = 1, @PageSize INT = 100
-- Returns: paged list of questions
--------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spAPI_EL_Question_List]
  @GroupId INT = NULL,
  @Type VARCHAR(60) = NULL,
  @Search NVARCHAR(400) = NULL,
  @IncludeDeleted BIT = 0,
  @PageNumber INT = 1,
  @PageSize INT = 100
AS
BEGIN
  SET NOCOUNT ON;

  IF @PageNumber < 1 SET @PageNumber = 1;
  IF @PageSize < 1 SET @PageSize = 100;

  -- Normalize empty strings to NULL
  IF @Type = '' SET @Type = NULL;
  IF @Search = '' SET @Search = NULL;

  ;WITH CTE AS (
    SELECT
      q.Id, q.GroupId, q.SourceId, q.Type, q.QuestionText, q.OrdinalNumber, q.Points, q.GradingType,
      q.IsAdvanced, q.ConfigJson, q.SkillsJson, q.RawJson, q.CreateUser, q.CreateTime, q.UpdateUser, q.UpdateTime, q.IsDeleted,
      ROW_NUMBER() OVER (ORDER BY q.OrdinalNumber ASC, q.Id ASC) AS rn
    FROM dbo.tblEL_QuestionBank_Question q
    WHERE (@IncludeDeleted = 1 OR q.IsDeleted = 0)
      AND (@GroupId IS NULL OR q.GroupId = @GroupId)
      AND (@Type IS NULL OR q.Type = @Type)
      AND (
            @Search IS NULL
            OR (q.QuestionText IS NOT NULL AND q.QuestionText LIKE '%' + @Search + '%')
            OR (q.ConfigJson IS NOT NULL AND q.ConfigJson LIKE '%' + @Search + '%')
          )
  )
  SELECT
    Id, GroupId, SourceId, Type, QuestionText, OrdinalNumber, Points, GradingType,
    IsAdvanced, ConfigJson, SkillsJson, RawJson, CreateUser, CreateTime, UpdateUser, UpdateTime, IsDeleted
  FROM CTE
  WHERE rn BETWEEN ((@PageNumber - 1) * @PageSize) + 1 AND (@PageNumber * @PageSize)
  ORDER BY rn;
END
