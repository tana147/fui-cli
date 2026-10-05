CREATE  PROCEDURE [dbo].[spAPI_HDKH_KeKhai_Delete]
    @SubmissionID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        
        -- Xóa mềm bản ghi cha
        UPDATE dbo.tblHDKH_KeKhai_Submission
        SET IsDeleted = 1, UpdateTime = GETDATE(), UpdateUser = @sys_UserID
        WHERE SubmissionID = @SubmissionID AND TrangThaiDuyet = 'CHO_DUYET';
        
        IF @@ROWCOUNT = 0 BEGIN
            RAISERROR(N'Không thể xóa. Hoạt động không tồn tại hoặc đã được duyệt.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Xóa mềm các bản ghi con
        UPDATE dbo.tblHDKH_KeKhai_FieldValue SET IsDeleted = 1, UpdateTime = GETDATE(), UpdateUser = @sys_UserID WHERE SubmissionID = @SubmissionID;
        UPDATE dbo.tblHDKH_KeKhai_KetQua_CaNhan SET IsDeleted = 1, UpdateTime = GETDATE(), UpdateUser = @sys_UserID WHERE SubmissionID = @SubmissionID;
        UPDATE tblHDKH_KeKhai_Submission_MinhChung
            SET
                IsDeleted = 1,
                UpdateTime = GETDATE(),
                UpdateUser = @sys_UserID
            WHERE
                SubmissionID = @SubmissionID;

            UPDATE tblHDKH_KeKhai_ThanhVien
            SET
                IsDeleted = 1,
                UpdateTime = GETDATE(),
                UpdateUser = @sys_UserID
            WHERE
                SubmissionID = @SubmissionID;
        
        COMMIT TRANSACTION;
        SELECT Message = N'Xóa hoạt động thành công.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END
