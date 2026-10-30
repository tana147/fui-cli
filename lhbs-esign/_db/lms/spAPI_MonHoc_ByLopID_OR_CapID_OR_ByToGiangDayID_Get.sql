CREATE PROC [dbo].[spAPI_MonHoc_ByLopID_OR_CapID_OR_ByToGiangDayID_Get]
    @LopID INT = NULL,
    @CapID INT = NULL,
    @SYS_USERID VARCHAR(9) = NULL,
    @Sys_GroupID INT = NULL,
    @NienKhoa INT = NULL,
    @MonHocGroup INT = NULL,
    @MonHocID INT = NULL,
    @ToGiangDayID INT = NULL,
    @GiaoVienID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Nếu MonHocID được cung cấp
    IF @MonHocID IS NOT NULL
    BEGIN
        SELECT DISTINCT
            MH.MonHocID, 
            MH.MonHocCode, 
            MH.MonHocName, 
            MH.MonHocGroup, 
            MH.TenMonDuLieuNganh, 
            MH.Enable,
            MH.CapID
        FROM 
            tblMonHoc MH
        LEFT JOIN 
            tblToGiangDay_GiaoVien_MonHoc TGGM ON MH.MonHocID = TGGM.MonHocID
        WHERE 
            MH.MonHocID = @MonHocID 
            AND MH.[Enable] = 1
            AND (@ToGiangDayID IS NULL OR TGGM.ToGiangDayID = @ToGiangDayID)
            AND (@GiaoVienID IS NULL OR TGGM.GiaoVienID = @GiaoVienID);
        RETURN;
    END;

    -- Nếu LopID được cung cấp
    IF @LopID IS NOT NULL
    BEGIN
        SELECT DISTINCT
            MHL.[MonHocLopID], 
            MH.[MonHocID], 
            MH.MonHocCode, 
            MH.MonHocName, 
            MH.MonHocGroup, 
            MH.TenMonDuLieuNganh, 
            MHL.[LopNhomID], 
            MHL.[NienKhoa], 
            MHL.[GVGiangDay1], 
            MHL.[GVGiangDay2], 
            MHL.[TemplateBangDiemID], 
            MHL.[TemplateReportHTML], 
            MHL.[TemplateReportPDF],
            MH.CapID
        FROM 
            tblMonHocLop MHL
        INNER JOIN 
            tblMonHoc MH ON MHL.MonHocID = MH.MonHocID
        LEFT JOIN 
            tblToGiangDay_GiaoVien_MonHoc TGGM ON MH.MonHocID = TGGM.MonHocID
        WHERE 
            (@NienKhoa IS NULL OR MHL.NienKhoa = @NienKhoa)
            AND MHL.[Enable] = 1 
            AND MH.[Enable] = 1 
            AND MHL.LopNhomID = @LopID
            AND (@MonHocGroup IS NULL OR MH.MonHocGroup = @MonHocGroup)
            AND (@ToGiangDayID IS NULL OR TGGM.ToGiangDayID = @ToGiangDayID)
            AND (@GiaoVienID IS NULL OR TGGM.GiaoVienID = @GiaoVienID);
        RETURN;
    END;

    -- Nếu CapID được cung cấp
    IF @CapID IS NOT NULL
    BEGIN
        SELECT DISTINCT
            MH.MonHocID, 
            MH.MonHocCode, 
            MH.MonHocName, 
            MH.MonHocGroup, 
            MH.TenMonDuLieuNganh, 
            MH.Enable,
            MH.CapID
        FROM 
            tblMonHoc MH
        LEFT JOIN 
            tblToGiangDay_GiaoVien_MonHoc TGGM ON MH.MonHocID = TGGM.MonHocID
        WHERE 
            MH.CapID = @CapID 
            AND MH.[Enable] = 1
            AND (@MonHocGroup IS NULL OR MH.MonHocGroup = @MonHocGroup)
            AND (@ToGiangDayID IS NULL OR TGGM.ToGiangDayID = @ToGiangDayID)
            AND (@GiaoVienID IS NULL OR TGGM.GiaoVienID = @GiaoVienID);
        RETURN;
    END;

    -- Trường hợp không nhập LopID, CapID, MonHocID
    SELECT DISTINCT
        MH.MonHocID, 
        MH.MonHocCode, 
        MH.MonHocName, 
        MH.MonHocGroup, 
        MH.TenMonDuLieuNganh, 
        MH.Enable,
        MH.CapID
    FROM 
        tblMonHoc MH
    LEFT JOIN 
        tblToGiangDay_GiaoVien_MonHoc TGGM ON MH.MonHocID = TGGM.MonHocID
    WHERE 
        MH.[Enable] = 1 
        AND (@MonHocGroup IS NULL OR MH.MonHocGroup = @MonHocGroup)
        AND (@ToGiangDayID IS NULL OR TGGM.ToGiangDayID = @ToGiangDayID)
        AND (@GiaoVienID IS NULL OR TGGM.GiaoVienID = @GiaoVienID);
END;
