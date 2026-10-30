CREATE   PROCEDURE [dbo].[spAPI_DongBo_Lop_From_Edubot]
    @HocSinhJSON NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @TableJSON TABLE (
        LopID VARCHAR(10),
        MaDonVi INT,
        TenLop VARCHAR(20),
        KhoiID INT,
        KhoiPhanBanID INT,
        TenKhoiPhanBan NVARCHAR(100),
        NienKhoa INT,
        GVCN VARCHAR(20),
        Enable BIT,
        CreateUser VARCHAR(20),
        CreateTime DATETIME,
        UpdateUser VARCHAR(20),
        UpdateTime DATETIME,
        CapID INT,
        LopIDQLD INT,
        IsLopToHop BIT
    );

    INSERT INTO @TableJSON (
        LopID, MaDonVi, TenLop, KhoiID, KhoiPhanBanID, TenKhoiPhanBan,
        NienKhoa, GVCN, Enable, CreateUser, CreateTime, UpdateUser,
        UpdateTime, CapID, LopIDQLD, IsLopToHop
    )
    SELECT
        j.LopID,
        j.MaDonVi,
        j.TenLop,
        j.KhoiID,
        j.KhoiPhanBanID,
        j.TenKhoiPhanBan,
        j.NienKhoa,
        j.GVCN,
        j.Enable,
        j.CreateUser,
        j.CreateTime,
        j.UpdateUser,
        j.UpdateTime,
        CASE
            WHEN j.KhoiID < 6 THEN 1
            WHEN j.KhoiID BETWEEN 6 AND 9 THEN 2
            WHEN j.KhoiID BETWEEN 10 AND 12 THEN 3
        END,
        j.LopIDQLD,
        ISNULL(j.IsLopToHop, 0)
    FROM OPENJSON(@HocSinhJSON)
    WITH (
        LopID VARCHAR(10),
        MaDonVi INT,
        TenLop VARCHAR(20),
        KhoiID INT,
        KhoiPhanBanID INT,
        TenKhoiPhanBan NVARCHAR(100),
        NienKhoa INT,
        GVCN VARCHAR(20),
        Enable BIT,
        CreateUser VARCHAR(20),
        CreateTime DATETIME,
        UpdateUser VARCHAR(20),
        UpdateTime DATETIME,
        CapID INT,
        LopIDQLD INT,
        IsLopToHop BIT
    ) AS j;

    BEGIN TRANSACTION;

    IF EXISTS (SELECT 1 FROM @TableJSON WHERE IsLopToHop = 1 AND KhoiID BETWEEN 10 AND 12)
    BEGIN
        UPDATE l
        SET l.Enable = 0,
            l.UpdateUser = 'DongBoLop',
            l.UpdateTime = GETDATE()
        FROM dbo.tblLop AS l
        WHERE l.NienKhoa IN (SELECT DISTINCT NienKhoa FROM @TableJSON)
          AND l.KhoiID BETWEEN 10 AND 12
          AND l.IsLopToHop = 0
          AND l.Enable = 1;
    END;

    UPDATE l
    SET
        l.MaDonVi = t.MaDonVi,
        l.TenLop = t.TenLop,
        l.KhoiID = t.KhoiID,
        l.PhanBanID = t.KhoiPhanBanID,
        l.TenKhoiPhanBan = t.TenKhoiPhanBan,
        l.NienKhoa = t.NienKhoa,
        l.GVCN = t.GVCN,
        l.Enable = t.Enable,
        l.CreateUser = t.CreateUser,
        l.CreateTime = t.CreateTime,
        l.UpdateUser = t.UpdateUser,
        l.UpdateTime = t.UpdateTime,
        l.CapID = t.CapID,
        l.LopIDQLD = t.LopIDQLD,
        l.IsLopToHop = t.IsLopToHop
    FROM dbo.tblLop AS l
    INNER JOIN @TableJSON AS t ON t.LopID = l.LopID AND t.NienKhoa = l.NienKhoa;

    INSERT INTO dbo.tblLop (
        LopID, MaDonVi, TenLop, KhoiID, PhanBanID, TenKhoiPhanBan,
        NienKhoa, GVCN, Enable, CreateUser, CreateTime, UpdateUser,
        UpdateTime, CapID, LopIDQLD, IsLopToHop
    )
    SELECT
        t.LopID, t.MaDonVi, t.TenLop, t.KhoiID, t.KhoiPhanBanID, t.TenKhoiPhanBan,
        t.NienKhoa, t.GVCN, t.Enable, t.CreateUser, t.CreateTime, t.UpdateUser,
        t.CreateTime, t.CapID, ISNULL(t.LopIDQLD, TRY_CONVERT(INT, t.LopID)), t.IsLopToHop
    FROM @TableJSON AS t
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.tblLop AS l WHERE l.LopID = t.LopID AND l.NienKhoa = t.NienKhoa
    );

    COMMIT TRANSACTION;
END;
GRANT EXECUTE ON [dbo].[spAPI_DongBo_Lop_From_Edubot] TO [lmslhbs];