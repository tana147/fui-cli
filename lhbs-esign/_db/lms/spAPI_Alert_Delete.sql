CREATE PROCEDURE spAPI_Alert_Delete
    @AlertID    INT,
    @SYS_USERID VARCHAR(9)      -- ghi log ai xóa
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM tblAlert WHERE AlertID = @AlertID)
    BEGIN
        RAISERROR(N'Không tìm thấy bản ghi AlertID = %d', 16, 1, @AlertID);
        RETURN;
    END

    update tblAlert SET
    Enable = 0,
	UpdateUser = @SYS_USERID,
	UpdateTime = GETDATE()
	WHERE AlertID = @AlertID;

    SELECT @@ROWCOUNT AS RowsAffected;
END