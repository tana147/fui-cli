CREATE PROC [dbo].[spAPI_MonHoc_Get_ByCapID]
@CapID INT,
@SYS_USERID VARCHAR(9),
@Sys_GroupID INT
AS
BEGIN
	SELECT MonHocID
         , Sort
         , CapID
         , MonHocCode
         , MonHocName
         , MonHocGroup
         , TrangThai
         , MaMonDuLieuNganh
         , TenMonDuLieuNganh
         , TenMonHoc_HienThi
         , ToGiangDayDayID
         , SoTietHK1
         , SoTietHocKy2
         , SoTuanHK1
         , SoTuanHK2
         , Color
		 , Icon
         , Is_MonHoc_BoTro
         , List_MonHoc_NLPC_ID
	FROM dbo.tblMonHoc WHERE CapID = @CapID AND [Enable] = 1
END