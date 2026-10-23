CREATE PROC [dbo].[spAPI_Decision_Get_ByStatus] 
@Decision_Status INT,
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	SELECT
			  D.[Decision_ID]
			, CASE WHEN LEN(D.[Decision_SoQD]) > 20 OR ISNULL(D.[Decision_SoQD],'') = '' THEN N'...../QĐ-ĐHLH' ELSE  D.[Decision_SoQD] END  AS Decision_SoQD
			, CASE WHEN ISNULL(D.[Decision_NgayQD],'') = '' THEN ' .../' ELSE D.[Decision_NgayQD]  + '/' END  
			+ CASE WHEN ISNULL(D.[Decision_ThangQD],'')= '' THEN ' .../' ELSE D.[Decision_ThangQD] + '/' END 
			+ CASE WHEN ISNULL(D.[Decision_NamQD],'')= '' THEN ' 20... ' ELSE D.[Decision_ThangQD] END AS Decision_NgayQD
			, D.[Decision_TieuDe]
			, D.[Decision_Nganh]
			, D.[Decision_NganhID]
			, D.[Decision_NienKhoa]
			, D.[Decision_Dot]
			, D.[Decision_MaSo]
			, D.[Decision_Type]
			, D.[Decision_Description]
			, D.[DecisionFile_ID]
			, D.[DecisionFile_Url]
			, D.[Decision_TemplateID]
			, D.[Decision_Status]
		
	FROM [dbo].[Decision] D 
	WHERE (@Decision_Status = 0 OR D.Decision_Status = @Decision_Status) 
		AND D.Decision_Status <> 10
		AND D.Decision_Type <> N'Xét tốt nghiệp'
		AND D.Decision_Type <> N'Đổi/điều chỉnh'
END