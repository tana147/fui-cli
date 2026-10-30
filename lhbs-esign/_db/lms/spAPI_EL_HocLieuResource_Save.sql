
CREATE   PROCEDURE dbo.spAPI_EL_HocLieuResource_Save
    @ResourceType VARCHAR(20),
    @ResourceID INT,
    @HocLieuID INT = NULL,
    @NoiDungID INT = NULL,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @ResourceType = UPPER(LTRIM(RTRIM(@ResourceType)));

    IF @ResourceType NOT IN ('LESSON', 'ASSIGNMENT') OR @ResourceID IS NULL OR @ResourceID <= 0
        THROW 51001, N'Loại hoặc mã nội dung LMS không hợp lệ.', 1;

    IF @HocLieuID IS NULL OR @NoiDungID IS NULL
    BEGIN
        UPDATE dbo.tblEL_HocLieuResourceMapping
        SET IsDeleted = 1, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE ResourceType = @ResourceType AND ResourceID = @ResourceID AND IsDeleted = 0;
        SELECT @ResourceID AS ResourceID, @ResourceType AS ResourceType, CAST(0 AS BIT) AS IsLinked;
        RETURN;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.tblHocLieu_FP
        WHERE HocLieuID = @HocLieuID AND Loai = 'HOC_LIEU' AND Is_Xoa = 0
    )
        THROW 51002, N'Chỉ được liên kết với học liệu số loại HOC_LIEU.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.tblNoiDungHocLieu_FP
        WHERE NoiDungID = @NoiDungID AND HocLieuID = @HocLieuID
          AND LoaiNoiDung IN ('CHUONG', 'BAI', 'NHOM_KY_NANG') AND Is_Xoa = 0
    )
        THROW 51003, N'Vị trí học liệu không hợp lệ; hãy chọn node CHUONG, BAI hoặc NHOM_KY_NANG.', 1;

    BEGIN TRANSACTION;
        IF EXISTS (
            SELECT 1 FROM dbo.tblEL_HocLieuResourceMapping
            WHERE ResourceType = @ResourceType AND ResourceID = @ResourceID AND IsDeleted = 0
        )
        BEGIN
            UPDATE dbo.tblEL_HocLieuResourceMapping
            SET HocLieuID = @HocLieuID, NoiDungID = @NoiDungID,
                UpdateUser = @sys_UserID, UpdateTime = GETDATE()
            WHERE ResourceType = @ResourceType AND ResourceID = @ResourceID AND IsDeleted = 0;
        END
        ELSE
        BEGIN
            UPDATE dbo.tblEL_HocLieuResourceMapping
            SET IsDeleted = 0, HocLieuID = @HocLieuID, NoiDungID = @NoiDungID,
                UpdateUser = @sys_UserID, UpdateTime = GETDATE()
            WHERE ResourceType = @ResourceType AND ResourceID = @ResourceID AND IsDeleted = 1;

            IF @@ROWCOUNT = 0
                INSERT INTO dbo.tblEL_HocLieuResourceMapping
                    (ResourceType, ResourceID, HocLieuID, NoiDungID, CreateUser, CreateTime)
                VALUES (@ResourceType, @ResourceID, @HocLieuID, @NoiDungID, @sys_UserID, GETDATE());
        END;
    COMMIT TRANSACTION;

    EXEC dbo.spAPI_EL_HocLieuResource_Get @ResourceType, @ResourceID;
END;
