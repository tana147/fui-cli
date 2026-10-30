CREATE PROC [dbo].[spAPI_KQHT_NhomDiem_TinhTrang_Udp]
    @NhomDiem_MonHocLopID INT,
    @MaNhomCotDiem NVARCHAR(100),
    @TinhTrang INT,
    @SYS_UserID VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblNhomDiem_MonHocLop
    SET TinhTrang = @TinhTrang,
        UpdateUser = @SYS_UserID,
        UpdateTime = GETDATE()
    WHERE NhomDiem_MonHocLopID = @NhomDiem_MonHocLopID;
END;