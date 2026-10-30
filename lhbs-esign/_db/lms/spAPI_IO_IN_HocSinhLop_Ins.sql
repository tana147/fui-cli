CREATE   PROC [dbo].[spAPI_IO_IN_HocSinhLop_Ins]
@HocSinhLopObjArr NVARCHAR(MAX),
@SYS_UserID VARCHAR(20),
@NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Bản ghi thành viên phải có năm học rõ ràng; không suy ra năm mới nhất từ LopID.
    IF (@NienKhoa IS NULL OR @NienKhoa = 0)
    BEGIN
        RAISERROR(N'NienKhoa là bắt buộc khi nhập học sinh vào lớp.', 16, 1);
        RETURN;
    END;

    IF EXISTS (
        SELECT 1
        FROM OPENJSON(@HocSinhLopObjArr) AS item
        LEFT JOIN dbo.tblLop AS l
          ON l.LopID = JSON_VALUE(item.value, '$.LopID')
         AND l.NienKhoa = COALESCE(TRY_CAST(JSON_VALUE(item.value, '$.NienKhoa') AS INT), @NienKhoa)
         AND l.Enable = 1
        WHERE l.LopID IS NULL
    )
    BEGIN
        RAISERROR(N'Có học sinh được nhập với cặp LopID và NienKhoa không tồn tại.', 16, 1);
        RETURN;
    END;

    DECLARE @ClassChanges TABLE
    (
        ChangeAction nvarchar(10) NOT NULL,
        HocSinhID int NULL,
        HSLopIDCu int NULL,
        HSLopIDMoi int NULL,
        LopCuID varchar(10) NULL,
        LopMoiID varchar(10) NULL,
        NienKhoaCu int NULL,
        NienKhoaMoi int NULL
    );

    BEGIN TRANSACTION;
        MERGE INTO [dbo].[tblHocSinhLop] AS target
        USING (
            SELECT
                JSON_VALUE(value, '$.HSLopID') AS HSLopID,
                JSON_VALUE(value, '$.HocSinhID') AS HocSinhID,
                JSON_VALUE(value, '$.LopID') AS LopID,
                JSON_VALUE(value, '$.SoDanhBo') AS SoDanhBo,
                JSON_VALUE(value, '$.CreateUser') AS CreateUser,
                JSON_VALUE(value, '$.CreateTime') AS CreateTime,
                JSON_VALUE(value, '$.UpdateUser') AS UpdateUser,
                JSON_VALUE(value, '$.UpdateTime') AS UpdateTime,
                COALESCE(
                    TRY_CAST(JSON_VALUE(value, '$.NienKhoa') AS INT),
                    @NienKhoa
                ) AS NienKhoa
            FROM OPENJSON(@HocSinhLopObjArr)
        ) AS source
        ON target.HSLopID = source.HSLopID
        WHEN MATCHED THEN
            UPDATE SET 
                target.HocSinhID = source.HocSinhID,
                target.LopID = source.LopID,
                target.SoDanhBo = source.SoDanhBo,
                target.UpdateUser = source.UpdateUser,
                target.UpdateTime = source.UpdateTime,
                target.NienKhoa = COALESCE(source.NienKhoa, target.NienKhoa)
        WHEN NOT MATCHED THEN
            INSERT ([HSLopID], [HocSinhID], [LopID], [SoDanhBo], [CreateUser], [CreateTime], [UpdateUser], [UpdateTime], [NienKhoa])
            VALUES (source.[HSLopID], source.[HocSinhID], source.[LopID], source.[SoDanhBo], source.[CreateUser], source.[CreateTime], source.[UpdateUser], source.[UpdateTime], source.[NienKhoa])
        OUTPUT
            $action,
            inserted.HocSinhID,
            deleted.HSLopID,
            inserted.HSLopID,
            CONVERT(varchar(10), deleted.LopID),
            CONVERT(varchar(10), inserted.LopID),
            deleted.NienKhoa,
            inserted.NienKhoa
        INTO @ClassChanges;

        -- Save an audit row before committing any real class change; enrollment-only inserts are logged when a prior class exists.
        INSERT INTO dbo.tblHocSinhLop_LichSuChuyenLop
        (
            HocSinhID, HSLopIDCu, HSLopIDMoi, LopCuID, TenLopCu, LopMoiID, TenLopMoi,
            NienKhoaCu, NienKhoaMoi, KieuThayDoi, NguoiChuyen, NguonThaoTac
        )
        SELECT
            changeRow.HocSinhID,
            CASE WHEN changeRow.ChangeAction = N'UPDATE' THEN changeRow.HSLopIDCu ELSE priorClass.HSLopIDCu END,
            changeRow.HSLopIDMoi,
            CASE WHEN changeRow.ChangeAction = N'UPDATE' THEN changeRow.LopCuID ELSE priorClass.LopCuID END,
            oldClass.TenLop,
            changeRow.LopMoiID,
            newClass.TenLop,
            CASE WHEN changeRow.ChangeAction = N'UPDATE' THEN changeRow.NienKhoaCu ELSE priorClass.NienKhoaCu END,
            changeRow.NienKhoaMoi,
            CASE WHEN changeRow.ChangeAction = N'UPDATE' THEN 'UPDATE_ROW' ELSE 'INSERT_WITH_PRIOR_CLASS' END,
            @SYS_UserID,
            'spAPI_IO_IN_HocSinhLop_Ins'
        FROM @ClassChanges AS changeRow
        OUTER APPLY
        (
            SELECT TOP (1)
                HSLopIDCu = prior.HSLopID,
                LopCuID = CONVERT(varchar(10), prior.LopID),
                NienKhoaCu = prior.NienKhoa
            FROM dbo.tblHocSinhLop AS prior WITH (UPDLOCK, HOLDLOCK)
            WHERE changeRow.ChangeAction = N'INSERT'
              AND prior.HocSinhID = changeRow.HocSinhID
              AND prior.NienKhoa = changeRow.NienKhoaMoi
              AND prior.HSLopID <> changeRow.HSLopIDMoi
              AND CONVERT(varchar(10), prior.LopID) <> changeRow.LopMoiID
            ORDER BY CASE WHEN prior.Enable = 1 THEN 0 ELSE 1 END,
                     ISNULL(prior.UpdateTime, prior.CreateTime) DESC,
                     prior.HSLopID DESC
        ) AS priorClass
        LEFT JOIN dbo.tblLop AS oldClass
          ON CONVERT(varchar(10), oldClass.LopID) = CASE WHEN changeRow.ChangeAction = N'UPDATE' THEN changeRow.LopCuID ELSE priorClass.LopCuID END
         AND oldClass.NienKhoa = CASE WHEN changeRow.ChangeAction = N'UPDATE' THEN changeRow.NienKhoaCu ELSE priorClass.NienKhoaCu END
        LEFT JOIN dbo.tblLop AS newClass
          ON CONVERT(varchar(10), newClass.LopID) = changeRow.LopMoiID
         AND newClass.NienKhoa = changeRow.NienKhoaMoi
        WHERE
            (
                changeRow.ChangeAction = N'UPDATE'
                AND changeRow.LopCuID IS NOT NULL
                AND changeRow.LopCuID <> changeRow.LopMoiID
            )
            OR
            (
                changeRow.ChangeAction = N'INSERT'
                AND priorClass.HSLopIDCu IS NOT NULL
            );

    COMMIT TRANSACTION;
END


