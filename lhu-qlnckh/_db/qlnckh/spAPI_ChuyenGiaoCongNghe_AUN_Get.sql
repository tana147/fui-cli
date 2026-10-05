CREATE PROC [dbo].[spAPI_ChuyenGiaoCongNghe_AUN_Get]   
AS
BEGIN
	---- Thông tin chuyển giao công nghệ

	SELECT 
    cn.[CGCNID],
    cn.[SoThuTu],
    cn.[TenDuAn],
    cn.[ChuNhiemDeTai],
    cn.[ThanhVienDeTai],
    cn.[DonViChuNhiem],
    cn.[DonViTiepNhan],
    cn.[GiaTriHopDong],
    cn.[NamThucHien],
    cn.[SoHopDong],
    cn.[FileID_List],
    (
        SELECT 
            fd.FileID AS [FILE_ID], 
            fd.[FileName] AS [FILE_NAME], 
            fd.Size AS [FILE_SIZE]
        FROM dbo.FileData fd
        WHERE fd.FileID IN (SELECT Data FROM [dbo].[FN_STRING_SPLIT](cn.[FileID_List], ','))
        FOR JSON PATH
    ) AS [json_data:FileData]
	--FROM dbo.ChuyenGiaoCongNghe_AUN cn
	FROM dbo.ChuyenGiaoCongNghe cn
	WHERE cn.Is_Xoa = 0
	ORDER BY cn.[SoThuTu] ASC

	
END

