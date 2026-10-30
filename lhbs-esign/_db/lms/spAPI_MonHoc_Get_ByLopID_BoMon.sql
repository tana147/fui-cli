CREATE PROC [dbo].[spAPI_MonHoc_Get_ByLopID_BoMon]
    @NienKhoa        INT
  , @LopID           VARCHAR(10)
  , @HocKi           INT
  , @SYS_USERID      VARCHAR(9)
  , @SYS_SystemRight INT
AS
BEGIN

    DECLARE @Is_GVCN BIT = 0;
    IF EXISTS
    (
        SELECT *
        FROM
               dbo.tblLop
        WHERE
               GVCN = @SYS_USERID
           AND LopID = @LopID
           AND NienKhoa = @NienKhoa
           AND Enable = 1
    )
    BEGIN
        SET @Is_GVCN = 1;
    END;
    DECLARE @Table TABLE
    (
        MonHocLopID         INT
      , MonHocID            INT
      , MonHocCode          VARCHAR(20)
      , MonHocName          NVARCHAR(100)
      , MonHocGroup         INT
      , TenMonDuLieuNganh   NVARCHAR(100)
      , LopNhomID           VARCHAR(20)
      , NienKhoa            INT
      , GVGiangDay1         VARCHAR(20)
      , GVGiangDay2         VARCHAR(20)
      , TemplateBangDiemID  INT
      , TemplateReportHTML  INT
      , TemplateReportPDF   INT
      , Is_MonHoc_BoTro     BIT
      , TenMonHoc_HienThi   NVARCHAR(200)
      , List_MonHoc_NLPC_ID NVARCHAR(10)
    );

    IF (@Is_GVCN = 0)
    BEGIN
        INSERT INTO @Table
        (
            MonHocLopID
          , MonHocID
          , MonHocCode
          , MonHocName
          , MonHocGroup
          , TenMonDuLieuNganh
          , LopNhomID
          , NienKhoa
          , GVGiangDay1
          , GVGiangDay2
          , TemplateBangDiemID
          , TemplateReportHTML
          , TemplateReportPDF
          , Is_MonHoc_BoTro
          , TenMonHoc_HienThi
          , List_MonHoc_NLPC_ID
        )
        SELECT [MHL].[MonHocLopID]
             , MH.[MonHocID]
             , MH.MonHocCode
             , CASE WHEN MH.CapID = 1 THEN MH.TenMonDuLieuNganh ELSE MH.MonHocName END AS MonHocName
             , MH.MonHocGroup
             , MH.TenMonDuLieuNganh
             , MHL.LopNhomID                                                           AS LopID
             , [MHL].[NienKhoa]
             , [MHL].[GVGiangDay1]
             , [MHL].[GVGiangDay2]
             , [MHL].[TemplateBangDiemID]
             , [MHL].[TemplateReportHTML]
             , [MHL].[TemplateReportPDF]
             , MH.Is_MonHoc_BoTro
             , MH.TenMonHoc_HienThi
             , MH.List_MonHoc_NLPC_ID
        FROM
               dbo.tblMonHocLop              MHL
               --INNER JOIN dbo.tblLop         AS l ON l.LopID                       = MHL.LopNhomID
               --                                  AND l.Enable                      = 1
               -- AND l.GVCN =  @SYS_USERID
               INNER JOIN dbo.tblMonHoc      MH ON MHL.MonHocID                    = MH.MonHocID
                                               AND MH.Enable                       = 1
                                               AND
                                                   (
                                                       MH.TenMonDuLieuNganh NOT LIKE N'%Năng lực%'
                                                 AND   MH.TenMonDuLieuNganh NOT LIKE N'%Phẩm chất%'
                                                   )
               INNER JOIN dbo.tblGiaoVienLop gvl ON gvl.MonHocID                   = MH.MonHocID
                                                AND gvl.GiaoVienID                 = @SYS_USERID --(CASE WHEN @SYS_USERID = 'NA0000022' THEN gvl.GiaoVienID ELSE @SYS_USERID END)
                                                AND CAST(gvl.LopID AS VARCHAR(10)) = MHL.LopNhomID
                                                AND gvl.VaiTro IN (3)
                                                AND gvl.Enable                     = 1
                                                AND gvl.HocKy                      = @HocKi
        WHERE
               MHL.NienKhoa = @NienKhoa
          AND  MHL.[Enable]  = 1
          AND  MHL.LopNhomID = @LopID;
    END;

    IF (@SYS_SystemRight IN (5, 7, 9))
    BEGIN
        SELECT MonHocLopID
             , mh.MonHocID
             , MonHocCode
             , MonHocName
             , MonHocGroup
             , TenMonDuLieuNganh
             , LopNhomID
             , NienKhoa
             , GVGiangDay1
             , GVGiangDay2
             , TemplateBangDiemID
             , TemplateReportHTML
             , TemplateReportPDF
             , Is_MonHoc_BoTro
             , TenMonHoc_HienThi
             , List_MonHoc_NLPC_ID
        FROM
               dbo.tblMonHocLop         mhl
               INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = mhl.MonHocID
                                          AND mh.Enable   = 1
        WHERE
               LopNhomID = @LopID
          AND  mhl.Enable = 1;
    END;
    ELSE
    BEGIN
        SELECT MonHocLopID
             , MonHocID
             , MonHocCode
             , MonHocName
             , MonHocGroup
             , TenMonDuLieuNganh
             , LopNhomID
             , NienKhoa
             , GVGiangDay1
             , GVGiangDay2
             , TemplateBangDiemID
             , TemplateReportHTML
             , TemplateReportPDF
             , Is_MonHoc_BoTro
             , TenMonHoc_HienThi
             , List_MonHoc_NLPC_ID
        FROM
               @Table;
    END;
END;