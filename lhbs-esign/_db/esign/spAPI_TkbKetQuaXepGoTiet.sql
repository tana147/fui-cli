CREATE PROCEDURE spAPI_TkbKetQuaXepGoTiet
    @ID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Go 1 tiet dang xep ra khoi lich (khac SuaTiet/ChuyenTiet la doi noi dung/vi tri — day la XOA
    -- HAN, tra lai o TRONG cho lop) — can thiet cho quy trinh "domino": muon xep A vao cho cua B thi
    -- phai go B ra truoc (2026-08-30, theo yeu cau nguoi dung). Sau khi go, ghi lai vao
    -- tblTKB_ChayAutoKhongXepDuoc de khong mat dau vet — nguoi dung con biet can xep lai gi.

    DECLARE @RunID INT, @MaLop VARCHAR(10), @MaMon VARCHAR(10), @MaGV VARCHAR(10);
    SELECT @RunID = RunID, @MaLop = MaLop, @MaMon = MaMon, @MaGV = MaGV
    FROM tblTKB_KetQuaXep WHERE ID = @ID;

    IF @RunID IS NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Không tìm thấy tiết học này' AS Message;
        RETURN;
    END

    DELETE FROM tblTKB_KetQuaXep WHERE ID = @ID;

    INSERT INTO tblTKB_ChayAutoKhongXepDuoc (RunID, MaLop, MaMon, MaGV, SoTiet)
    VALUES (@RunID, @MaLop, @MaMon, @MaGV, 1);

    SELECT CAST(1 AS BIT) AS Success, N'Đã gỡ tiết, khung giờ này giờ trống cho lớp ' + @MaLop AS Message;
END
