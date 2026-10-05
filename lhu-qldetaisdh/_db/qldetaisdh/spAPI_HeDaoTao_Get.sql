CREATE PROC [dbo].[spAPI_HeDaoTao_Get]
AS
BEGIN
	-- Cao Học 
	SELECT 'C' [KEY], N'Thạc sĩ' AS [VALUE], N'Về việc công nhận tên đề tài và giảng viên hướng dẫn luận văn thạc sĩ' [SUBJECT]
	UNION
	-- NCS
	SELECT 'N' [KEY], N'Tiến sĩ' AS [VALUE], N'Về việc giao đề tài luận án và người hướng dẫn khoa học' [SUBJECT]
END