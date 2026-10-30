
--sp_TinhTrungBinhDiemTheoMaNhomDiem
CREATE FUNCTION dbo.sp_TinhTrungBinhDiemTheoMaCotDiem
(
    @MaLop INT,
-- Tham số để lọc theo học sinh
    @MaMonHoc INT,
    @MaCotDiem NVARCHAR(50)
)
RETURNS TABLE
AS
RETURN
(
SELECT
	ths.Ho + ' ' + ths.Ten as HoTen,
	kq.HocSinhID,
	--cong thuc tinh Diem trung binh
	AVG(
            CASE 
                WHEN ISNUMERIC(kq.KetQuaDanhGia_VI) = 1 and tbdct.isNegativeNumber = 0 THEN 
                    CASE 
                        WHEN CAST(kq.KetQuaDanhGia_VI AS Float) > tbdct.DiemMax THEN tbdct.DiemMax
                        WHEN CAST(kq.KetQuaDanhGia_VI AS Float) < tbdct.DiemMin THEN tbdct.DiemMin
                        ELSE CAST(kq.KetQuaDanhGia_VI AS Float)
                    END
                ELSE 0 
            END
        ) AS DiemTrungBinh,
	--cong thuc tinh Diem tru
	SUM(
CASE 
                WHEN ISNUMERIC(kq.KetQuaDanhGia_VI) = 1 and tbdct.isNegativeNumber = 1 THEN  
                    CASE 
                        WHEN CAST(kq.KetQuaDanhGia_VI AS Float) > tbdct.DiemMax THEN tbdct.DiemMax
                        WHEN CAST(kq.KetQuaDanhGia_VI AS Float) < tbdct.DiemMin THEN tbdct.DiemMin
                        ELSE CAST(kq.KetQuaDanhGia_VI AS Float)
                    END
                ELSE 0 
            END
        ) AS DiemTru,
	SUM(
            CASE 
                WHEN ISNUMERIC(kq.KetQuaDanhGia_VI) = 1 and tbdct.isNegativeNumber = 0 THEN 
                    CASE 
                        WHEN CAST(kq.KetQuaDanhGia_VI AS Float) > tbdct.DiemMax THEN tbdct.DiemMax
                        WHEN CAST(kq.KetQuaDanhGia_VI AS Float) < tbdct.DiemMin THEN tbdct.DiemMin
                        ELSE CAST(kq.KetQuaDanhGia_VI AS Float)
                    END
                ELSE 0 
            END
           )     
        AS TongDiemChuaTru,
	--cong thuc tinh Diem tong = tong diem - diem tru
	SUM(
            CASE 
                WHEN ISNUMERIC(kq.KetQuaDanhGia_VI) = 1 and tbdct.isNegativeNumber = 0 THEN 
                    CASE 
                        WHEN CAST(kq.KetQuaDanhGia_VI AS Float) > tbdct.DiemMax THEN tbdct.DiemMax
                        WHEN CAST(kq.KetQuaDanhGia_VI AS Float) < tbdct.DiemMin THEN tbdct.DiemMin
                        ELSE CAST(kq.KetQuaDanhGia_VI AS Float)
                    END
                ELSE 0 
            END
           )  
        -
        SUM(
			CASE 
                WHEN ISNUMERIC(kq.KetQuaDanhGia_VI) = 1 and tbdct.isNegativeNumber = 1 THEN  
                    CASE 
                        WHEN CAST(kq.KetQuaDanhGia_VI AS Float) > tbdct.DiemMax THEN tbdct.DiemMax
                        WHEN CAST(kq.KetQuaDanhGia_VI AS Float) < tbdct.DiemMin THEN tbdct.DiemMin
                        ELSE CAST(kq.KetQuaDanhGia_VI AS Float)
                    END
                ELSE 0 
            END
        )      
        AS TongDiemDaTru
	--SELECT *
FROM
	  [LMS-LHBS].dbo.tblKetQuaHocTap kq
inner join [LMS-LHBS].dbo.tblMonHocLop tmhl on
	tmhl.MonHocLopID = kq.MonHocLopID
inner join [LMS-LHBS].dbo.tblMonHoc tmh on
	tmhl.MonHocID = tmh.MonHocID
inner join [LMS-LHBS].dbo.TemplateBangDiemChiTiet tbdct on
	tbdct.CotDiemID = kq.CotDiemID
inner join [LMS-LHBS].dbo.tblHocSinh ths on
	ths.HocSinhID = kq.HocSinhID
WHERE
	kq.LopID = @MaLop
	and tmh.MonHocID = @MaMonHoc
	And tbdct.MaCotDiem = @MaCotDiem
	and ths.TinhTrang = 0
	and tbdct.LoaiCotDiem = N'Nhập'
Group by
	ths.Ten,
	ths.Ho,
	kq.HocSinhID,
	kq.LopID
);
