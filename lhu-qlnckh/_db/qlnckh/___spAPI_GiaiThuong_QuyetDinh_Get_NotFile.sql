CREATE PROC [dbo].[spAPI_GiaiThuong_QuyetDinh_Get_NotFile]
AS
BEGIN
	SELECT DISTINCT LGT.LoaiGiaiThuongID, GT.SoQuyetDinh, LGT.TenLoaiGiaiThuong, GT.NamDatGiai, COUNT(GT.SoQuyetDinh) AS SLDETAI
		 FROM GiaiThuong GT 
				INNER JOIN LoaiGiaiThuong LGT ON LGT.LoaiGiaiThuongID = GT.LoaiGiaiThuongID
				WHERE (GT.FileID_List IS NULL OR GT.FileID_List = '')
				AND GT.Is_Xoa = 0 
				GROUP BY LGT.LoaiGiaiThuongID, GT.SoQuyetDinh, LGT.TenLoaiGiaiThuong, GT.NamDatGiai
				ORDER BY LGT.LoaiGiaiThuongID, NamDatGiai ASC
				
END