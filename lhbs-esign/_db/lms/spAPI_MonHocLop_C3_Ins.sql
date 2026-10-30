CREATE PROC [dbo].[spAPI_MonHocLop_C3_Ins]
    @JSON_DiemHocSinh NVARCHAR(MAX),
    @SYS_USERID VARCHAR(9)
AS
BEGIN

    DECLARE @Table_Diem_HocSinh TABLE
    (
        LopID INT,
        MonHocID VARCHAR(50),
        STT INT,
        TenLop VARCHAR(50),
        HocSinhID VARCHAR(9),
        HoTen NVARCHAR(200),
        NgaySinh VARCHAR(10),
        DTB FLOAT,
        TX1 FLOAT,
        TX2 FLOAT,
        TX3 FLOAT,
        TX4 FLOAT,
        TX5 FLOAT,
        GK FLOAT,
        CK FLOAT
    );
    INSERT INTO @Table_Diem_HocSinh
    (
        LopID,
        MonHocID,
        STT,
        TenLop,
        HocSinhID,
        HoTen,
        NgaySinh,
        DTB,
        TX1,
        TX2,
        TX3,
        TX4,
        TX5,
        GK,
        CK
    )
    SELECT LopID,
           MonHocID,
           STT,
           TenLop,
           HocSinhID,
           HoTen,
           NgaySinh,
           DTB,
           TX1,
           TX2,
           TX3,
           TX4,
           TX5,
           GK,
           CK
    FROM
        OPENJSON(@JSON_DiemHocSinh)
        WITH
        (
            LopID INT,
            MonHocID VARCHAR(50),
            STT INT,
            TenLop VARCHAR(50),
            HocSinhID VARCHAR(9),
            HoTen NVARCHAR(200),
            NgaySinh VARCHAR(10),
            DTB FLOAT,
            TX1 FLOAT,
            TX2 FLOAT,
            TX3 FLOAT,
            TX4 FLOAT,
            TX5 FLOAT,
            GK FLOAT,
            CK FLOAT
        );

    -- Merge data into the target table
    MERGE INTO dbo.tbl_QLDiem_Tam_C3 AS Target
    USING @Table_Diem_HocSinh AS Source
    ON Target.LopID = Source.LopID
       AND Target.MonHocID = Source.MonHocID
       AND Target.HocSinhID = Source.HocSinhID
    WHEN MATCHED THEN
        UPDATE SET Target.STT = Source.STT,
                   Target.TenLop = Source.TenLop,
                   Target.HoTen = Source.HoTen,
                   Target.NgaySinh = Source.NgaySinh,
                   Target.DTB = Source.DTB,
                   Target.TX1 = Source.TX1,
                   Target.TX2 = Source.TX2,
                   Target.TX3 = Source.TX3,
                   Target.TX4 = Source.TX4,
                   Target.TX5 = Source.TX5,
                   Target.GK = Source.GK,
                   Target.CK = Source.CK,
				   Target.Is_Update = 1,
                   Target.UpdateUser = @SYS_USERID,
                   Target.UpdateTime = GETDATE()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT
        (
            LopID,
            MonHocID,
            STT,
            TenLop,
            HocSinhID,
            HoTen,
            NgaySinh,
            DTB,
            TX1,
            TX2,
            TX3,
            TX4,
            TX5,
            GK,
            CK,
            Is_Insert,
            CreateUser,
            CreateTime
        )
        VALUES
        (Source.LopID, Source.MonHocID, Source.STT, Source.TenLop, Source.HocSinhID, Source.HoTen, Source.NgaySinh,
         Source.DTB, Source.TX1, Source.TX2, Source.TX3, Source.TX4, Source.TX5, Source.GK, Source.CK, 1, @SYS_USERID,
         GETDATE());

END;