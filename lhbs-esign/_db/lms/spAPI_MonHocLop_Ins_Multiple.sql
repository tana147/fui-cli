CREATE PROC [dbo].[spAPI_MonHocLop_Ins_Multiple]
    @jsonData   NVARCHAR(MAX)
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    DECLARE @Table TABLE
    (
        MonHocID           INT
      , LopNhomID          VARCHAR(10)
      , ChiaTheoLop        BIT
      , NienKhoa           INT
      , GVGiangDay1        VARCHAR(20)
      , GVGiangDay2        VARCHAR(20)
      , TemplateBangDiemID INT
      , TemplateReportHTML INT
      , TemplateReportPDF  INT
    );
    INSERT INTO @Table
    (
        MonHocID
      , LopNhomID
      , ChiaTheoLop
      , NienKhoa
      , GVGiangDay1
      , GVGiangDay2
      , TemplateBangDiemID
      , TemplateReportHTML
      , TemplateReportPDF
    )
    SELECT *
    FROM
           OPENJSON(@jsonData)
           WITH
           (
               MonHocID INT
             , LopNhomID VARCHAR(10)
             , ChiaTheoLop BIT
             , NienKhoa INT
             , GVGiangDay1 VARCHAR(20)
             , GVGiangDay2 VARCHAR(20)
             , TemplateBangDiemID INT
             , TemplateReportHTML INT
             , TemplateReportPDF INT
           );

    UPDATE mhl
    SET    mhl.TemplateBangDiemID = ISNULL(t.TemplateBangDiemID, mhl.TemplateBangDiemID)
         , mhl.UpdateUser = @SYS_USERID
         , mhl.UpdateTime = GETDATE()
    FROM
           dbo.tblMonHocLop  mhl
           INNER JOIN @Table t ON t.MonHocID  = mhl.MonHocID
                              AND t.LopNhomID = mhl.LopNhomID
                              AND t.NienKhoa  = mhl.NienKhoa
    WHERE
           mhl.Enable = 1;

    INSERT INTO dbo.tblMonHocLop
    (
        MonHocID
      , LopNhomID
      , ChiaTheoLop
      , NienKhoa
      , TemplateBangDiemID
      , TemplateReportHTML
      , TemplateReportPDF
      , Enable
      , CreateUser
      , CreateTime
    )
    SELECT t.MonHocID
         , t.LopNhomID
         , t.ChiaTheoLop
         , t.NienKhoa
         , ISNULL(t.TemplateBangDiemID, 0) AS TemplateBangDiemID
         , 0
         , 0
         , 1
         , @SYS_USERID
         , GETDATE()
    FROM
           @Table t
    WHERE
           NOT EXISTS
    (
        SELECT *
        FROM
               dbo.tblMonHocLop mhl
        WHERE
               t.MonHocID = mhl.MonHocID
          AND  t.LopNhomID = mhl.LopNhomID
          AND  t.NienKhoa  = mhl.NienKhoa
          AND  mhl.Enable  = 1
    );
END;