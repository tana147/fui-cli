CREATE PROC [dbo].[spAPI_MonHocLop_Ins]
    @MonHocID INT,
    @LopID VARCHAR(10),
    @NienKhoa INT,
    @TemplateBangDiemID INT,
    @TemplateReportHTML INT,
    @TemplateReportPDF INT,
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    -- Xác nhận đúng lớp-năm trước khi tạo cấu hình môn học.
    IF NOT EXISTS (
        SELECT 1 FROM dbo.tblLop
        WHERE LopID = @LopID AND NienKhoa = @NienKhoa AND Enable = 1
    )
    BEGIN
        RAISERROR(N'Không tìm thấy lớp theo cặp LopID và NienKhoa.', 16, 1);
        RETURN;
    END;

    INSERT INTO dbo.tblMonHocLop
    (
        MonHocID,
        LopNhomID,
        NienKhoa,
        GVGiangDay1,
        GVGiangDay2,
        TemplateBangDiemID,
        TemplateReportHTML,
        TemplateReportPDF,
        Enable,
        CreateUser,
        CreateTime
    )
    VALUES
    (   @MonHocID,           -- MonHocID - int
        @LopID,              -- LopID - int
        @NienKhoa,           -- NienKhoa - int
        '',                  -- GVGiangDay1 - varchar(20)
        '',                  -- GVGiangDay2 - varchar(20)
        @TemplateBangDiemID, -- TemplateBangDiemID - int
        @TemplateReportHTML, -- TemplateReportHTML - int
        @TemplateReportPDF,  -- TemplateReportPDF - int
        1,                   -- Enable - bit
        @SYS_USERID,         -- CreateUser - varchar(20)
        GETDATE()            -- UpdateTime - datetime
        );

END;
