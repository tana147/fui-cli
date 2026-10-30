-- =================================================================================
-- Description:    Giáo viên xác nhận học sinh đã hoàn thành bài học thủ công.
--                 Dùng cho trường hợp học sinh học xong nội dung trước
--                 EstimatedDuration nhưng chưa đủ thời gian tích lũy.
-- API Endpoint:   POST lms/EL_Teacher_MarkLearningProgressCompleted
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_MarkLearningProgressCompleted]
    @AssignToClassID BIGINT,
    @HocSinhID       INT,
    @sys_UserID      VARCHAR(9),
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    DECLARE @LessonID INT;
    DECLARE @LopHoacNhomID VARCHAR(100);
    DECLARE @MonHocID INT;
    DECLARE @NienKhoa INT;

    -- Chỉ giáo viên sở hữu lần giao bài hoặc tài khoản quyền cao mới được thao tác.
    SELECT
        @LessonID = atc.ResourceID,
        @LopHoacNhomID = mhl.LopNhomID,
        @MonHocID = mhl.MonHocID,
        @NienKhoa = COALESCE(atc.NienKhoa, dbo.fn_GetNienKhoa_HienTai())
    FROM dbo.tblEL_AssignToClass atc
    INNER JOIN dbo.tblMonHocLop mhl
        ON mhl.MonHocLopID = atc.MonHocLopID
       AND mhl.Enable = 1
    WHERE atc.AssignToClassID = @AssignToClassID
      AND atc.ResourceType = 'LESSON'
      AND (atc.CreateUser = @sys_UserID OR @sys_SystemRight IN (5, 9))
      AND atc.IsDeleted = 0;

    IF @LessonID IS NULL
    BEGIN
        RAISERROR(N'[Unauthorized] Không tìm thấy lần giao bài hoặc bạn không có quyền thao tác.', 16, 1);
        RETURN;
    END;

    -- Không cho đánh dấu học sinh ngoài lớp/nhóm đang được giao bài.
    DECLARE @IsNhom BIT = CASE WHEN TRY_CONVERT(INT, @LopHoacNhomID) IS NULL THEN 1 ELSE 0 END;
    IF @IsNhom = 1
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tblHocSinhNhom hsn
            INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsn.HocSinhID AND hs.TinhTrang = 0
            INNER JOIN dbo.tblNhom n
                ON n.NhomID = hsn.NhomID
               AND n.Enable = 1
               AND n.MonHocID = @MonHocID
               AND n.NienKhoa = @NienKhoa
            WHERE hsn.NhomID = @LopHoacNhomID
              AND hsn.HocSinhID = @HocSinhID
              AND hsn.Enable = 1
        )
        BEGIN
            RAISERROR(N'Học sinh không thuộc nhóm được giao bài.', 16, 1);
            RETURN;
        END;
    END;
    ELSE
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tblHocSinhLop hsl
            INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID AND hs.TinhTrang = 0
            INNER JOIN dbo.tblLop l ON l.LopID = hsl.LopID AND l.NienKhoa = @NienKhoa
            AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.LopID = @LopHoacNhomID
              AND hsl.HocSinhID = @HocSinhID
              AND (hsl.NienKhoa = @NienKhoa OR hsl.NienKhoa IS NULL)
              AND hsl.Enable = 1
        )
        AND NOT EXISTS
        (
            SELECT 1
            FROM dbo.tblHocSinhNhom hsn
            INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsn.HocSinhID AND hs.TinhTrang = 0
            INNER JOIN dbo.tblNhom n
                ON n.NhomID = hsn.NhomID
               AND n.NienKhoa = @NienKhoa
            WHERE hsn.NhomID = @LopHoacNhomID
              AND hsn.HocSinhID = @HocSinhID
              AND hsn.Enable = 1
        )
        BEGIN
            RAISERROR(N'Học sinh không thuộc lớp được giao bài.', 16, 1);
            RETURN;
        END;
    END;

    -- Bắt buộc học sinh đã mở bài và có progress đang dang dở. Không tạo progress mới
    -- cho học sinh chưa bắt đầu, để không thể đánh dấu hoàn thành từ trạng thái rỗng.
    DECLARE @ProgressID BIGINT;
    SELECT TOP (1) @ProgressID = ProgressID
    FROM dbo.tblEL_Learning_Progress
    WHERE LessonID = @LessonID
      AND HocSinhID = @HocSinhID
      AND ISNULL(IsDeleted, 0) = 0
      AND ISNULL(IsCompleted, 0) = 0
    ORDER BY ProgressID DESC;

    IF @ProgressID IS NULL
    BEGIN
        RAISERROR(N'Không thể xác nhận hoàn thành: học sinh chưa bắt đầu bài học hoặc đã hoàn thành trước đó.', 16, 1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.tblEL_Learning_Progress
        SET IsCompleted = 1,
            CompletedDate = ISNULL(CompletedDate, GETDATE()),
            CompletedByUserID = CASE
                WHEN ISNULL(IsCompleted, 0) = 0 THEN @sys_UserID
                ELSE CompletedByUserID
            END,
            CompletionSource = CASE
                WHEN ISNULL(IsCompleted, 0) = 0 THEN 'TEACHER_MANUAL'
                ELSE CompletionSource
            END,
            LastAccessed = GETDATE()
        WHERE ProgressID = @ProgressID
          AND ISNULL(IsDeleted, 0) = 0;

        -- Dùng cùng loại thông báo với luồng tự động khi bài học hoàn thành.
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tblEL_ThongBao
            WHERE ResourceID = @ProgressID
        )
        BEGIN
            INSERT INTO dbo.tblEL_ThongBao
            (
                ResourceType,
                ResourceID,
                ThongBao_TemplateID,
                NguoiNhan,
                ThoiGianNhan,
                NguoiGiao,
                ThoiGianGiao
            )
            VALUES
            (
                'LP',
                @ProgressID,
                13,
                @HocSinhID,
                GETDATE(),
                @HocSinhID,
                GETDATE()
            );
        END;

        COMMIT TRANSACTION;

        SELECT ProgressID, HocSinhID, LessonID, IsCompleted, CompletedDate, CompletedByUserID, CompletionSource
        FROM dbo.tblEL_Learning_Progress
        WHERE ProgressID = @ProgressID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
