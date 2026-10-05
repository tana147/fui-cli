
CREATE PROC [dbo].[spAPI_AnPham_Upd_LocalStorage]--  N'[{"AnPhamID":4773},{"AnPhamID":4774}]', 1, 'GV0000611', 9
@AnPhamObjArr NVARCHAR(MAX),
@Is_Store BIT ,
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
		DECLARE @MsgError NVARCHAR(500)
		IF (@sys_SystemRight NOT IN (1,2,9))
		BEGIN 
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
				-- Tạo bảng tạm để lưu danh sách AnPhamID từ JSON
		DECLARE @AnPhamTable TABLE (AnPhamID INT);

		-- Trích xuất danh sách AnPhamID từ JSON vào bảng tạm
		INSERT INTO @AnPhamTable (AnPhamID)
		SELECT AnPhamID
		FROM OPENJSON(@AnPhamObjArr)
		WITH (AnPhamID INT);

		-- Cập nhật Is_LocalStore cho tất cả AnPhamID trong danh sách
		UPDATE AnPham
		SET Is_LocalStore = @Is_Store
    WHERE AnPhamID IN (SELECT AnPhamID FROM @AnPhamTable);
END
