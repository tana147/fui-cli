
--[dbo].[spAPI_XetKetQuaRenLuyen_Get]
--	@HocKi		 = 2,
--	@LopID		 = '2549',
--	@NienKhoa	 = 2025 

CREATE PROC [dbo].[spAPI_XetKetQuaRenLuyen_Get]
	@HocKi INT,
	@LopID INT,
	@NienKhoa INT
as
begin
	select 
		HocSinhID	,
		HocKi		,
		LopID		,
		TenLop		,
		KQRL_Truoc	,
		KQRL_Sau	,
		NienKhoa	,
		 IsChotDiem,
		CreateUser	,
		CreateTime	,
		UpdateUser	,
		UpdateTime	
	from dbo.tblXetKetQuaRenLuyen
	where HocKi = @HocKi
	and LopID = @LopID
	AND NienKhoa = @NienKhoa
end
