CREATE PROCEDURE [dbo].[spAPI_EL_Question_ContentHub_Check]
  @MonHocID INT,
  @KhoiID INT,
  @Type VARCHAR(60),
  @QuestionText NVARCHAR(MAX),
  @SourceId VARCHAR(100)
AS
BEGIN
  SET NOCOUNT ON;

  IF @MonHocID IS NULL OR @KhoiID IS NULL OR @Type IS NULL OR LEN(LTRIM(RTRIM(@Type))) = 0
  BEGIN
    RAISERROR('MonHocID, KhoiID and Type are required.', 16, 1);
    RETURN;
  END

  DECLARE @QuestionTextTrimmed NVARCHAR(MAX) = LTRIM(RTRIM(ISNULL(@QuestionText, N'')));

  /*
    Return only candidates in the same subject/grade. The client normalizes the
    canonical JSON and makes the final content comparison because legacy rows
    were stored with more than one JSON shape.
  */
  SELECT TOP (100)
    q.Id,
    q.GroupId,
    g.Title AS GroupTitle,
    q.SourceId,
    q.Type,
    q.QuestionText,
    q.ConfigJson,
    q.SkillsJson,
    q.Points,
    q.GradingType,
    q.IsAdvanced,
    q.CreateTime,
    q.UpdateTime
  FROM dbo.tblEL_QuestionBank_Question q
  INNER JOIN dbo.tblEL_QuestionBank_Group g ON g.Id = q.GroupId
  WHERE q.IsDeleted = 0
    AND g.IsDeleted = 0
    AND g.MonHocID = @MonHocID
    AND g.KhoiID = @KhoiID
    AND q.Type = @Type
    AND (
      (NULLIF(LTRIM(RTRIM(@SourceId)), '') IS NOT NULL AND q.SourceId = @SourceId)
      OR (NULLIF(@QuestionTextTrimmed, N'') IS NOT NULL
          AND LTRIM(RTRIM(ISNULL(q.QuestionText, N''))) = @QuestionTextTrimmed)
    )
  ORDER BY
    CASE WHEN NULLIF(LTRIM(RTRIM(@SourceId)), '') IS NOT NULL AND q.SourceId = @SourceId THEN 0 ELSE 1 END,
    q.Id ASC;
END