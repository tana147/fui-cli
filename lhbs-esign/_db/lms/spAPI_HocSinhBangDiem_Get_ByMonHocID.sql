--  [dbo].[spAPI_HocSinhBangDiem_Get_ByMonHocID_MaNhom] 2376, 46, 48, 'DiemCK_HK1', '',0

-- [spAPI_HocSinhBangDiem_Get_ByMonHocID] 2376, 46, 48,  '',0
CREATE PROC [dbo].[spAPI_HocSinhBangDiem_Get_ByMonHocID]
    @LopID              VARCHAR(10)
  , @NienKhoa           INT
  , @MonHocID           INT
  , @TemplateBangDiemID INT
  , @SYS_USERID         VARCHAR(9)
--, @Sys_GroupID        INT
AS
BEGIN

    DECLARE @LopNhomID VARCHAR(10);
    SET @LopNhomID = @LopID;
    -- Truy vấn tối ưu sử dụng LEFT JOIN
    -- Truy vấn khi LopID là số
    -- Kiểm tra loại LopID (số hay chuỗi)
    DECLARE @IsNumber BIT = CASE WHEN ISNUMERIC(@LopID) = 1 THEN 1 ELSE 0 END;
    IF @IsNumber = 1
    BEGIN
        SELECT HS.[HocSinhID]
             , HSL.SoDanhBo
             , HS.[Ho]
             , HS.[Ten]
             , HS.[NgaySinh]
             , HS.[Nu]
             , BD.CotDiemID            AS CotDiemID
             , BD.MaCotDiem
             , BD.LoaiCotDiem
             , BD.GiaTriCotDiem        AS GiaTriCotDiem
             , BD.KieuDanhGiaID
             , BD.TenCotDiem_VI
             , BD.TenCotDiem_EN
             , BD.ThuTuCotDiem
             , BD.MaNhomCotDiem
             , BD.TenNhomCotDiem_VI
             , BD.TenNhomCotDiem_EN
             , KQ.KetQuaDanhGia_VI
             , KQ.KetQuaDanhGia_EN
             , BD.HexBackground
             , BD.Formula
             , BD.DiemMin
             , BD.DiemMax
             , BD.QuyenNhapDiem
             , BD.WidthCSS
             , ISNULL(KQ.TinhTrang, 0) AS TinhTrang
             , CASE
                    WHEN KQ.NhapDiemUser = @SYS_USERID THEN CAST(1 AS BIT)
                    ELSE CAST(0 AS BIT)
               END                     AS Is_Comment
             , KQ.NhapDiemUser
        FROM
               dbo.tblHocSinh                         HS
               INNER JOIN dbo.tblHocSinhLop           HSL ON HS.HocSinhID           = HSL.HocSinhID
                                                         AND HSL.LopID              = CAST(@LopID AS INT)
               INNER JOIN dbo.tblMonHocLop            MHL ON MHL.LopNhomID          = HSL.LopID
                                                         AND MHL.TemplateBangDiemID = @TemplateBangDiemID
                                                         AND MHL.NienKhoa           = @NienKhoa
               INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID   = MHL.TemplateBangDiemID
                                                        AND BD.Enable               = 1
               LEFT JOIN dbo.tblKetQuaHocTap          KQ ON KQ.HocSinhID            = HS.HocSinhID
                                                        AND KQ.CotDiemID            = BD.CotDiemID
                                                        AND KQ.MonHocLopID          = MHL.MonHocLopID
                                                        AND KQ.Enable               = 1
        WHERE
               HS.TinhTrang = 0
          AND  HSL.Enable    = 1
        ORDER BY
               HSL.SoDanhBo
             , BD.ThuTuNhom
             , BD.ThuTuCotDiem;
    END;
    ELSE
    BEGIN
        -- Truy vấn khi LopID là chuỗi
        SELECT HS.[HocSinhID]
             , HSN.SoTT                AS SoDanhBo
             , HS.[Ho]
             , HS.[Ten]
             , HS.[NgaySinh]
             , HS.[Nu]
             , BD.CotDiemID            AS CotDiemID
             , BD.MaCotDiem
             , BD.LoaiCotDiem
             , BD.GiaTriCotDiem        AS GiaTriCotDiem
             , BD.KieuDanhGiaID
             , BD.TenCotDiem_VI
             , BD.TenCotDiem_EN
             , BD.ThuTuCotDiem
             , BD.MaNhomCotDiem
             , BD.TenNhomCotDiem_VI
             , BD.TenNhomCotDiem_EN
             , KQ.KetQuaDanhGia_VI
             , KQ.KetQuaDanhGia_EN
             , BD.HexBackground
             , BD.Formula
             , BD.DiemMin
             , BD.DiemMax
             , BD.QuyenNhapDiem
             , BD.WidthCSS
             , ISNULL(KQ.TinhTrang, 0) AS TinhTrang
             , CASE
                    WHEN KQ.NhapDiemUser = @SYS_USERID THEN CAST(1 AS BIT)
                    ELSE CAST(0 AS BIT)
               END                     AS Is_Comment
             , KQ.NhapDiemUser
        FROM
               dbo.tblHocSinh                         HS
               INNER JOIN dbo.tblHocSinhNhom          HSN ON HS.HocSinhID           = HSN.HocSinhID
                                                         AND HSN.NhomID             = @LopNhomID
														 and hsn.Enable = 1
               INNER JOIN dbo.tblMonHocLop            MHL ON MHL.LopNhomID          = HSN.NhomID
                                                         AND MHL.TemplateBangDiemID = @TemplateBangDiemID
                                                         AND MHL.NienKhoa           = @NienKhoa
               INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID   = MHL.TemplateBangDiemID
                                                        AND BD.Enable               = 1
               LEFT JOIN dbo.tblKetQuaHocTap          KQ ON KQ.HocSinhID            = HS.HocSinhID
                                                        AND KQ.CotDiemID            = BD.CotDiemID
                                                        AND KQ.MonHocLopID          = MHL.MonHocLopID
                                                        AND KQ.Enable               = 1
        WHERE
               HS.TinhTrang = 0
        ORDER BY
               HSN.SoTT
             , BD.ThuTuNhom
             , BD.ThuTuCotDiem;
    END;
END;