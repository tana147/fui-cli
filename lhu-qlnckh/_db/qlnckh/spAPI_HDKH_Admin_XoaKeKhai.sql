CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_XoaKeKhai] @SubmissionID INT,
@sys_UserID VARCHAR(9) AS BEGIN
SET
NOCOUNT ON;

IF NOT EXISTS (
    SELECT
        1
    FROM
        tblHDKH_KeKhai_Submission
    WHERE
        SubmissionID = @SubmissionID
        AND IsDeleted = 0
) BEGIN RAISERROR (N'Kê khai không tồn tại hoặc đã bị xoá', 16, 1) RETURN 0 END;

BEGIN TRY BEGIN TRANSACTION;

UPDATE tblHDKH_KeKhai_FieldValue
SET
    IsDeleted = 1,
    UpdateTime = GETDATE(),
    UpdateUser = @sys_UserID
WHERE
    SubmissionID = @SubmissionID;

UPDATE tblHDKH_KeKhai_KetQua_CaNhan
SET
    IsDeleted = 1,
    UpdateTime = GETDATE(),
    UpdateUser = @sys_UserID
WHERE
    SubmissionID = @SubmissionID;

UPDATE tblHDKH_KeKhai_Submission
SET
    IsDeleted = 1,
    UpdateTime = GETDATE(),
    UpdateUser = @sys_UserID
WHERE
    SubmissionID = @SubmissionID;

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

END TRY 
BEGIN CATCH 
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
DECLARE @ErrorState INT = ERROR_STATE()

RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)

END CATCH END;

