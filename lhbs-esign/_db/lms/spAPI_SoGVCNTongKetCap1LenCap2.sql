CREATE   PROCEDURE dbo.spAPI_SoGVCNTongKetCap1LenCap2
    @NienKhoa int,
    @JsonLop nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Lop TABLE
    (
        LopID varchar(10) NOT NULL PRIMARY KEY
    );

    INSERT INTO @Lop(LopID)
    SELECT DISTINCT CAST(JSON_VALUE(value, '$.LopID') AS varchar(10))
    FROM OPENJSON(@JsonLop)
    WHERE ISNULL(JSON_VALUE(value, '$.LopID'), '') <> '';

    SELECT
        hsl.HocSinhID,
        hsl.HSLopID,
        LopID = hsl.LopID,
        Toan = MAX(CASE WHEN mhl.MonHocID = 2 THEN NULLIF(LTRIM(RTRIM(kq.KetQuaDanhGia_VI)), '') END),
        Van = MAX(CASE WHEN mhl.MonHocID = 1 THEN NULLIF(LTRIM(RTRIM(kq.KetQuaDanhGia_VI)), '') END),
        Anh = MAX(CASE WHEN mhl.MonHocID = 5 THEN NULLIF(LTRIM(RTRIM(kq.KetQuaDanhGia_VI)), '') END)
    FROM dbo.tblHocSinhLop hsl
    INNER JOIN @Lop lop
        ON lop.LopID = hsl.LopID
    INNER JOIN dbo.tblMonHocLop mhl
        ON mhl.LopNhomID = hsl.LopID
       AND mhl.NienKhoa = @NienKhoa
       AND mhl.MonHocID IN (1, 2, 5)
       AND mhl.Enable = 1
    INNER JOIN dbo.TemplateBangDiemChiTiet tbct
        ON tbct.TemplateBangDiemID = mhl.TemplateBangDiemID
       AND tbct.MaCotDiem = N'DiemCK_HK2'
    INNER JOIN dbo.tblKetQuaHocTap kq
        ON kq.HocSinhID = hsl.HocSinhID
       AND kq.LopID = hsl.LopID
       AND kq.NienKhoa = @NienKhoa
       AND kq.MonHocLopID = mhl.MonHocLopID
       AND kq.CotDiemID = tbct.CotDiemID
       AND kq.Enable = 1
    WHERE hsl.Enable = 1
    GROUP BY
        hsl.HocSinhID,
        hsl.HSLopID,
        hsl.LopID;
END
