CREATE PROC [dbo].[spAPI_AUTH_QLDiem_DiemThi_Ins_Upd]
    @HocSinhID       INT
  , @MonHocID        NVARCHAR(100)
  , @DiemThi         DECIMAL(10, 2)
  , @NienKhoa        INT
  , @DiemTrungBinh   DECIMAL(10, 2) -- Gửi NULL cho cấp 1; bắt buộc với cấp 2 và cấp 3.
  , @HocKi           VARCHAR(10)
  , @sys_UserID      VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- AUTH có thể không có user đăng nhập; dùng nhãn dịch vụ để lưu dấu vết tích hợp.
    DECLARE @AuditUserID VARCHAR(9) = ISNULL(NULLIF(LTRIM(RTRIM(@sys_UserID)), ''), 'QLDIEM');
    -- Giữ key API MonHocID theo payload qlDiem; giá trị thực là tblMonHoc.MonHocCode.
    DECLARE @MonHocCode NVARCHAR(100) = NULLIF(LTRIM(RTRIM(@MonHocID)), N'');

    DECLARE @HocKiCode VARCHAR(10) = UPPER(LTRIM(RTRIM(@HocKi)));
    DECLARE @Semester VARCHAR(10);
    DECLARE @LoaiKy VARCHAR(2);
    DECLARE @ExamPrefix VARCHAR(20);
    DECLARE @AltExamPrefix VARCHAR(20);
    DECLARE @CustomExamSuffix VARCHAR(40);
    DECLARE @TA2AggregateSuffix VARCHAR(50);
    DECLARE @GeneralAverageCode VARCHAR(30);

    IF @HocSinhID IS NULL OR @HocSinhID <= 0
       OR @MonHocCode IS NULL OR LEN(@MonHocCode) > 8
       OR @NienKhoa IS NULL OR @NienKhoa <= 0
       OR @DiemThi IS NULL
       OR @HocKiCode IS NULL
    BEGIN
        RAISERROR(N'Thiếu hoặc sai tham số bắt buộc.', 16, 1);
        RETURN;
    END;

    IF @HocKiCode NOT IN ('GK_HK1', 'CK_HK1', 'GK_HK2', 'CK_HK2')
    BEGIN
        RAISERROR(N'HocKi không hợp lệ. Chỉ nhận GK_HK1, CK_HK1, GK_HK2, CK_HK2.', 16, 1);
        RETURN;
    END;

    SET @Semester = CASE WHEN RIGHT(@HocKiCode, 3) = 'HK1' THEN 'HK1' ELSE 'HK2' END;
    SET @LoaiKy = LEFT(@HocKiCode, 2);
    SET @ExamPrefix = CASE WHEN @LoaiKy = 'GK' THEN 'DiemGK' ELSE 'DiemCK' END;
    SET @AltExamPrefix = CASE WHEN @LoaiKy = 'GK' THEN 'DiemCD1' ELSE 'DiemCD2' END;
    SET @CustomExamSuffix = CASE WHEN @LoaiKy = 'GK' THEN '%Mid_Total_Point' ELSE '%Final_Total_Point' END;
    SET @TA2AggregateSuffix = CASE WHEN @LoaiKy = 'GK' THEN '%Mid_TA2_Avg_Point' ELSE '%Final_TA2_Avg_Point' END;
    SET @GeneralAverageCode = 'DiemTB_' + @Semester;

    -- Lớp chính của học sinh dùng cho LopID ở bản ghi điểm.
    DECLARE @StudentClass TABLE
    (
        LopID VARCHAR(10) NOT NULL,
        CapID INT NULL
    );

    INSERT INTO @StudentClass (LopID, CapID)
    SELECT DISTINCT hsl.LopID, l.CapID
    FROM dbo.tblHocSinhLop hsl
    INNER JOIN dbo.tblLop l
        ON l.LopID = hsl.LopID
       AND l.NienKhoa = hsl.NienKhoa
       AND l.Enable = 1
    INNER JOIN dbo.tblHocSinh hs
        ON hs.HocSinhID = hsl.HocSinhID
       AND hs.TinhTrang = 0
    WHERE hsl.HocSinhID = @HocSinhID
      AND hsl.NienKhoa = @NienKhoa
      AND hsl.Enable = 1;

    IF NOT EXISTS (SELECT 1 FROM @StudentClass)
    BEGIN
        RAISERROR(N'Không tìm thấy học sinh đang học trong niên khóa này.', 16, 1);
        RETURN;
    END;

    -- Theo quy ước hiện tại, chỉ C3 có môn tổ chức theo nhóm.
    -- Tra MonHocLopID của C3 qua tblHocSinhNhom -> tblNhom; các môn còn lại tra theo lớp.
    DECLARE @Course TABLE
    (
        MonHocID INT NOT NULL,
        MonHocLopID INT NOT NULL,
        -- LopID lưu điểm là NhomID với môn nhóm, theo luồng kéo điểm C3.
        LopID VARCHAR(50) NOT NULL,
        StudentLopID VARCHAR(10) NOT NULL,
        TemplateBangDiemID INT NOT NULL,
        CapID INT NULL
    );

    INSERT INTO @Course (MonHocID, MonHocLopID, LopID, StudentLopID, TemplateBangDiemID, CapID)
    SELECT DISTINCT mh.MonHocID, mhl.MonHocLopID, CONVERT(VARCHAR(50), hsn.NhomID), sc.LopID, mhl.TemplateBangDiemID, sc.CapID
    FROM @StudentClass sc
    INNER JOIN dbo.tblMonHoc mh
        ON mh.MonHocCode = @MonHocCode
       AND mh.CapID = sc.CapID
       AND mh.Enable = 1
    INNER JOIN dbo.tblNhom n
        ON n.MonHocID = mh.MonHocID
       AND n.NienKhoa = @NienKhoa
       AND n.CapID = sc.CapID
       AND n.Enable = 1
       AND n.IsNhomLMS_GiaoBai = 0
    INNER JOIN dbo.tblHocSinhNhom hsn
        ON hsn.HocSinhID = @HocSinhID
       AND hsn.LopID = TRY_CONVERT(INT, sc.LopID)
       AND hsn.NhomID = n.NhomID
       AND hsn.Enable = 1
    INNER JOIN dbo.tblMonHocLop mhl
        ON mhl.LopNhomID = CONVERT(VARCHAR(50), hsn.NhomID)
       AND mhl.MonHocID = mh.MonHocID
       AND mhl.NienKhoa = @NienKhoa
       AND mhl.Enable = 1
    WHERE sc.CapID = 3

    UNION

    SELECT DISTINCT mh.MonHocID, mhl.MonHocLopID, sc.LopID, sc.LopID, mhl.TemplateBangDiemID, sc.CapID
    FROM @StudentClass sc
    INNER JOIN dbo.tblMonHoc mh
        ON mh.MonHocCode = @MonHocCode
       AND mh.CapID = sc.CapID
       AND mh.Enable = 1
    INNER JOIN dbo.tblMonHocLop mhl
        ON mhl.LopNhomID = sc.LopID
       AND mhl.MonHocID = mh.MonHocID
       AND mhl.NienKhoa = @NienKhoa
       AND mhl.Enable = 1
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.tblNhom n
        WHERE n.MonHocID = mh.MonHocID
          AND n.NienKhoa = @NienKhoa
          AND n.CapID = sc.CapID
          AND n.Enable = 1
          AND n.IsNhomLMS_GiaoBai = 0
    );

    DECLARE @CourseCount INT;
    SELECT @CourseCount = COUNT(*) FROM @Course;

    IF @CourseCount = 0
    BEGIN
        RAISERROR(N'Không tìm thấy lớp học phần của học sinh cho MonHocCode và niên khóa đã gửi.', 16, 1);
        RETURN;
    END;

    IF @CourseCount > 1
    BEGIN
        RAISERROR(N'Học sinh đang có nhiều lớp học phần phù hợp với môn học này; không thể xác định duy nhất bản ghi điểm từ bộ tham số hiện tại.', 16, 1);
        RETURN;
    END;

    DECLARE @MonHocLopID INT;
    DECLARE @LmsMonHocID INT;
    DECLARE @LopID VARCHAR(50);
    DECLARE @StudentLopID VARCHAR(10);
    DECLARE @CapID INT;
    DECLARE @TemplateBangDiemID INT;

    SELECT
        @LmsMonHocID = MonHocID,
        @MonHocLopID = MonHocLopID,
        @LopID = LopID,
        @StudentLopID = StudentLopID,
        @CapID = CapID,
        @TemplateBangDiemID = TemplateBangDiemID
    FROM @Course;

    -- tblKetQuaHocTap.LopID hiện có độ dài varchar(10); chặn NhomID dài hơn thay vì lưu sai.
    IF LEN(@LopID) > 10
    BEGIN
        RAISERROR(N'LopID/NhomID vượt quá độ dài cho phép của tblKetQuaHocTap.LopID.', 16, 1);
        RETURN;
    END;

    IF @CapID NOT IN (1, 2, 3)
    BEGIN
        RAISERROR(N'API điểm thi hiện chỉ hỗ trợ học sinh cấp 1, cấp 2 và cấp 3.', 16, 1);
        RETURN;
    END;

    -- C1 kế thừa danh sách môn thi của luồng kéo điểm cũ; bổ sung STEM (MonHocID=36)
    -- theo template C1 đã xác nhận. Bên dưới vẫn bắt buộc có đúng cột số GK/CK trong template.
    IF @CapID = 1 AND @LmsMonHocID NOT IN (1, 2, 3, 4, 5, 19, 35, 36)
    BEGIN
        RAISERROR(N'Môn cấp 1 này không nằm trong danh sách môn nhận điểm thi từ QLDiem.', 16, 1);
        RETURN;
    END;

    -- Cấp 1 chỉ có cột điểm thi ở một số môn, không ghi điểm trung bình.
    -- Cấp 2 và cấp 3 tiếp tục yêu cầu cả điểm thi lẫn điểm trung bình học kỳ.
    IF @CapID IN (2, 3) AND @DiemTrungBinh IS NULL
    BEGIN
        RAISERROR(N'Cấp 2 và cấp 3 bắt buộc có DiemTrungBinh.', 16, 1);
        RETURN;
    END;

    IF @CapID = 1 AND @DiemTrungBinh IS NOT NULL
    BEGIN
        RAISERROR(N'Cấp 1 không nhận DiemTrungBinh; hãy gửi null cho tham số này.', 16, 1);
        RETURN;
    END;

    -- Ưu tiên theo mapping đã thấy ở store C1/C2/C3: mã chuẩn, DiemCD1/2 (C2 trừ môn 46),
    -- cột tổng của môn 46 (C2) / môn 76 (C3), rồi điểm tổng TA2 của môn 76.
    -- Cột kỹ năng TA2 không được chọn riêng lẻ vì payload chỉ có một DiemThi.
    DECLARE @ExamColumns TABLE
    (
        CotDiemID INT NOT NULL,
        MaCotDiem NVARCHAR(50) NOT NULL,
        PriorityNo INT NOT NULL,
        DiemMin FLOAT NULL,
        DiemMax FLOAT NULL
    );

    INSERT INTO @ExamColumns (CotDiemID, MaCotDiem, PriorityNo, DiemMin, DiemMax)
    SELECT
        ct.CotDiemID,
        ct.MaCotDiem,
        CASE
            WHEN ct.MaCotDiem = @ExamPrefix + '_' + @Semester THEN 1
            WHEN @CapID = 2 AND @LmsMonHocID <> 46 AND ct.MaCotDiem = @AltExamPrefix + '_' + @Semester THEN 2
            WHEN @CapID = 2 AND @LmsMonHocID <> 46 AND ct.MaCotDiem LIKE @AltExamPrefix + '%' THEN 3
            WHEN @CapID = 2 AND @LmsMonHocID = 46 AND ct.MaCotDiem LIKE @CustomExamSuffix THEN 4
            WHEN @CapID = 3 AND @LmsMonHocID = 76 AND ct.MaCotDiem LIKE @CustomExamSuffix THEN 4
            WHEN @CapID = 3 AND @LmsMonHocID = 76 AND ct.MaCotDiem LIKE @TA2AggregateSuffix THEN 5
            ELSE 6
        END,
        ct.DiemMin,
        ct.DiemMax
    FROM dbo.TemplateBangDiemChiTiet ct
    WHERE ct.TemplateBangDiemID = @TemplateBangDiemID
      AND ct.Semester = @Semester
      AND ct.Enable = 1
      AND ct.GiaTriCotDiem = 'number'
      AND
      (
             ct.MaCotDiem = @ExamPrefix + '_' + @Semester
          OR (@CapID = 2 AND @LmsMonHocID <> 46 AND ct.MaCotDiem LIKE @AltExamPrefix + '%')
          OR (@CapID = 2 AND @LmsMonHocID = 46 AND ct.MaCotDiem LIKE @CustomExamSuffix)
          OR (@CapID = 3 AND @LmsMonHocID = 76 AND ct.MaCotDiem LIKE @CustomExamSuffix)
          OR (@CapID = 3 AND @LmsMonHocID = 76 AND ct.MaCotDiem LIKE @TA2AggregateSuffix)
          OR
          (
              @CapID IN (2, 3)
              AND ct.MaCotDiem LIKE @ExamPrefix + '%'
              AND ct.MaCotDiem NOT LIKE '%TA2[_]Listening[_]Point'
              AND ct.MaCotDiem NOT LIKE '%TA2[_]Reading[_]Point'
              AND ct.MaCotDiem NOT LIKE '%TA2[_]Writing[_]Point'
              AND ct.MaCotDiem NOT LIKE '%TA2[_]Speaking[_]Point'
              AND ct.MaCotDiem NOT LIKE '%Conv%'
          )
      );

    DECLARE @BestExamPriority INT;
    DECLARE @ExamColumnCount INT;
    SELECT @BestExamPriority = MIN(PriorityNo) FROM @ExamColumns;
    SELECT @ExamColumnCount = COUNT(*) FROM @ExamColumns WHERE PriorityNo = @BestExamPriority;

    IF @BestExamPriority IS NULL
    BEGIN
        RAISERROR(N'Mẫu bảng điểm của môn này không có cột điểm thi số tương ứng với HocKi.', 16, 1);
        RETURN;
    END;

    IF @ExamColumnCount <> 1
    BEGIN
        RAISERROR(N'Mẫu bảng điểm có nhiều cột điểm thi cùng mức ưu tiên; không thể chọn an toàn.', 16, 1);
        RETURN;
    END;

    DECLARE @CotDiemThiID INT;
    DECLARE @MaCotDiemThi NVARCHAR(50);
    DECLARE @DiemThiMin FLOAT;
    DECLARE @DiemThiMax FLOAT;

    SELECT
        @CotDiemThiID = CotDiemID,
        @MaCotDiemThi = MaCotDiem,
        @DiemThiMin = DiemMin,
        @DiemThiMax = DiemMax
    FROM @ExamColumns
    WHERE PriorityNo = @BestExamPriority;

    -- Luồng kéo điểm C2/C3 và trang gv-xem-diem cùng dùng DTB -> DiemTB_HK1/HK2,
    -- nên giữ một cột trung bình học kỳ thống nhất cho cả GK và CK.
    DECLARE @AverageColumns TABLE
    (
        CotDiemID INT NOT NULL,
        MaCotDiem NVARCHAR(50) NOT NULL,
        PriorityNo INT NOT NULL,
        DiemMin FLOAT NULL,
        DiemMax FLOAT NULL
    );

    INSERT INTO @AverageColumns (CotDiemID, MaCotDiem, PriorityNo, DiemMin, DiemMax)
    SELECT
        ct.CotDiemID,
        ct.MaCotDiem,
        1,
        ct.DiemMin,
        ct.DiemMax
    FROM dbo.TemplateBangDiemChiTiet ct
    WHERE ct.TemplateBangDiemID = @TemplateBangDiemID
      AND ct.Semester = @Semester
      AND ct.Enable = 1
      AND ct.GiaTriCotDiem = 'number'
      AND @CapID IN (2, 3)
      AND ct.MaCotDiem = @GeneralAverageCode;

    DECLARE @BestAveragePriority INT;
    DECLARE @AverageColumnCount INT;
    SELECT @BestAveragePriority = MIN(PriorityNo) FROM @AverageColumns;
    SELECT @AverageColumnCount = COUNT(*) FROM @AverageColumns WHERE PriorityNo = @BestAveragePriority;

    IF @CapID IN (2, 3) AND @BestAveragePriority IS NULL
    BEGIN
        RAISERROR(N'Mẫu bảng điểm của môn này không có cột trung bình số tương ứng với học kỳ.', 16, 1);
        RETURN;
    END;

    IF @CapID IN (2, 3) AND @AverageColumnCount <> 1
    BEGIN
        RAISERROR(N'Mẫu bảng điểm có nhiều cột trung bình cùng mức ưu tiên; không thể chọn an toàn.', 16, 1);
        RETURN;
    END;

    DECLARE @CotDiemTrungBinhID INT;
    DECLARE @MaCotDiemTrungBinh NVARCHAR(50);
    DECLARE @DiemTBMin FLOAT;
    DECLARE @DiemTBMax FLOAT;

    SELECT
        @CotDiemTrungBinhID = CotDiemID,
        @MaCotDiemTrungBinh = MaCotDiem,
        @DiemTBMin = DiemMin,
        @DiemTBMax = DiemMax
    FROM @AverageColumns
    WHERE PriorityNo = @BestAveragePriority;

    IF (@DiemThiMin IS NOT NULL AND @DiemThi < @DiemThiMin)
       OR (@DiemThiMax IS NOT NULL AND @DiemThi > @DiemThiMax)
    BEGIN
        RAISERROR(N'DiemThi nằm ngoài thang điểm của cột điểm thi trong mẫu bảng điểm.', 16, 1);
        RETURN;
    END;

    IF @CapID IN (2, 3)
       AND ((@DiemTBMin IS NOT NULL AND @DiemTrungBinh < @DiemTBMin)
         OR (@DiemTBMax IS NOT NULL AND @DiemTrungBinh > @DiemTBMax))
    BEGIN
        RAISERROR(N'DiemTrungBinh nằm ngoài thang điểm của cột trung bình trong mẫu bảng điểm.', 16, 1);
        RETURN;
    END;

    DECLARE @GradeToSave TABLE
    (
        RowNo TINYINT NOT NULL PRIMARY KEY,
        LoaiDiem NVARCHAR(30) NOT NULL,
        CotDiemID INT NOT NULL,
        MaCotDiem NVARCHAR(50) NOT NULL,
        Diem DECIMAL(10, 2) NOT NULL,
        DiemText NVARCHAR(100)
    );

    INSERT INTO @GradeToSave (RowNo, LoaiDiem, CotDiemID, MaCotDiem, Diem, DiemText)
    VALUES (1, N'DiemThi', @CotDiemThiID, @MaCotDiemThi, @DiemThi, CONVERT(NVARCHAR(100), @DiemThi));

    IF @CapID IN (2, 3)
    BEGIN
        INSERT INTO @GradeToSave (RowNo, LoaiDiem, CotDiemID, MaCotDiem, Diem, DiemText)
        VALUES (2, N'DiemTrungBinh', @CotDiemTrungBinhID, @MaCotDiemTrungBinh, @DiemTrungBinh, CONVERT(NVARCHAR(100), @DiemTrungBinh));
    END;

    DECLARE @Saved TABLE
    (
        RowNo TINYINT NOT NULL PRIMARY KEY,
        LoaiDiem NVARCHAR(30) NOT NULL,
        CotDiemID INT NOT NULL,
        MaCotDiem NVARCHAR(50) NOT NULL,
        KQHTID INT NOT NULL,
        KhoaCotDiemID INT NULL,
        DiemText NVARCHAR(100) NOT NULL
    );

    DECLARE @i TINYINT = 1;
    DECLARE @KQHTID INT;
    DECLARE @KhoaCotDiemID INT;
    DECLARE @ExistingCount INT;
    DECLARE @CotDiemID INT;
    DECLARE @MaCotDiem NVARCHAR(50);
    DECLARE @LoaiDiem NVARCHAR(30);
    DECLARE @DiemText NVARCHAR(100);
    DECLARE @LockIDResult TABLE (KhoaCotDiemID INT);
    DECLARE @GradeCount TINYINT;
    SELECT @GradeCount = COUNT(*) FROM @GradeToSave;

    BEGIN TRY
        BEGIN TRANSACTION;

        WHILE @i <= @GradeCount
        BEGIN
            SELECT
                @CotDiemID = CotDiemID,
                @MaCotDiem = MaCotDiem,
                @LoaiDiem = LoaiDiem,
                @DiemText = DiemText
            FROM @GradeToSave
            WHERE RowNo = @i;

            SELECT @ExistingCount = COUNT(*)
            FROM dbo.tblKetQuaHocTap WITH (UPDLOCK, HOLDLOCK)
            WHERE MonHocLopID = @MonHocLopID
              AND HocSinhID = @HocSinhID
              AND LopID = @LopID
              AND NienKhoa = @NienKhoa
              AND CotDiemID = @CotDiemID
              AND Enable = 1;

            IF @ExistingCount > 1
            BEGIN
                RAISERROR(N'Đã có nhiều bản ghi điểm đang hiệu lực cho cùng học sinh, môn học và cột điểm.', 16, 1);
            END;

            IF @ExistingCount = 1
            BEGIN
                UPDATE dbo.tblKetQuaHocTap
                SET KetQuaDanhGia_VI = @DiemText,
                    KetQuaDanhGia_EN = @DiemText,
                    UpdateUser = @AuditUserID,
                    UpdateTime = GETDATE(),
                    NhapDiemUser = @AuditUserID,
                    NhapDiemTime = GETDATE()
                WHERE MonHocLopID = @MonHocLopID
                  AND HocSinhID = @HocSinhID
                  AND LopID = @LopID
                  AND NienKhoa = @NienKhoa
                  AND CotDiemID = @CotDiemID
                  AND Enable = 1;
            END
            ELSE
            BEGIN
                INSERT INTO dbo.tblKetQuaHocTap
                (
                    MonHocLopID,
                    HocSinhID,
                    LopID,
                    NienKhoa,
                    CotDiemID,
                    KetQuaDanhGia_VI,
                    KetQuaDanhGia_EN,
                    Enable,
                    CreateUser,
                    CreateTime,
                    NhapDiemUser,
                    NhapDiemTime
                )
                VALUES
                (
                    @MonHocLopID,
                    @HocSinhID,
                    @LopID,
                    @NienKhoa,
                    @CotDiemID,
                    @DiemText,
                    @DiemText,
                    1,
                    @AuditUserID,
                    GETDATE(),
                    @AuditUserID,
                    GETDATE()
                );
            END;

            SELECT @KQHTID = KQHTID
            FROM dbo.tblKetQuaHocTap
            WHERE MonHocLopID = @MonHocLopID
              AND HocSinhID = @HocSinhID
              AND LopID = @LopID
              AND NienKhoa = @NienKhoa
              AND CotDiemID = @CotDiemID
              AND Enable = 1;

            DELETE FROM @LockIDResult;
            INSERT INTO @LockIDResult (KhoaCotDiemID)
            EXEC dbo.spAPI_KhoaCotDiem_Ins_And_Upd
                  @LopID = @LopID
                , @MonHocLopID = @MonHocLopID
                , @MaCotDiem = @MaCotDiem
                , @IsKhoaCotDiem = 0
                , @SYS_USERID = @AuditUserID;

            SELECT TOP (1) @KhoaCotDiemID = KhoaCotDiemID
            FROM @LockIDResult;

            UPDATE dbo.tblKetQuaHocTap
            SET KhoaCotDiemID = @KhoaCotDiemID
            WHERE KQHTID = @KQHTID;

            INSERT INTO @Saved (RowNo, LoaiDiem, CotDiemID, MaCotDiem, KQHTID, KhoaCotDiemID, DiemText)
            VALUES (@i, @LoaiDiem, @CotDiemID, @MaCotDiem, @KQHTID, @KhoaCotDiemID, @DiemText);

            SET @i += 1;
        END;

        COMMIT TRANSACTION;

        SELECT
            N'Thành công' AS [status],
            @HocSinhID AS HocSinhID,
            @MonHocID AS MonHocID,
            @LmsMonHocID AS LMSMonHocID,
            @NienKhoa AS NienKhoa,
            @HocKiCode AS HocKi,
            @MonHocLopID AS MonHocLopID,
            @StudentLopID AS LopID,
            @LopID AS LopNhomID,
            s.LoaiDiem,
            s.CotDiemID,
            s.MaCotDiem,
            s.KQHTID,
            s.KhoaCotDiemID,
            s.DiemText AS KetQuaDanhGia
        FROM @Saved s
        ORDER BY s.RowNo;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END;
