
CREATE PROCEDURE [dbo].[spAPI_GiaoAn_Upd]
	@ChuongTrinhHocID INT,
    @GiaoVienID NVARCHAR(10),
    @TenChuongTrinh NVARCHAR(254),
    @NoiDungChuongTrinh NVARCHAR(254),
    @SoBuoiHoc INT,
    @SoBuoiHocCoDiemDanh INT,
    @NgayBatDau datetime,
    @NgayKetThuc datetime,
    @SYS_USERID VARCHAR(9)
	AS
	BEGIN
	    -- Kiểm tra sự tồn tại của GiaoVienID trong bảng GiaoVien và thực hiện INSERT nếu có
	    IF EXISTS (SELECT 1 FROM dbo.tblGiaoVien tgv WHERE GiaoVienID = @GiaoVienID)
	        BEGIN
		        BEGIN TRANSACTION;
				UPDATE dbo.tblLMSChuongTrinhHoc
					SET 
					    TenChuongTrinhHoc = @TenChuongTrinh, 
					    NoiDungChuongTrinh = @NoiDungChuongTrinh, 
					    GiaoVienID = @GiaoVienID, 
					    SoBuoiHoc = @SoBuoiHoc, 
					    SoBuoiHocCoDiemDanh = @SoBuoiHocCoDiemDanh, 
					    NgayBatDau = @NgayBatDau, 
					    NgayKetThuc = @NgayKetThuc, 
					    UpdateUser = @SYS_USERID, 
					    UpdateTime = GETDATE()
					WHERE 
					    ChuongTrinhHocID = @ChuongTrinhHocID
	            COMMIT TRANSACTION;
	        END
	    
	END;