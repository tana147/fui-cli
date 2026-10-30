CREATE PROC [dbo].[spAPI_AUTH_HocSinhLop_Upd]
    @Json_HocSinhLop NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Table_HSL TABLE
    (
        HSLopID INT,
        HocSinhID INT,
        LopID VARCHAR(10),
        SoDanhBo VARCHAR(10),
        [Enable] bit,
        CreateUser VARCHAR(20),
        CreateTime DATETIME,
        UpdateUser VARCHAR(20),
        UpdateTime DATETIME
    );

    INSERT INTO @Table_HSL
    (
        HSLopID, HocSinhID, LopID, SoDanhBo, [Enable],
        CreateUser, CreateTime, UpdateUser, UpdateTime
    )
    SELECT
        HSLopID, HocSinhID, LopID, SoDanhBo, [Enable],
        CreateUser, CreateTime, UpdateUser, UpdateTime
    FROM OPENJSON(@Json_HocSinhLop)
    WITH
    (
        HSLopID INT,
        HocSinhID INT,
        LopID VARCHAR(10),
        SoDanhBo VARCHAR(10),
        [Enable] bit,
        CreateUser VARCHAR(20),
        CreateTime DATETIME,
        UpdateUser VARCHAR(20),
        UpdateTime DATETIME
    );

    DECLARE @ClassChanges TABLE
    (
        HocSinhID int NULL,
        HSLopIDCu int NULL,
        HSLopIDMoi int NULL,
        LopCuID varchar(10) NULL,
        LopMoiID varchar(10) NULL,
        NienKhoaCu int NULL,
        NienKhoaMoi int NULL,
        NguoiChuyen varchar(20) NULL
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE hsl
        SET
            HocSinhID = t.HocSinhID,
            LopID = t.LopID,
            SoDanhBo = t.SoDanhBo,
            UpdateUser = t.UpdateUser,
            UpdateTime = t.UpdateTime
        OUTPUT
            inserted.HocSinhID,
            deleted.HSLopID,
            inserted.HSLopID,
            CONVERT(varchar(10), deleted.LopID),
            CONVERT(varchar(10), inserted.LopID),
            deleted.NienKhoa,
            inserted.NienKhoa,
            inserted.UpdateUser
        INTO @ClassChanges
        FROM dbo.tblHocSinhLop AS hsl
        INNER JOIN @Table_HSL AS t ON t.HSLopID = hsl.HSLopID;

        -- Keep the class change and its audit row in the same transaction.
        INSERT INTO dbo.tblHocSinhLop_LichSuChuyenLop
        (
            HocSinhID, HSLopIDCu, HSLopIDMoi, LopCuID, TenLopCu, LopMoiID, TenLopMoi,
            NienKhoaCu, NienKhoaMoi, KieuThayDoi, NguoiChuyen, NguonThaoTac
        )
        SELECT
            changeRow.HocSinhID,
            changeRow.HSLopIDCu,
            changeRow.HSLopIDMoi,
            changeRow.LopCuID,
            oldClass.TenLop,
            changeRow.LopMoiID,
            newClass.TenLop,
            changeRow.NienKhoaCu,
            changeRow.NienKhoaMoi,
            'UPDATE_ROW',
            changeRow.NguoiChuyen,
            'spAPI_AUTH_HocSinhLop_Upd'
        FROM @ClassChanges AS changeRow
        LEFT JOIN dbo.tblLop AS oldClass
          ON CONVERT(varchar(10), oldClass.LopID) = changeRow.LopCuID
         AND oldClass.NienKhoa = changeRow.NienKhoaCu
        LEFT JOIN dbo.tblLop AS newClass
          ON CONVERT(varchar(10), newClass.LopID) = changeRow.LopMoiID
         AND newClass.NienKhoa = changeRow.NienKhoaMoi
        WHERE changeRow.LopCuID IS NOT NULL
          AND changeRow.LopCuID <> changeRow.LopMoiID;

        INSERT INTO dbo.tblHocSinhLop
        (
            HSLopID, HocSinhID, LopID, SoDanhBo, [Enable], CreateUser, CreateTime
        )
        SELECT
            t.HSLopID, t.HocSinhID, t.LopID, t.SoDanhBo, t.[Enable], t.CreateUser, t.CreateTime
        FROM @Table_HSL AS t
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.tblHocSinhLop AS existing
            WHERE existing.HSLopID = t.HSLopID
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage nvarchar(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH;
END;
