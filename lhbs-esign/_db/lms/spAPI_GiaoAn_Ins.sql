
CREATE PROCEDURE [dbo].[spAPI_GiaoAn_Ins]
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
			INSERT INTO dbo.tblLMSChuongTrinhHoc(TenChuongTrinhHoc , NoiDungChuongTrinh, GiaoVienID, SoBuoiHoc,SoBuoiHocCoDiemDanh,NgayBatDau,NgayKetThuc, CreateUser, CreateTime)
            VALUES (@TenChuongTrinh, @NoiDungChuongTrinh, @GiaoVienID, @SoBuoiHoc, @SoBuoiHocCoDiemDanh,@NgayBatDau,@NgayKetThuc,  @SYS_USERID, GETDATE());
            COMMIT TRANSACTION;
        END
    
END;