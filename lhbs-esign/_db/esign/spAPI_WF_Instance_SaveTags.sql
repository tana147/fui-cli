CREATE PROCEDURE [dbo].[spAPI_WF_Instance_SaveTags]
    @sys_UserID VARCHAR(9),
    @InstanceID BIGINT,
    @Tags NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Kiểm tra tồn tại
        IF NOT EXISTS (SELECT 1 FROM dbo.tblWF_Instance WHERE InstanceID = @InstanceID AND [Enable] = 1)
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Không tìm thấy hồ sơ hoặc đã bị xóa.' AS Message;
            RETURN;
        END

        UPDATE dbo.tblWF_Instance
        SET TagIDList = @Tags,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID
          AND [Enable] = 1;

        SELECT CAST(1 AS BIT) AS Success, N'Cập nhật nhãn thành công.' AS Message;
    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END

