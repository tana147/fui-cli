CREATE PROCEDURE [dbo].[spAPI_EL_QuestionGroup_List]
  @KhoiID INT = NULL,
  @MonHocID INT = NULL,
  @IncludeDeleted BIT = 0,
  @PageNumber INT = 1,
  @PageSize INT = 100
AS
BEGIN
  SET NOCOUNT ON;
  IF @PageNumber < 1 SET @PageNumber = 1;
  IF @PageSize < 1 SET @PageSize = 100;
  ;WITH CTE AS (
    SELECT Id, SourceId, KhoiID, MonHocID, Title, Description, OrdinalNumber, MediaJson, RawJson,
      CreateUser, CreateTime, UpdateUser, UpdateTime, IsDeleted,
      ROW_NUMBER() OVER (ORDER BY OrdinalNumber ASC, Id ASC) AS rn
    FROM dbo.tblEL_QuestionBank_Group
    WHERE (@IncludeDeleted = 1 OR IsDeleted = 0)
      AND (@KhoiID IS NULL OR KhoiID = @KhoiID)
      AND (@MonHocID IS NULL OR MonHocID = @MonHocID)
  )
  SELECT Id, SourceId, KhoiID, MonHocID, Title, Description, OrdinalNumber, MediaJson, RawJson,
    CreateUser, CreateTime, UpdateUser, UpdateTime, IsDeleted
  FROM CTE
  WHERE rn BETWEEN ((@PageNumber - 1) * @PageSize) + 1 AND (@PageNumber * @PageSize)
  ORDER BY rn;
END