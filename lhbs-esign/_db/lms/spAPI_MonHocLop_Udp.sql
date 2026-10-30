CREATE PROC [dbo].[spAPI_MonHocLop_Udp]
    @MonHocLopID INT,
    @TemplateBangDiemID INT,
    @TemplateReportHTML INT,
    @TemplateReportPDF INT,
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblMonHocLop
    SET TemplateBangDiemID = @TemplateBangDiemID,
        TemplateReportHTML = @TemplateReportHTML,
        TemplateReportPDF = @TemplateReportPDF,
        UpdateUser = @SYS_USERID,
        UpdateTime = GETDATE()
    WHERE MonHocLopID = @MonHocLopID;
END;