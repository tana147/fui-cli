-- [dbo].[spAPI_TongHopDuLieuCuocThi_Get] 2025, '2445'
CREATE PROC [dbo].[spAPI_TongHopDuLieuCuocThi_Del]
   @TongHopDuLieuCuocThiID INT,
   @SYS_USERID VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblTong_Hop_Du_Lieu_Cuoc_Thi
	SET
		Enable = 0,
		UpdateUser = @SYS_USERID,
		UpdateTime = GETDATE()
	WHERE TongHopDuLieuCuocThiID = @TongHopDuLieuCuocThiID
END;