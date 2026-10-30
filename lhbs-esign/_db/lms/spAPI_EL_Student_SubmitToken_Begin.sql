
CREATE PROCEDURE [dbo].[spAPI_EL_Student_SubmitToken_Begin]
      @HocSinhID         INT
    , @AssignToClassID   INT = NULL
    , @AssignToStudentID INT = NULL
    , @sys_UserID        VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF (@AssignToClassID IS NULL AND @AssignToStudentID IS NULL)
    OR (@AssignToClassID IS NOT NULL AND @AssignToStudentID IS NOT NULL)
    BEGIN
        RAISERROR(N'Yeu cau token khong hop le: chi duoc chon 1 loai bai giao.', 16, 1);
        RETURN;
    END;

    -- TTL ngan: 30 giay
    DECLARE @Now DATETIME2(0) = SYSDATETIME();
    DECLARE @ExpireTime DATETIME2(0) = DATEADD(SECOND, 30, @Now);

    -- Don dep token het han/chua dung de tranh phinh bang.
    DELETE TOP (200)
    FROM dbo.tblEL_Student_SubmitTokens
    WHERE IsUsed = 0
      AND ExpireTime < DATEADD(MINUTE, -5, @Now);

    DECLARE @TokenBytes VARBINARY(32) = CRYPT_GEN_RANDOM(32);
    DECLARE @TokenPlain VARCHAR(128) = CONVERT(VARCHAR(128), @TokenBytes, 2); -- Hex string
    DECLARE @TokenHash VARBINARY(32) = HASHBYTES('SHA2_256', @TokenPlain);

    INSERT INTO dbo.tblEL_Student_SubmitTokens
    (
        AssignToClassID,
        AssignToStudentID,
        HocSinhID,
        TokenHash,
        ExpireTime,
        CreateUser
    )
    VALUES
    (
        @AssignToClassID,
        @AssignToStudentID,
        @HocSinhID,
        @TokenHash,
        @ExpireTime,
        @sys_UserID
    );

    SELECT
        @TokenPlain AS SubmitToken,
        @ExpireTime AS ExpireTime;
END;
