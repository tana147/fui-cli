-- [dbo].[spAPI_NhomCauTrucDiem_Get_ByTemplateBangDiemID] 621, '1',1 ,9
CREATE PROC [dbo].[spAPI_NhomCauTrucDiem_Get_ByTemplateBangDiemID] -- 4,'',0
    @TemplateBangDiemID INT
  , @SYS_USERID         VARCHAR(9)
  , @Sys_GroupID        INT
  , @SYS_SystemRight    INT
AS
BEGIN
    DECLARE @Month INT = MONTH(GETDATE());
    DECLARE @Year INT = YEAR(GETDATE());
	DECLARE @HocKy NVARCHAR(200)
    DECLARE @TemplateNienKhoa INT;
    SELECT @TemplateNienKhoa = NienKhoa 
    FROM dbo.TemplateBangDiem 
    WHERE TemplateBangDiemID = @TemplateBangDiemID;

    IF (@SYS_SystemRight IN (9) OR @TemplateNienKhoa < dbo.fn_GetNienKhoa_HienTai())
    BEGIN
        SET @HocKy = N'HK1,HK2,CaNam';
    END;
    ELSE
    BEGIN
        -- Xác định niên khóa và học kỳ
        IF @Month BETWEEN 8 AND 11
        BEGIN
            SET @HocKy = N'HK1';
        END;
        ELSE IF @Month = 12
        BEGIN
            SET @HocKy = N'HK1,HK2';
        END;
        ELSE -- Các tháng còn lại (1 đến 7)
        BEGIN
            SET @HocKy = N'HK1,HK2,CaNam';
        END;
    END;

    -- Sử dụng STRING_SPLIT để tách thành từng giá trị
    SELECT DISTINCT
           MaNhomCotDiem
         , TenNhomCotDiem_VI
         , TenNhomCotDiem_EN
         , ThuTuNhom
         , Semester
    FROM
           dbo.TemplateBangDiemChiTiet
    WHERE
           TemplateBangDiemID = @TemplateBangDiemID
      AND  Enable              = 1
      AND  Semester IN
           (
               SELECT value
               FROM
                      STRING_SPLIT(@HocKy, ',')
           )
    ORDER BY
           ThuTuNhom
         , Semester;

END;
