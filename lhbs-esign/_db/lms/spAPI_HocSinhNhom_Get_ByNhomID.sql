CREATE PROC [dbo].[spAPI_HocSinhNhom_Get_ByNhomID]
    @NienKhoa INT,
    @NhomID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Đồng bộ quy tắc sắp xếp phân nhóm với spAPI_HocSinhBangDiem_Get_ByMonHocID_MaNhom (nhap-diem):
    -- Nếu trong nhóm có bất kỳ học sinh nào chưa có SoTT thì sort theo Ten, Ho;
    -- ngược lại sort theo SoTT, Ten, Ho.
    DECLARE @HasSoTTNull BIT = 0;
    IF EXISTS (
        SELECT TOP 1 1
        FROM dbo.tblHocSinhNhom AS hsn
             INNER JOIN dbo.tblHocSinh AS hs ON hs.HocSinhID = hsn.HocSinhID
                                            AND hs.TinhTrang = 0
        WHERE hsn.NhomID = @NhomID
          AND hsn.SoTT IS NULL
          AND hsn.Enable = 1
    )
    BEGIN
        SET @HasSoTTNull = 1;
    END;

    SELECT
        hsn.HSNhomID,
        hsn.HocSinhID,
        hsn.NhomID,
        hsn.LopID,
        hsn.SoTT,
        hs.Ho,
        hs.Ten,
        hs.Ho + ' ' + hs.Ten AS HoTen,
        hs.TinhTrang,
        hs.TenTinhTrang,
        hs.EnglishName,
        l.TenLop,
        mhl.MonHocLopID
    FROM dbo.tblHocSinhNhom AS hsn
    INNER JOIN dbo.tblNhom AS n
        ON n.NhomID = hsn.NhomID
       AND n.NienKhoa = @NienKhoa
       AND n.Enable = 1
    INNER JOIN dbo.tblHocSinh AS hs
        ON hs.HocSinhID = hsn.HocSinhID
       AND hs.TinhTrang = 0
    INNER JOIN dbo.tblLop AS l
        ON l.LopID = hsn.LopID
       AND l.NienKhoa = @NienKhoa
       AND l.Enable = 1
    INNER JOIN dbo.tblMonHocLop AS mhl
        ON mhl.LopNhomID = hsn.NhomID
       AND mhl.NienKhoa = @NienKhoa
       AND mhl.Enable = 1
    WHERE hsn.NhomID = @NhomID
      AND hsn.Enable = 1
    ORDER BY
        CASE WHEN @HasSoTTNull = 1 THEN NULL ELSE hsn.SoTT END,
        hs.Ten,
        hs.Ho;
END