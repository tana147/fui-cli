
--------------------------------------------------------------------------------
-- spAPI_EL_QuestionGroup_Create
--------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spAPI_EL_QuestionGroup_Create]
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
  BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.tblEL_QuestionBank_Group
      (SourceId, KhoiID, MonHocID, Title, Description, OrdinalNumber, MediaJson, RawJson, CreateUser, CreateTime, IsDeleted)
    VALUES
      (@SourceId, @KhoiID, @MonHocID, @Title, @Description, @OrdinalNumber, @MediaJson, @RawJson, @User, GETDATE(), 0);

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
