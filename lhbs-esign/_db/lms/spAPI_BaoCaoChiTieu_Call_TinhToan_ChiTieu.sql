-- EXEC [dbo].[spAPI_BaoCaoChiTieu_Call_TinhToan_ChiTieu] '1',2025,3,0
CREATE procedure [dbo].[spAPI_BaoCaoChiTieu_Call_TinhToan_ChiTieu]
    @Semester varchar(20) = '1',
 @NienKhoa int = 2025,
 @CapID int = 2,
 @Is_TA2 int = 0
    AS
    BEGIN
     DECLARE @MonHocID int
     IF(@CapID = 1)
        BEGIN
            SET @MonHocID = 5
        END
     ELSE IF(@CapID = 2)
        BEGIN
            SET @MonHocID = 46
        END
     ELSE
        BEGIN
            SET @MonHocID = 76
        END

         DECLARE @LopList TABLE
    (
        LopID VARCHAR(40)
    );

    -- Get all LopIDs for the given CapHoc and NienKhoa
    IF(@CapID = 3 AND @Is_TA2 = 1)
     BEGIN 
        INSERT INTO @LopList
    (
        LopID
    )
    VALUES
        ('N100000'),
        ('N251001,N251002'),
        ('N251003,N251004'),
        ('N251005'),
        ('N110000'),
        ('N251101,N251102'),
        ('N251103,N251104'),
        ('N251105'),
        ('N120000'),
        ('N251201,N251202'),
        ('N251203,N251204'),
        ('N251205,N251206')
    END
    ELSE IF(@CapID = 3 AND @Is_TA2 = 0)
    BEGIN
          INSERT INTO @LopList
    (
        LopID
    )
    VALUES
        ('N100000'),
        ('N251001'),('N251002'),
        ('N251003'),('N251004'),
        ('N251005'),
        ('N110000'),
        ('N251101'),('N251102'),
        ('N251103'),('N251104'),
        ('N251105'),
        ('N120000'),
        ('N251201'),('N251202'),
        ('N251203'),('N251204'),
        ('N251205'),('N251206')
    END
    ELSE 
    BEGIN

    DECLARE @TableLopC1C2 TABLE(LopID varchar(40),CapID INT)
    INSERT INTO @TableLopC1C2
     VALUES
    ('-625',2),   -- Khối 6
    ('-725',2),   -- Khối 7
    ('-825',2),   -- Khối 8
    ('-925',2),   -- Khối 9
    ('-125',1),   -- Khối 1
    ('-225',1),   -- Khối 2
    ('-325',1),   -- Khối 3
    ('-425',1),   -- Khối 4
    ('-525',1)    -- Khối 5

    -- Insert lớp
      INSERT INTO @LopList
    (
        LopID
    )
    SELECT LopID
    FROM
           dbo.tblLop
    WHERE
           CapID   = @CapID
      AND  NienKhoa = @NienKhoa
      AND  Enable   = 1
      -- Insert Khối
    UNION
    SELECT LopID 
    FROM @TableLopC1C2 
    WHERE CapID = @CapID

    END
  
       -- Declare cursor variables
    DECLARE @CurrentLopID VARCHAR(40);

    -- Create cursor to loop through each LopID
    DECLARE lop_cursor CURSOR FOR SELECT LopID FROM @LopList;

    OPEN lop_cursor;
    FETCH NEXT FROM lop_cursor
    INTO @CurrentLopID;

    -- Loop through each LopID
    WHILE @@FETCH_STATUS = 0
    BEGIN
    IF(@Is_TA2 = 0 AND @CapID in (2,3))
    BEGIN
         EXEC spAPI_BaoCaoChiTieu_Tinh_ChiTieuThucTe_TheoCap 
            @Semester = @Semester,
	        @NienKhoa  = @NienKhoa,
	        @MonHocID = @MonHocID,
	        @CapID = @CapID,
            @LopID = @CurrentLopID
    END
    ELSE IF(@Is_TA2 = 0 AND @CapID = 1)
    BEGIN
        EXEC spAPI_BaoCaoChiTieu_Tinh_ChiTieuThucTe_TA1_Cap1
                @Semester = @Semester,
	            @NienKhoa  = @NienKhoa,
                @LopID = @CurrentLopID
    END
    ELSE 
    BEGIn
               -- Call the child stored procedure and insert results
     EXEC spAPI_BaoCaoChiTieu_Tinh_ChiTieuThucTe_TA2_TheoCap 
            @Semester = @Semester,
	        @NienKhoa  = @NienKhoa,
	        @MonHocID = @MonHocID,
	        @CapID = @CapID,
            @LopID = @CurrentLopID
    END
     

        FETCH NEXT FROM lop_cursor
        INTO @CurrentLopID;
    END;

    CLOSE lop_cursor;
    DEALLOCATE lop_cursor;
    END
 