-- [spAPI_HocSinhBangDiem_Get_ByMonHocID_MaNhom] '2362', 1, 3, 'DiemGK_Viet_HK1', 'NA0000022',9
CREATE PROC [dbo].[spAPI_HocSinhBangDiem_Get_ByMonHocID_MaNhom_PCNL] --'N241001', 76, 78, 'Theme_1', 'NA0000022',9
    @LopID              VARCHAR(10)
  , @MonHocID           INT
  , @TemplateBangDiemID INT
  , @MaNhomCotDiem      NVARCHAR(100)
  , @SYS_USERID         VARCHAR(9)
  , @Sys_GroupID        INT
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
             , HS.Ho + ' ' + HS.Ten                                                     AS HoTen
             , BD.CotDiemID                                                             AS CotDiemID
             , BD.MaCotDiem
             , BD.LoaiCotDiem
             , BD.GiaTriCotDiem                                                         AS GiaTriCotDiem
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
             , ISNULL(KQ.TinhTrang, 0)                                                  AS TinhTrang
             , BD.WidthCSS
             , KQ.Is_Reject_TT                                                          AS Is_Reject_TT
             , KQ.ReasonReject_TT                                                       AS ReasonReject_TT
             , CASE WHEN KQ.NhapDiemUser = @SYS_USERID THEN CAST(1 AS BIT)ELSE NULL END AS Is_Comment
             , KQ.NhapDiemUser
        FROM
               dbo.tblHocSinh                         HS
               INNER JOIN dbo.tblHocSinhLop           HSL ON HS.HocSinhID           = HSL.HocSinhID
                                                         AND HSL.LopID              = @LopID
               INNER JOIN dbo.tblMonHocLop            MHL ON MHL.LopNhomID          = HSL.LopID
                                                         AND MHL.TemplateBangDiemID = @TemplateBangDiemID
               INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID   = MHL.TemplateBangDiemID
                                                        AND
                                                            (
                                                                @MaNhomCotDiem IS NULL
                                                           OR   BD.MaNhomCotDiem        = @MaNhomCotDiem
                                                            )
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
             , HSN.SoTT                                                                 AS SoDanhBo
             , HS.[Ho]
             , HS.[Ten]
             , HS.[NgaySinh]
             , HS.[Nu]
             , HS.Ho + ' ' + HS.Ten                                                     AS HoTen
             , BD.CotDiemID                                                             AS CotDiemID
             , BD.MaCotDiem
             , BD.LoaiCotDiem
             , BD.GiaTriCotDiem                                                         AS GiaTriCotDiem
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
             , ISNULL(KQ.TinhTrang, 0)                                                  AS TinhTrang
             , BD.WidthCSS
             , KQ.Is_Reject_TT                                                          AS Is_Reject_TT
             , KQ.ReasonReject_TT                                                       AS ReasonReject_TT
             , CASE WHEN KQ.NhapDiemUser = @SYS_USERID THEN CAST(1 AS BIT)ELSE NULL END AS Is_Comment
             , KQ.NhapDiemUser
        FROM
               dbo.tblHocSinh                         HS
               INNER JOIN dbo.tblHocSinhNhom          HSN ON HS.HocSinhID           = HSN.HocSinhID
                                                         AND HSN.NhomID             = @LopNhomID
               INNER JOIN dbo.tblMonHocLop            MHL ON MHL.LopNhomID          = HSN.NhomID
                                                         AND MHL.TemplateBangDiemID = @TemplateBangDiemID
               INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID   = MHL.TemplateBangDiemID
                                                        AND
                                                            (
                                                                @MaNhomCotDiem IS NULL
                                                           OR   BD.MaNhomCotDiem        = @MaNhomCotDiem
                                                            )
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