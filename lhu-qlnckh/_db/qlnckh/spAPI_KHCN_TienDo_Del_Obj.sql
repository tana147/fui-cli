CREATE PROC [dbo].[spAPI_KHCN_TienDo_Del_Obj]
@TienDoKHCNObj NVARCHAR(MAX), 
@SYS_UserID VARCHAR(9)
AS
BEGIN

	----update vào table TienDoCapKinhPhi
	UPDATE [dbo].[KHCN_TienDoCapKinhPhi]
	SET
		[Is_Xoa] = 1
	FROM OPENJSON(@TienDoKHCNObj)
	WITH (
		TienDoID INT
	) AS json
	WHERE [dbo].[KHCN_TienDoCapKinhPhi].TienDoID = json.TienDoID
END