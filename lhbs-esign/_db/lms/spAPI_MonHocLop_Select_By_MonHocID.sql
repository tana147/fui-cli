CREATE PROCEDURE [dbo].[spAPI_MonHocLop_Select_By_MonHocID]
    @MonHocID INT,
    @LopID NVARCHAR(20),
    @NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT mhl.MonHocLopID,
           mhl.MonHocID,
           ISNULL(mhl.LopNhomID, l.LopID) AS LopNhomID,
           l.TenLop,
           l.KhoiID,
           mh.MonHocName,
           mhl.TemplateBangDiemID,
           mhl.TemplateReportHTML,
           mhl.TemplateReportPDF,
           t_1.TemplateBangDiemName AS TemplateBangDiemName,
           t_2.TemplateBangDiemName AS TemplateBangDiemName_HTML,
           t_3.TemplateBangDiemName AS TemplateBangDiemName_PDF
    FROM dbo.tblLop AS l
    LEFT JOIN dbo.tblMonHocLop AS mhl
        ON l.LopID = mhl.LopNhomID
       AND mhl.NienKhoa = @NienKhoa
       AND (mhl.MonHocID = @MonHocID OR @MonHocID = 0)
       AND mhl.Enable = 1
    LEFT JOIN dbo.tblMonHoc AS mh
        ON mh.MonHocID = mhl.MonHocID
       AND mh.Enable = 1
    LEFT JOIN dbo.TemplateBangDiem AS t_1
        ON t_1.TemplateBangDiemID = mhl.TemplateBangDiemID
       AND t_1.NienKhoa = @NienKhoa
       AND t_1.Enable = 1
    LEFT JOIN dbo.TemplateBangDiem AS t_2
        ON t_2.TemplateBangDiemID = mhl.TemplateReportHTML
       AND t_2.NienKhoa = @NienKhoa
       AND t_2.Enable = 1
    LEFT JOIN dbo.TemplateBangDiem AS t_3
        ON t_3.TemplateBangDiemID = mhl.TemplateReportPDF
       AND t_3.NienKhoa = @NienKhoa
       AND t_3.Enable = 1
    WHERE l.Enable = 1
      AND l.NienKhoa = @NienKhoa
      AND (l.LopID = @LopID OR ISNULL(@LopID, '') = '')

    UNION ALL

    SELECT mhl.MonHocLopID,
           COALESCE(mhl.MonHocID, n.MonHocID) AS MonHocID,
           n.NhomID AS LopNhomID,
           n.TenNhom AS TenLop,
           n.KhoiID,
           mh.MonHocName,
           mhl.TemplateBangDiemID,
           mhl.TemplateReportHTML,
           mhl.TemplateReportPDF,
           t_1.TemplateBangDiemName AS TemplateBangDiemName,
           t_2.TemplateBangDiemName AS TemplateBangDiemName_HTML,
           t_3.TemplateBangDiemName AS TemplateBangDiemName_PDF
    FROM dbo.tblNhom AS n
    LEFT JOIN dbo.tblMonHocLop AS mhl
        ON mhl.LopNhomID = n.NhomID
       AND mhl.NienKhoa = @NienKhoa
       AND (mhl.MonHocID = @MonHocID OR @MonHocID = 0)
       AND mhl.Enable = 1
    LEFT JOIN dbo.tblMonHoc AS mh
        ON mh.MonHocID = COALESCE(mhl.MonHocID, n.MonHocID)
       AND mh.Enable = 1
    LEFT JOIN dbo.TemplateBangDiem AS t_1
        ON t_1.TemplateBangDiemID = mhl.TemplateBangDiemID
       AND t_1.NienKhoa = @NienKhoa
       AND t_1.Enable = 1
    LEFT JOIN dbo.TemplateBangDiem AS t_2
        ON t_2.TemplateBangDiemID = mhl.TemplateReportHTML
       AND t_2.NienKhoa = @NienKhoa
       AND t_2.Enable = 1
    LEFT JOIN dbo.TemplateBangDiem AS t_3
        ON t_3.TemplateBangDiemID = mhl.TemplateReportPDF
       AND t_3.NienKhoa = @NienKhoa
       AND t_3.Enable = 1
    WHERE n.Enable = 1
      AND n.NienKhoa = @NienKhoa
      AND (n.NhomID = @LopID OR ISNULL(@LopID, '') = '')
      AND (@MonHocID = 0 OR n.MonHocID = @MonHocID OR mhl.MonHocID = @MonHocID)

    ORDER BY TenLop;

    GRANT EXECUTE ON [dbo].[spAPI_MonHocLop_Select_By_MonHocID] TO [lmslhbs];
END;