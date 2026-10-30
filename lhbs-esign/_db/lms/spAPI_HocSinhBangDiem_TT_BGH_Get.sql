-- [spAPI_HocSinhBangDiem_TT_BGH_Get]2025, 2477, 'GK_HK1', 'NA0000022',9
CREATE PROC [dbo].[spAPI_HocSinhBangDiem_TT_BGH_Get]
    @NienKhoa    INT
  , @LopID       VARCHAR(10)
  , @Semester    VARCHAR(10)
  , @SYS_USERID  VARCHAR(9)
  , @Sys_GroupID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @tblSort AS TABLE (STT INT, TenCotDiem_VI NVARCHAR(200), TenCotDiem_HienThi NVARCHAR(200))
    INSERT INTO @tblSort(STT, TenCotDiem_VI, TenCotDiem_HienThi)
	VALUES	(1 , N'Mức độ đánh giá giữa HK1', N'Mức đạt được'),
			(2 , N'Điểm kiểm tra giữa HK1', N'Điểm KTĐK'),
			(3 , N'Nhận xét giữa HK1', N'Nhận xét'),

			(1 , N'Mức độ đánh giá cuối HK1', N'Mức đạt được'),
			(2 , N'Điểm kiểm tra cuối HK1', N'Điểm KTĐK'),
			(3 , N'Nhận xét cuối HK1', N'Nhận xét'),

			(1 , N'Mức độ đánh giá giữa HK2', N'Mức đạt được'),
			(2 , N'Điểm kiểm tra giữa HK2', N'Điểm KTĐK'),
			(3 , N'Nhận xét giữa HK2', N'Nhận xét'),

			(1 , N'Mức độ đánh giá cuối HK2', N'Mức đạt được'),
			(2 , N'Điểm kiểm tra cuối HK2', N'Điểm KTĐK'),
			(3 , N'Nhận xét cuối HK2', N'Nhận xét'),

			(1 , N'Điểm', N'Điểm'), 
			(1 , N'Quy đổi sao giữa HK1', N'Quy đổi sao'),
			(1 , N'Nhận xét', N'Nhận xét'),

			(1 , N'Điểm', N'Điểm'), 
			(1 , N'Quy đổi sao cuối HK1', N'Quy đổi sao'),
			(1 , N'Nhận xét', N'Nhận xét'),

			(1 , N'Điểm', N'Điểm'), 
			(1 , N'Quy đổi sao giữa HK2', N'Quy đổi sao'),
			(1 , N'Nhận xét', N'Nhận xét'),

			(1 , N'Điểm', N'Điểm'), 
			(1 , N'Quy đổi sao cuối HK2', N'Quy đổi sao'),
			(1 , N'Nhận xét', N'Nhận xét')


    SELECT HS.HocSinhID
         , HSL.SoDanhBo
         , HS.Ho
         , HS.Ten
         , HS.NgaySinh
         , HS.Nu
         , HS.Ho + ' ' + HS.Ten                       AS HoTen
         , BD.CotDiemID
         , BD.MaCotDiem
         , BD.LoaiCotDiem
         , BD.GiaTriCotDiem
         , BD.KieuDanhGiaID
          , S.TenCotDiem_HienThi AS TenCotDiem_VI
         --, BD.TenCotDiem_VI
         -- BD.TenCotDiem_EN,
         , BD.ThuTuCotDiem
         , BD.MaNhomCotDiem
         , BD.TenNhomCotDiem_VI
         --  BD.TenNhomCotDiem_EN,
         , KQ.KetQuaDanhGia_VI
         --   KQ.KetQuaDanhGia_EN,
         , BD.HexBackground
         , BD.Formula
         , BD.DiemMin
         , BD.DiemMax
         , BD.QuyenNhapDiem
         , BD.WidthCSS
         , l_tt.Lop_TinhTrangID
         , ISNULL(l_tt.TinhTrang, 0)                  AS TinhTrang
         , l_tt.NoiDungNhanXet
         , dbo.RenderTinhTrang(l_tt.TinhTrang)        AS TenTinhTrang
         , dbo.RenderColorTinhTrang(l_tt.TinhTrang)   AS MauTinhTrang
         , l_tt.Is_GVCN_DaDuyet
         , IIF(KQ.NhapDiemUser = @SYS_USERID, 1, 0)   AS Is_Comment
         , KQ.NhapDiemUser
         , mh.TenMonDuLieuNganh
         , mh.TenMonHoc_HienThi
         , MHL.MonHocID
         , kq.MonHocLopID
         , mh.Is_MonHoc_BoTro
         , CONVERT(VARCHAR(20), KQ.NhapDiemTime, 120) AS NhapDiemTime
         , 1                                          AS Count_Log_Diem
    --dbo.Count_Log_Diem(@LopID, KQ.MonHocLopID, BD.MaNhomCotDiem, KQ.HocSinhID) AS Count_Log_Diem
    FROM
           dbo.tblHocSinh                         HS WITH (NOLOCK)
           INNER JOIN dbo.tblHocSinhLop           HSL ON HS.HocSinhID          = HSL.HocSinhID
                                                     AND HSL.LopID             =  @LopID 
                                                     AND HSL.Enable            = 1
           INNER JOIN dbo.tblMonHocLop             MHL ON MHL.LopNhomID         = HSL.LopID
                                                     AND MHL.Enable            = 1
           LEFT JOIN dbo.tblMonHoc                mh ON mh.MonHocID            = MHL.MonHocID
           INNER JOIN dbo.TemplateBangDiemChiTiet BD ON BD.TemplateBangDiemID  = MHL.TemplateBangDiemID
                                                    AND BD.Enable              = 1
                                                    AND BD.MaCotDiem IN (
														'Diem' + @Semester, 
														'MucDoDanhGia' + @Semester, 
														'NhanXet' + @Semester,
														'Sao' + @Semester
														)
          INNER JOIN @tblSort S ON BD.TenCotDiem_VI = S.TenCotDiem_VI
           LEFT JOIN dbo.tblKetQuaHocTap          KQ ON KQ.HocSinhID           = HS.HocSinhID
                                                    AND KQ.CotDiemID           = BD.CotDiemID
                                                    AND KQ.MonHocLopID         = MHL.MonHocLopID
                                                    AND KQ.Enable              = 1
                                                    AND KQ.NienKhoa            = @NienKhoa
           LEFT JOIN dbo.tblLop_TinhTrang         l_tt ON l_tt.Lop_TinhTrangID = KQ.Lop_TinhTrangID
                                                      AND l_tt.Enable          = 1
    WHERE
           HS.TinhTrang = 0 --AND MaCotDiem in ('DiemCK_HK2','MucDoDanhGiaCK_HK2','NhanXetCK_HK2')
    ORDER BY
           mh.Sort
         , HSL.SoDanhBo
         , BD.ThuTuNhom, S.STT--, BD.ThuTuCotDiem;
END;
