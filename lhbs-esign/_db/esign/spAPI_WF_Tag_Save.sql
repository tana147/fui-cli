CREATE PROCEDURE [dbo].[spAPI_WF_Tag_Save]
    @sys_UserID VARCHAR(9),
    @Tag VARCHAR(50),
    @TagName NVARCHAR(200),
    @Color VARCHAR(20) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate fields
    IF ISNULL(@Tag, '') = '' 
    BEGIN 
        RAISERROR(N'Mã nhãn không được để trống.', 16, 1); 
        RETURN; 
    END

    IF ISNULL(@TagName, '') = '' 
    BEGIN 
        RAISERROR(N'Tên nhãn không được để trống.', 16, 1); 
        RETURN; 
    END

    -- Route to INSERT or UPDATE
    IF EXISTS (SELECT 1 FROM dbo.tblWF_Tag WHERE Tag = @Tag)
    BEGIN
        -- Cập nhật thông tin nhãn (kể cả hồi phục Enable)
        UPDATE dbo.tblWF_Tag
        SET TagName     = @TagName,
            Color       = @Color,
            UpdateUser  = @sys_UserID,
            UpdateTime  = GETDATE(),
            [Enable]    = @IsActive
        WHERE Tag = @Tag;
    END
    ELSE
    BEGIN
        -- Thêm mới nhãn
        INSERT INTO dbo.tblWF_Tag
            (Tag, TagName, Color, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable])
        VALUES
            (@Tag, @TagName, @Color, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), @IsActive);
    END

    SELECT Message = N'Lưu nhãn thành công.', Tag = @Tag;
END

