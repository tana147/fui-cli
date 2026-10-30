
CREATE   PROCEDURE dbo.spAPI_EL_Assignment_Ins
    @Title NVARCHAR(1000),
    @Instructions NVARCHAR(2000),
    @Chuong NVARCHAR(2000),
    @TuanHocID INT,
    @MonHocID INT,
    @KhoiID INT,
    @NienKhoa INT,
    @HocKi INT,
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET @SYS_USERID = [dbo].[fn_GetUser_LMS](@SYS_USERID);

    IF @Title IS NULL OR LTRIM(RTRIM(@Title)) = ''
       OR @TuanHocID IS NULL
       OR @MonHocID IS NULL
       OR @KhoiID IS NULL
       OR @NienKhoa IS NULL
    BEGIN
        RAISERROR(N'Dữ liệu không hợp lệ: thiếu Title / TuanHocID / MonHocID / KhoiID / NienKhoa.', 16, 1);
        RETURN;
    END;

    DECLARE @NewAssignmentID INT;

    INSERT INTO dbo.tblEL_Assignments
    (
        [Title],
        [Instructions],
        [Chuong],
        TuanHocID,
        MonHocID,
        KhoiID,
        [AssignmentConfig],
        [NienKhoa],
        [HocKi],
        [IsDeleted],
        [CreateTime],
        [CreateUser]
    )
    VALUES
    (
        @Title,
        @Instructions,
        @Chuong,
        @TuanHocID,
        @MonHocID,
        @KhoiID,
        NULL,
        @NienKhoa,
        @HocKi,
        0,
        GETDATE(),
        @SYS_USERID
    );

    SET @NewAssignmentID = SCOPE_IDENTITY();
    SELECT @NewAssignmentID AS AssignmentID;
END;
