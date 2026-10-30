
CREATE PROCEDURE [dbo].[spAPI_DashboardDiemTrungBinh_Get]-- 2024,6,46
    @NienKhoa INT,
    @KhoiID INT,
    @MonHocID INT
AS
BEGIN
    SELECT 
        tl.LopID,
        tl.TenLop,
        tmh.MonHocName,
        tmh.MonHocCode,

		AVG(CASE WHEN tbdct.MaCotDiem = 'S1_Mid_Total_Point' THEN 
            CASE WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1 
                 THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
                 ELSE NULL END ELSE NULL END) AS DiemGiua_HK1,

        AVG(CASE WHEN tbdct.MaCotDiem = 'S1_Final_Total_Point' THEN 
            CASE WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1 
                 THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
                 ELSE NULL END ELSE NULL END) AS DiemCuoi_HK1,

		   AVG(CASE WHEN tbdct.MaCotDiem = 'DiemTB_HK1' THEN 
            CASE WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1 
                 THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
                 ELSE NULL END ELSE NULL END) AS DiemTB_HK1
        
        --AVG(CASE WHEN tbdct.MaCotDiem = 'DiemTB_HK2' THEN 
        --    CASE WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1 
        --         THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
        --         ELSE NULL END ELSE NULL END) AS DiemTB_HK2,
        
        --AVG(CASE WHEN tbdct.MaCotDiem = 'DiemTB_CaNam' THEN 
        --    CASE WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1 
        --         THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
        --         ELSE NULL END ELSE NULL END) AS DiemTB_CaNam
    FROM 
        dbo.tblKetQuaHocTap tkqht 
    INNER JOIN 
        dbo.tblLop tl ON tl.LopID = tkqht.LopID AND tl.NienKhoa = @NienKhoa
    INNER JOIN 
        dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID 
    INNER JOIN 
        dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID 
    INNER JOIN 
        dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID 
    WHERE 
        tkqht.NienKhoa = @NienKhoa
        AND tl.KhoiID = @KhoiID
    	AND tmh.MonHocID = @MonHocID 
        AND tbdct.MaCotDiem IN ('S1_Mid_Total_Point', 'S1_Final_Total_Point', 'DiemTB_HK1')
		 AND  tkqht.Enable                      = 1
    GROUP BY 
        tl.LopID, 
        tl.TenLop,
        tmh.MonHocName,
        tmh.MonHocCode
END