CREATE PROC [dbo].[spAPI_AnPhamFile_Get_ByAnPhamID]
@AnPhamID INT
AS
BEGIN

	
	SELECT 
		  C.[AnPhamFileID]
		, C.[AnPhamID]
		, C.[LoaiFile]
		, C.[FileIDList]
		,  JSON_QUERY('[' + 
        STUFF(
            (
                SELECT
                    ', {"FileIDMinhChung":"' + FileID + '","FileNameMinhChung":"' + FileName + '","FileUrlMinhChung":"/FileData/'+ FileID +'"}'
                FROM FileData AS F
                WHERE CHARINDEX(FileID, C.FileIDList) > 0
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 2, ''
        ) + ']') AS FileList
		, C.[MoTa]
		, C.[TrangThai]
		, C.[NhanVienCapNhat]
		, C.[ThoiGianCapNhat]
		, C.[Is_Xoa]
	FROM AnPham_File C WHERE C.AnPhamID = @AnPhamID and C.Is_Xoa =0


END