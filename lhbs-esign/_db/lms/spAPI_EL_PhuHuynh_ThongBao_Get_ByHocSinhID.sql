CREATE PROC [dbo].[spAPI_EL_PhuHuynh_ThongBao_Get_ByHocSinhID] 
@HocSinhID VARCHAR(50),
@NienKhoa INT,
@Type INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Xác định khoảng thời gian dựa vào @Type
    DECLARE @StartDate DATETIME, @EndDate DATETIME;
    
    IF @Type = 0  -- Theo ngày (hôm nay)
    BEGIN
        SET @StartDate = CAST(GETDATE() AS DATE);  -- 00:00:00 của ngày hiện tại
        SET @EndDate = DATEADD(DAY, 1, @StartDate);  -- 00:00:00 của ngày mai
    END
    ELSE IF @Type = 1  -- Theo tuần (tuần hiện tại)
    BEGIN
        -- Lấy ngày đầu tuần (Thứ 2)
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
        SET @EndDate = DATEADD(DAY, 7, @StartDate);  -- Cuối tuần (Chủ nhật)
    END
    ELSE IF @Type = 2  -- Theo tháng (tháng hiện tại)
    BEGIN
        SET @StartDate = DATEADD(DAY, 1 - DAY(GETDATE()), CAST(GETDATE() AS DATE));  -- Ngày đầu tháng
        SET @EndDate = DATEADD(MONTH, 1, @StartDate);  -- Ngày đầu tháng sau
    END
    ELSE  -- @Type = 3 hoặc giá trị khác - Lấy tất cả
    BEGIN
        SET @StartDate = '1900-01-01';
        SET @EndDate = '9999-12-31';
    END

    --------------------------------------------------------------------------------
    -- 1) Lấy toàn bộ thông báo từ 3 nguồn: AssignToClass, AssignToStudent, Learning Path
    --------------------------------------------------------------------------------
    ;
    WITH TB AS
    (
        -- 1.1) Submission từ AssignToClass
        SELECT 
            tb.ThongBaoID,
            ISNULL(tb.SubmissionID, tb.ResourceID) as SubmissionID,
            ISNULL(mh.TenMonHoc_HienThi, N'Không có môn học') AS TenMonHoc_HienThi,
            ISNULL(asm.Title, N'Không có tiêu đề') AS Title,
            tb.Is_DaXem,
            tb.NguoiXem,
            tb.ThoiGianXem,
            tb.NguoiNhan,
            tb.ThoiGianNhan,
            tb_t.TemplateContent,
            tb_t_t.TypeTitle,
            tb_t_t.Color,
            tb_t_t.Icon,
            hs.HocSinhID,
            hs.Ho + ' ' + hs.Ten AS HoTen,
            l.TenLop,
            FORMAT(TRY_CONVERT(DATE, hs.NgaySinh, 103), 'dd/MM/yyyy') AS NgaySinh,
            hs.Nu,
            atc.DueDate,
            tb_t.ThongBao_TypeID,
            s.Score,
            CONCAT(gv.HoGV,' ', gv.TenGV) as HoTenGV,
            atc.AssignToClassID,
            s.SubmissionTime
        FROM dbo.tblEL_ThongBao tb
        INNER JOIN dbo.tblEL_ThongBao_Template tb_t 
            ON tb_t.ThongBao_TemplateID = tb.ThongBao_TemplateID 
            AND tb_t.IsDeleted = 0
        INNER JOIN dbo.tblEL_ThongBao_Template_Type tb_t_t 
            ON tb_t_t.ThongBao_TypeID = tb_t.ThongBao_TypeID
        INNER JOIN dbo.tblHocSinh hs 
            ON CONVERT(VARCHAR(50), hs.HocSinhID) = tb.NguoiNhan
        INNER JOIN dbo.tblHocSinhLop hsl 
            ON hsl.HocSinhID = hs.HocSinhID
        INNER JOIN dbo.tblLop l 
            ON l.LopID = hsl.LopID 
            AND l.NienKhoa = @NienKhoa
            AND l.Enable = 1
        AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN dbo.tblEL_Submissions s 
            ON s.SubmissionID = ISNULL(tb.SubmissionID, tb.ResourceID) 
            AND s.IsDeleted = 0
            AND s.AssignToClassID IS NOT NULL
        INNER JOIN dbo.tblEL_AssignToClass atc 
            ON atc.AssignToClassID = s.AssignToClassID 
            AND atc.IsDeleted = 0
        INNER JOIN dbo.tblEL_Assignments asm 
            ON asm.AssignmentID = atc.AssignmentID 
            AND asm.IsDeleted = 0
            AND asm.NienKhoa = @NienKhoa
        LEFT JOIN dbo.tblGiaoVien gv 
            ON gv.GiaoVienID = atc.CreateUser
        LEFT JOIN dbo.tblMonHoc mh 
            ON mh.MonHocID = asm.MonHocID 
            AND mh.Enable = 1
        WHERE ISNULL(tb.IsDeleted, 0) = 0 
            AND tb.NguoiNhan = @HocSinhID
            AND tb.ThoiGianNhan >= @StartDate 
            AND tb.ThoiGianNhan < @EndDate

        UNION ALL

        -- 1.2) Submission từ AssignToStudent
        SELECT 
            tb.ThongBaoID,
            ISNULL(tb.SubmissionID, tb.ResourceID) as SubmissionID,
            ISNULL(mh.TenMonHoc_HienThi, N'Không có môn học') AS TenMonHoc_HienThi,
            ISNULL(asm.Title, N'Không có tiêu đề') AS Title,
            tb.Is_DaXem,
            tb.NguoiXem,
            tb.ThoiGianXem,
            tb.NguoiNhan,
            tb.ThoiGianNhan,
            tb_t.TemplateContent,
            tb_t_t.TypeTitle,
            tb_t_t.Color,
            tb_t_t.Icon,
            hs.HocSinhID,
            hs.Ho + ' ' + hs.Ten AS HoTen,
            l.TenLop,
            FORMAT(TRY_CONVERT(DATE, hs.NgaySinh, 103), 'dd/MM/yyyy') AS NgaySinh,
            hs.Nu,
            ats.DueDate,
            tb_t.ThongBao_TypeID,
            s.Score,
            NULL as HoTenGV,
            NULL as AssignToClassID,
            s.SubmissionTime
        FROM dbo.tblEL_ThongBao tb
        INNER JOIN dbo.tblEL_ThongBao_Template tb_t 
            ON tb_t.ThongBao_TemplateID = tb.ThongBao_TemplateID 
            AND tb_t.IsDeleted = 0
        INNER JOIN dbo.tblEL_ThongBao_Template_Type tb_t_t 
            ON tb_t_t.ThongBao_TypeID = tb_t.ThongBao_TypeID
        INNER JOIN dbo.tblHocSinh hs 
            ON CONVERT(VARCHAR(50), hs.HocSinhID) = tb.NguoiNhan
        INNER JOIN dbo.tblHocSinhLop hsl 
            ON hsl.HocSinhID = hs.HocSinhID
        INNER JOIN dbo.tblLop l 
            ON l.LopID = hsl.LopID 
            AND l.NienKhoa = @NienKhoa
            AND l.Enable = 1
        AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN dbo.tblEL_Submissions s 
            ON s.SubmissionID = ISNULL(tb.SubmissionID, tb.ResourceID) 
            AND s.IsDeleted = 0
            AND s.AssignToStudentID IS NOT NULL
        INNER JOIN dbo.tblEL_AssignToStudent ats 
            ON ats.AssignToStudentID = s.AssignToStudentID 
            AND ats.IsDeleted = 0
        INNER JOIN dbo.tblEL_Assignments asm 
            ON asm.AssignmentID = ats.AssignmentID 
            AND asm.IsDeleted = 0
            AND asm.NienKhoa = @NienKhoa
        LEFT JOIN dbo.tblMonHoc mh 
            ON mh.MonHocID = asm.MonHocID 
            AND mh.Enable = 1
        WHERE ISNULL(tb.IsDeleted, 0) = 0 
            AND tb.NguoiNhan = @HocSinhID
            AND tb.ThoiGianNhan >= @StartDate 
            AND tb.ThoiGianNhan < @EndDate

        UNION ALL

        -- 1.3) Learning Path
        SELECT 
            tb.ThongBaoID,
            tb.ResourceID as SubmissionID,
            ISNULL(mh.TenMonHoc_HienThi, N'Không có môn học') AS TenMonHoc_HienThi,
            ISNULL(ls.Title, N'Learning Path') AS Title,
            tb.Is_DaXem,
            tb.NguoiXem,
            tb.ThoiGianXem,
            tb.NguoiNhan,
            tb.ThoiGianNhan,
            tb_t.TemplateContent,
            tb_t_t.TypeTitle,
            tb_t_t.Color,
            tb_t_t.Icon,
            hs.HocSinhID,
            hs.Ho + ' ' + hs.Ten AS HoTen,
            l.TenLop,
            FORMAT(TRY_CONVERT(DATE, hs.NgaySinh, 103), 'dd/MM/yyyy') AS NgaySinh,
            hs.Nu,
            NULL as DueDate,
            tb_t.ThongBao_TypeID,
            NULL as Score,
            NULL as HoTenGV,
            NULL as AssignToClassID,
            NULL as SubmissionTime
        FROM dbo.tblEL_ThongBao tb
        INNER JOIN dbo.tblEL_ThongBao_Template tb_t 
            ON tb_t.ThongBao_TemplateID = tb.ThongBao_TemplateID 
            AND tb_t.IsDeleted = 0
        INNER JOIN dbo.tblEL_ThongBao_Template_Type tb_t_t 
            ON tb_t_t.ThongBao_TypeID = tb_t.ThongBao_TypeID
        INNER JOIN dbo.tblHocSinh hs 
            ON CONVERT(VARCHAR(50), hs.HocSinhID) = tb.NguoiNhan
        INNER JOIN dbo.tblHocSinhLop hsl 
            ON hsl.HocSinhID = hs.HocSinhID
        INNER JOIN dbo.tblLop l 
            ON l.LopID = hsl.LopID 
            AND l.NienKhoa = @NienKhoa
            AND l.Enable = 1
        AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN dbo.tblEL_Learning_Progress lp
            ON lp.HocSinhID = hs.HocSinhID 
            AND lp.HocSinhID = hsl.HocSinhID
            AND lp.ProgressID = tb.ResourceID
            AND lp.IsDeleted = 0
        INNER JOIN dbo.tblEL_Lessons ls 
            ON ls.LessonID = lp.LessonID 
            AND ls.IsDeleted = 0
            AND ls.NienKhoa = @NienKhoa
        INNER JOIN dbo.tblMonHoc mh 
            ON mh.MonHocID = ls.MonHocID
            AND mh.Enable = 1
        WHERE ISNULL(tb.IsDeleted, 0) = 0 
            AND tb.NguoiNhan = @HocSinhID
            AND tb.ResourceType = 'LP'
            AND tb.SubmissionID IS NULL
            AND tb.ThoiGianNhan >= @StartDate 
            AND tb.ThoiGianNhan < @EndDate
    )
    --------------------------------------------------------------------------------
    -- 2) Thay thế template param
    --------------------------------------------------------------------------------
    SELECT 
        ThongBaoID,
        SubmissionID,
        Is_DaXem,
        NguoiXem,
        ThoiGianXem,
        NguoiNhan,
        ThoiGianNhan,
        ThongBao_TypeID,
        Score,
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(
                                            TemplateContent,
                                            '@HoTenGV', ISNULL(HoTenGV, '')
                                        ),
                                        '@TenLop', TenLop
                                    ),
                                    '@Title', Title
                                ),
                                '@TenMonHoc_HienThi', TenMonHoc_HienThi
                            ),
                            '@NgaySinh', NgaySinh
                        ),
                        '@DueDate', ISNULL(CONVERT(VARCHAR(20), DueDate, 103), '')
                    ),
                    '@Score', ISNULL(CAST(Score AS VARCHAR(20)), '')
                ),
                '@CreateDate', ISNULL(CONVERT(VARCHAR(20), SubmissionTime, 103), '')
            ),
            '@HoTen', HoTen
        ) AS TemplateContent,
        TemplateContent as original_content,
        TypeTitle,
        Color,
        Icon,
        AssignToClassID
    FROM TB
    ORDER BY ThongBaoID DESC;

END;
