
CREATE   PROCEDURE dbo.spAPI_FP_NoiDung_Save_Audited
    @NoiDungID INT,
    @HocLieuID INT,
    @ParentID INT,
    @TenNoiDung NVARCHAR(500),
    @LoaiNoiDung VARCHAR(50),
    @ThuTu INT,
    @DataJson NVARCHAR(MAX),
    @OperationID UNIQUEIDENTIFIER,
    @OperationName NVARCHAR(150),
    @SourceModule VARCHAR(100),
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        EXEC sys.sp_set_session_context @key = N'HocLieu.OperationID', @value = @OperationID;
        EXEC sys.sp_set_session_context @key = N'HocLieu.OperationName', @value = @OperationName;
        EXEC sys.sp_set_session_context @key = N'HocLieu.SourceModule', @value = @SourceModule;
        EXEC sys.sp_set_session_context @key = N'HocLieu.ActorUserID', @value = @sys_UserID;

        EXEC dbo.spAPI_FP_NoiDung_Save
            @NoiDungID = @NoiDungID,
            @HocLieuID = @HocLieuID,
            @ParentID = @ParentID,
            @TenNoiDung = @TenNoiDung,
            @LoaiNoiDung = @LoaiNoiDung,
            @ThuTu = @ThuTu,
            @DataJson = @DataJson,
            @sys_UserID = @sys_UserID;

        EXEC sys.sp_set_session_context @key = N'HocLieu.OperationID', @value = NULL;
        EXEC sys.sp_set_session_context @key = N'HocLieu.OperationName', @value = NULL;
        EXEC sys.sp_set_session_context @key = N'HocLieu.SourceModule', @value = NULL;
        EXEC sys.sp_set_session_context @key = N'HocLieu.ActorUserID', @value = NULL;
    END TRY
    BEGIN CATCH
        EXEC sys.sp_set_session_context @key = N'HocLieu.OperationID', @value = NULL;
        EXEC sys.sp_set_session_context @key = N'HocLieu.OperationName', @value = NULL;
        EXEC sys.sp_set_session_context @key = N'HocLieu.SourceModule', @value = NULL;
        EXEC sys.sp_set_session_context @key = N'HocLieu.ActorUserID', @value = NULL;
        THROW;
    END CATCH
END;
