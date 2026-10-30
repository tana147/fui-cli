CREATE   PROCEDURE dbo.spAPI_SoGVCNKeHoachTuanClear
	@SoGVCNID varchar(10),
	@Thang varchar(2),
	@sys_UserID varchar(10),
	@sys_SystemRight varchar(10)
AS
BEGIN
	SET NOCOUNT ON;
	-- Client cũ từng gọi Clear trước khi lưu từng tuần. Nếu request sau lỗi,
	-- toàn bộ dữ liệu lớp sẽ bị ẩn. Giữ endpoint để client cũ nhận lỗi rõ ràng
	-- và phải tải lại bản mới; tuyệt đối không đổi cờ Enable ở đây.
	THROW 50001, N'Phiên bản Sổ GVCN đã cũ. Vui lòng tải lại trang trước khi lưu kế hoạch tuần.', 1;
END;
