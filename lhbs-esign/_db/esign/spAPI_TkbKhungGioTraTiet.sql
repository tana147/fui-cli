CREATE PROCEDURE spAPI_TkbKhungGioTraTiet
    @GioBatDau VARCHAR(5),
    @GioKetThuc VARCHAR(5),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Cong cu tra cuu: nhap khung gio thuc (phut) -> tra ra dung Tiet nao chong lan, theo TUNG CAP
    -- rieng (vi cung 1 khung phut ung voi Tiet khac nhau o Tieu hoc va THCS-THPT). Dung khi nhap
    -- danh muc Khoa phong dung chung (R1) de tranh doan bang mat.
    DECLARE @Tu TIME = CAST(@GioBatDau AS TIME);
    DECLARE @Den TIME = CAST(@GioKetThuc AS TIME);

    SELECT
        k.Cap, k.Buoi, k.Tiet, k.GioBatDau, k.GioKetThuc,
        DATEDIFF(MINUTE,
            CASE WHEN k.GioBatDau > @Tu THEN k.GioBatDau ELSE @Tu END,
            CASE WHEN k.GioKetThuc < @Den THEN k.GioKetThuc ELSE @Den END
        ) AS SoPhutChongLan,
        DATEDIFF(MINUTE, k.GioBatDau, k.GioKetThuc) AS TongPhutTietDo
    FROM tblTKB_KhungGio k
    WHERE k.Enable = 1
      AND k.GioBatDau < @Den AND k.GioKetThuc > @Tu
    ORDER BY k.Cap, k.Buoi, k.Tiet;
END