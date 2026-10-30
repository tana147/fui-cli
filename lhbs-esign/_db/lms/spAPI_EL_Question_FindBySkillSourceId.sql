
--------------------------------------------------------------------------------
-- spAPI_EL_Question_FindBySkillSourceId
-- Params:
--   @SourceSkillId INT (KyNang_MonHoc_ChiTietID inside SkillsJson objects)
--   @PageNumber INT = 1, @PageSize INT = 100
-- Uses OPENJSON to parse SkillsJson and match KyNang_MonHoc_ChiTietID
--------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spAPI_EL_Question_FindBySkillSourceId]
  @SourceSkillId INT,
  @PageNumber INT = 1,
  @PageSize INT = 100
AS
BEGIN
  SET NOCOUNT ON;

  IF @SourceSkillId IS NULL
  BEGIN
    RAISERROR('Parameter @SourceSkillId is required.', 16, 1);
    RETURN;
  END

  IF @PageNumber < 1 SET @PageNumber = 1;
  IF @PageSize < 1 SET @PageSize = 100;

  ;WITH Matched AS (
    SELECT
      q.Id, q.GroupId, q.SourceId, q.Type,   q.QuestionText, q.OrdinalNumber, q.Points, q.GradingType,
      q.IsAdvanced, q.ConfigJson, q.SkillsJson, q.RawJson, q.CreateUser, q.CreateTime, q.UpdateUser, q.UpdateTime, q.IsDeleted,
      ROW_NUMBER() OVER (ORDER BY q.OrdinalNumber ASC, q.Id ASC) AS rn
    FROM dbo.tblEL_QuestionBank_Question q
    CROSS APPLY OPENJSON(q.SkillsJson) WITH (KyNang_MonHoc_ChiTietID INT '$.KyNang_MonHoc_ChiTietID') AS s
    WHERE s.KyNang_MonHoc_ChiTietID = @SourceSkillId
      AND q.IsDeleted = 0
  )
  SELECT
    Id, GroupId, SourceId, Type,  QuestionText, OrdinalNumber, Points, GradingType,
    IsAdvanced, ConfigJson, SkillsJson, RawJson, CreateUser, CreateTime, UpdateUser, UpdateTime, IsDeleted
  FROM Matched
  WHERE rn BETWEEN ((@PageNumber - 1) * @PageSize) + 1 AND (@PageNumber * @PageSize)
  ORDER BY rn;
END
