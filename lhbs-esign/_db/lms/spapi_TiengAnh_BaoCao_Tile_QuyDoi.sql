CREATE PROC spapi_TiengAnh_BaoCao_Tile_QuyDoi --'','HK2'
@ObjLopNhomID VARCHAR(200),
@Semester VARCHAR(5)
AS
BEGIN

	
	SELECT 
    kqht.LopID,
    BD.MaCotDiem,
    COUNT(*) AS SoLuong,
    (COUNT(*) * 100.0 / (SELECT COUNT(*) 
                         FROM tblKetQuaHocTap 
                         WHERE LopID = kqht.LopID 
                           AND Enable = 1)) AS TyLe
FROM 
    tblKetQuaHocTap kqht
INNER JOIN 
    tblMonHocLop mhl ON kqht.MonHocLopID = mhl.MonHocLopID 
INNER JOIN 
    TemplateBangDiemChiTiet BD ON BD.CotDiemID = kqht.CotDiemID
WHERE 
    kqht.Enable = 1 
    AND BD.Enable = 1
    AND kqht.LopID IN ('N241101', 'N241102')
    AND BD.Semester = 'HK2'
    AND BD.MaCotDiem IN (
        'S2_Final_TA2_Avg_Conv',
        'S2_Final_TA2_Listening_Conv',
        'S2_Final_TA2_Reading_Conv',
        'S2_Final_TA2_Speaking_Conv',
        'S2_Final_TA2_Writing_Conv'
    )
GROUP BY 
    kqht.LopID, 
    BD.MaCotDiem
ORDER BY 
    kqht.LopID, 
    BD.MaCotDiem

	
END
