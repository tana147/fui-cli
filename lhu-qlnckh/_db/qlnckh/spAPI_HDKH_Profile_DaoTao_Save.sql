CREATE  PROCEDURE [dbo].[spAPI_HDKH_Profile_DaoTao_Save]
    @DaoTaoID BIGINT = 0,
    @HocVi NVARCHAR(100),
    @ChuyenNganh NVARCHAR(255),
    @NoiDaoTao NVARCHAR(255),
    @NamTotNghiep INT,
	@NhanVienID VARCHAR(9),
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE dbo.tblHDKH_Profile_DaoTao AS T
    USING (SELECT @DaoTaoID AS DaoTaoID) AS S
    ON (T.DaoTaoID = S.DaoTaoID AND S.DaoTaoID > 0)
    WHEN MATCHED THEN
        UPDATE SET
            HocVi = @HocVi,
            ChuyenNganh = @ChuyenNganh,
            NoiDaoTao = @NoiDaoTao,
            NamTotNghiep = @NamTotNghiep,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (NhanVienID, HocVi, ChuyenNganh, NoiDaoTao, NamTotNghiep, CreateUser)
        VALUES (@NhanVienID, @HocVi, @ChuyenNganh, @NoiDaoTao, @NamTotNghiep, @sys_UserID);
        
    SELECT Message = N'Lưu thông tin đào tạo thành công.';
END
