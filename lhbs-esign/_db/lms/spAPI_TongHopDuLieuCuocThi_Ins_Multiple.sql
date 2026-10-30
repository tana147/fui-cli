
CREATE PROCEDURE [dbo].[spAPI_TongHopDuLieuCuocThi_Ins_Multiple]
    @JSON_HocSinh NVARCHAR(MAX),
    @NienKhoa INT,
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------
    -- 1. TABLE VARIABLE (KHÔNG dùng @ cho cột)
    --------------------------------------------------
    DECLARE @Table_HocSinh TABLE (
        HocSinhID INT,
        TenLop NVARCHAR(50),
        LopID INT,
        ThoiGianThi NVARCHAR(50),
        HocKi NVARCHAR(50),
        TenCuocThi NVARCHAR(100),
        LinhVucDuAn NVARCHAR(50),
        MoTaNganGonNoiDung_MucTieu NVARCHAR(200),
        GVHuongDan NVARCHAR(50),
        To_BoPhan NVARCHAR(50),
        GV_ToHoTro NVARCHAR(50),
        ToChucCongNhan NVARCHAR(50),
        CapDoGiaiThuong NVARCHAR(50),
        GiaiThuongDatDuoc NVARCHAR(50),
        MinhChung_SoHieuQD_LinkChungNhan NVARCHAR(50),
        GhiChuBoSung NVARCHAR(50)
    );

    --------------------------------------------------
    -- 2. Đổ dữ liệu từ JSON
    --------------------------------------------------
    INSERT INTO @Table_HocSinh (
        HocSinhID,
        TenLop,
        LopID,
        ThoiGianThi,
        HocKi,
        TenCuocThi,
        LinhVucDuAn,
        MoTaNganGonNoiDung_MucTieu,
        GVHuongDan,
        To_BoPhan,
        GV_ToHoTro,
        ToChucCongNhan,
        CapDoGiaiThuong,
        GiaiThuongDatDuoc,
        MinhChung_SoHieuQD_LinkChungNhan,
        GhiChuBoSung
    )
    SELECT
        HocSinhID,
        TenLop,
        (
            SELECT TOP 1 l.LopID
            FROM dbo.tblLop l
            WHERE l.NienKhoa = @NienKhoa
              AND l.TenLop = js.TenLop
        ) AS LopID,
        ThoiGianThi,
        HocKi,
        TenCuocThi,
        LinhVucDuAn,
        MoTaNganGonNoiDung_MucTieu,
        GVHuongDan,
        To_BoPhan,
        GV_ToHoTro,
        ToChucCongNhan,
        CapDoGiaiThuong,
        GiaiThuongDatDuoc,
        MinhChung_SoHieuQD_LinkChungNhan,
        GhiChuBoSung
    FROM OPENJSON(@JSON_HocSinh)
    WITH (
        HocSinhID INT,
        TenLop NVARCHAR(50),
        ThoiGianThi NVARCHAR(50),
        HocKi NVARCHAR(50),
        TenCuocThi NVARCHAR(100),
        LinhVucDuAn NVARCHAR(50),
        MoTaNganGonNoiDung_MucTieu NVARCHAR(200),
        GVHuongDan NVARCHAR(50),
        To_BoPhan NVARCHAR(50),
        GV_ToHoTro NVARCHAR(50),
        ToChucCongNhan NVARCHAR(50),
        CapDoGiaiThuong NVARCHAR(50),
        GiaiThuongDatDuoc NVARCHAR(50),
        MinhChung_SoHieuQD_LinkChungNhan NVARCHAR(50),
        GhiChuBoSung NVARCHAR(50)
    ) js;

    --------------------------------------------------
    -- 3. Insert vào bảng chính
    --------------------------------------------------
    INSERT INTO dbo.tblTong_Hop_Du_Lieu_Cuoc_Thi
    (
        NienKhoa,
        HocSinhID,
        LopID,
        ThoiGianThi,
        HocKi,
        TenCuocThi,
        LinhVucDuAn,
        MoTaNganGonNoiDung_MucTieu,
        GVHuongDan,
        To_BoPhan,
        GV_ToHoTro,
        ToChucCongNhan,
        CapDoGiaiThuong,
        GiaiThuongDatDuoc,
        MinhChung_SoHieuQD_LinkChungNhan,
        GhiChuBoSung,
        Enable,
        CreateUser,
        CreateTime
    )
    SELECT
        @NienKhoa,
        HocSinhID,
        LopID,
        ThoiGianThi,
        HocKi,
        TenCuocThi,
        LinhVucDuAn,
        MoTaNganGonNoiDung_MucTieu,
        GVHuongDan,
        To_BoPhan,
        GV_ToHoTro,
        ToChucCongNhan,
        CapDoGiaiThuong,
        GiaiThuongDatDuoc,
        MinhChung_SoHieuQD_LinkChungNhan,
        GhiChuBoSung,
        1,
        @SYS_USERID,
        GETDATE()
    FROM @Table_HocSinh;
END;
