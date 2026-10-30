-- [spAPI_HocSinhBangDiem_TT_BGH_Get_C2] 2291, 'HK2', 'NA0000022',9
CREATE PROC [dbo].[spAPI_HocSinhBangDiem_TT_BGH_Get_C2]
 @NienKhoa INT = 2024,
    @LopID       VARCHAR(10),
    @Semester    VARCHAR(3),
    @SYS_USERID  VARCHAR(9),
    @Sys_GroupID INT
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @tblSort AS TABLE (STT INT,  MaCotDiem NVARCHAR(200), MaCotDiemHienThi NVARCHAR(200),  TenCotDiem_HienThi NVARCHAR(200))
	INSERT INTO @tblSort(STT, MaCotDiem, MaCotDiemHienThi, TenCotDiem_HienThi)
	SELECT 1 , N'TX_L1_HK2', N'TX_L1_HK2', N'TX1'
	UNION
	SELECT 1 , N'Theme5_Total', N'TX_L1_HK2', N'TX1'
	UNION
	SELECT 2 , N'TX_L2_HK2', N'TX_L2_HK2', N'TX2'
	UNION
	SELECT 2 , N'Theme6_Total', N'TX_L2_HK2', N'TX2'
	UNION
	SELECT 3 , N'TX_L3_HK2', N'TX_L3_HK2', N'TX3'
	UNION
	SELECT 3 , N'Theme7_Total', N'TX_L3_HK2', N'TX3'
	UNION
	SELECT 4 , N'TX_L4_HK2', N'TX_L4_HK2', N'TX4'
	UNION
	SELECT 4 , N'Theme8_Total', N'TX_L4_HK2', N'TX4'
	UNION
	SELECT 5 , N'DiemGK_HK2', N'DiemGK_HK2', N'GK'
	UNION
	SELECT 5 , N'S2_Mid_Total_Point', N'DiemGK_HK2', N'GK'
	UNION
	SELECT 6 , N'DiemCK_HK2', N'DiemCK_HK2', N'CK'
	UNION
	SELECT 6 , N'S2_Final_Total_Point', N'DiemCK_HK2', N'CK'
	UNION
	SELECT 7 , N'DiemTB_HK2', N'DiemTB_HK2', N'ĐTB'

    DECLARE @LopNhomID VARCHAR(10) = @LopID;
    DECLARE @IsNumber BIT = IIF(TRY_CAST(@LopID AS INT) IS NOT NULL, 1, 0);


    IF @IsNumber = 1
    BEGIN
        -- Khi LopID là số: xử lý theo bảng tblHocSinhLop
        SELECT 
            HS.HocSinhID,
            HSL.SoDanhBo,
            HS.Ho,
            HS.Ten,
            HS.NgaySinh,
            HS.Nu,
            HS.Ho + ' ' + HS.Ten AS HoTen,
            BD.CotDiemID,
            S.MaCotDiemHienThi AS MaCotDiem,
            BD.LoaiCotDiem,
            BD.GiaTriCotDiem,
            BD.KieuDanhGiaID,
            S.TenCotDiem_HienThi  AS TenCotDiem_VI,
           -- BD.TenCotDiem_EN,
            BD.ThuTuCotDiem,
            BD.MaNhomCotDiem,
            BD.TenNhomCotDiem_VI,
          --  BD.TenNhomCotDiem_EN,
            CASE WHEN BD.MaCotDiem IN('S2_Mid_Total_Point','S2_Final_Total_Point') THEN ROUND(KQ.KetQuaDanhGia_VI,1) ELSE KQ.KetQuaDanhGia_VI END AS KetQuaDanhGia_VI,
         --   KQ.KetQuaDanhGia_EN,
            BD.HexBackground,
            BD.Formula,
            BD.DiemMin,
            BD.DiemMax,
            BD.QuyenNhapDiem,
            BD.WidthCSS,
            l_tt.Lop_TinhTrangID,
            ISNULL(l_tt.TinhTrang, 0) AS TinhTrang,
            l_tt.NoiDungNhanXet,
            dbo.RenderTinhTrang(l_tt.TinhTrang) AS TenTinhTrang,
            dbo.RenderColorTinhTrang(l_tt.TinhTrang) AS MauTinhTrang,
            l_tt.Is_GVCN_DaDuyet,
            IIF(KQ.NhapDiemUser = @SYS_USERID, 1, 0) AS Is_Comment,
            KQ.NhapDiemUser,
            KQ.MonHocLopID,
            mh.TenMonDuLieuNganh,
            mh.TenMonHoc_HienThi,
            MHL.MonHocID,
            MHL.MonHocLopID,
            mh.Is_MonHoc_BoTro,
            CONVERT(VARCHAR(20), KQ.NhapDiemTime, 120) AS NhapDiemTime,
           -- dbo.Count_Log_Diem(@LopID, KQ.MonHocLopID, BD.MaNhomCotDiem, KQ.HocSinhID) AS
		   1 as Count_Log_Diem
        FROM dbo.tblHocSinh HS WITH (NOLOCK)
        INNER JOIN dbo.tblHocSinhLop HSL ON HS.HocSinhID = HSL.HocSinhID AND HSL.LopID = TRY_CAST(@LopID AS INT) AND HSL.Enable = 1
        INNER JOIN dbo.tblMonHocLop MHL ON MHL.LopNhomID = HSL.LopID and mhl.Enable =1
        INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = MHL.MonHocID

        INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID = MHL.TemplateBangDiemID
                                                AND BD.Semester = @Semester AND BD.Enable = 1
		INNER JOIN @tblSort S ON BD.MaCotDiem = S.MaCotDiem
        INNER JOIN dbo.tblKetQuaHocTap KQ ON KQ.HocSinhID = HS.HocSinhID
                                        AND KQ.CotDiemID = BD.CotDiemID
                                        AND KQ.MonHocLopID = MHL.MonHocLopID
                                        AND KQ.Enable = 1
										AND KQ.NienKhoa = @NienKhoa
        LEFT JOIN dbo.tblLop_TinhTrang l_tt ON l_tt.Lop_TinhTrangID = KQ.Lop_TinhTrangID AND l_tt.Enable = 1
        WHERE HS.TinhTrang = 0 AND BD.MaCotDiem in ( 'Theme5_Total','Theme6_Total', 'Theme7_Total', 'Theme8_Total', 'S2_Mid_Total_Point','S2_Final_Total_Point','TX_L1_HK2',  'TX_L2_HK2' ,'TX_L3_HK2', 'TX_L4_HK2','DiemGK_HK2','DiemCK_HK2', 'DiemTB_HK2')
        ORDER BY  mh.Sort,HSL.SoDanhBo, BD.ThuTuNhom,  BD.ThuTuCotDiem;
    END
    ELSE
    BEGIN
        -- Khi LopID là chuỗi: xử lý theo bảng tblHocSinhNhom
        SELECT 
            HS.HocSinhID,
            HSN.SoTT AS SoDanhBo,
            HS.Ho,
            HS.Ten,
            HS.NgaySinh,
            HS.Nu,
            HS.Ho + ' ' + HS.Ten AS HoTen,
            BD.CotDiemID,
            BD.MaCotDiem,
            BD.LoaiCotDiem,
            BD.GiaTriCotDiem,
            BD.KieuDanhGiaID,
            BD.TenCotDiem_VI,
           -- BD.TenCotDiem_EN,
            BD.ThuTuCotDiem,
            BD.MaNhomCotDiem,
            BD.TenNhomCotDiem_VI,
           -- BD.TenNhomCotDiem_EN,
            KQ.KetQuaDanhGia_VI,
           -- KQ.KetQuaDanhGia_EN,
            BD.HexBackground,
            BD.Formula,
            BD.DiemMin,
            BD.DiemMax,
            BD.QuyenNhapDiem,
            BD.WidthCSS,
            ISNULL(KQ.TinhTrang, 0) AS TinhTrang,
            dbo.RenderColorTinhTrang(ISNULL(KQ.TinhTrang, 0)) AS MauTinhTrang,
            dbo.RenderTinhTrang(ISNULL(KQ.TinhTrang, 0)) AS TenTinhTrang,
            IIF(KQ.NhapDiemUser = @SYS_USERID, 1, 0) AS Is_Comment,
            KQ.NhapDiemUser,
            mh.TenMonDuLieuNganh,
            mh.TenMonHoc_HienThi,
            MHL.MonHocID,
            MHL.MonHocLopID,
            mh.Is_MonHoc_BoTro
        FROM dbo.tblHocSinh HS WITH (NOLOCK)
        INNER JOIN dbo.tblHocSinhNhom HSN ON HS.HocSinhID = HSN.HocSinhID AND HSN.NhomID = @LopNhomID and hsn.Enable = 1
        INNER JOIN dbo.tblMonHocLop MHL ON MHL.LopNhomID = HSN.NhomID and MHL.Enable = 1
        INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = MHL.MonHocID
        INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID = MHL.TemplateBangDiemID
                                                AND BD.Semester = @Semester AND BD.Enable = 1
        INNER JOIN dbo.tblKetQuaHocTap KQ ON KQ.HocSinhID = HS.HocSinhID
                                        AND KQ.CotDiemID = BD.CotDiemID
                                        AND KQ.MonHocLopID = MHL.MonHocLopID
                                        AND KQ.Enable = 1
										AND KQ.NienKhoa = @NienKhoa
        WHERE HS.TinhTrang = 0
        ORDER BY mh.Sort,HSN.SoTT, BD.ThuTuNhom, BD.ThuTuCotDiem;
    END
END
