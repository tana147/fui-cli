CREATE PROCEDURE [dbo].[spAPI_CGCN_ThanhVien_Save]
    @CGCNID INT,
    @MembersJSON NVARCHAR(MAX),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.ChuyenGiaoCongNghe WHERE CGCNID = @CGCNID AND Is_Xoa = 0)
    BEGIN
        RAISERROR(N'Hồ sơ chuyển giao công nghệ không tồn tại hoặc đã bị xóa', 16, 1);
        RETURN;
    END

    -- Đồng bộ danh sách thành viên: Đánh dấu Is_Xoa = 1 cho các dòng cũ
    UPDATE dbo.ChuyenGiaoCongNghe_ThanhVien
    SET Is_Xoa = 1, UpdateTime = GETDATE(), UpdateUser = @sys_UserID
    WHERE CGCNID = @CGCNID AND Is_Xoa = 0;

    IF @MembersJSON IS NOT NULL AND LEN(@MembersJSON) > 2
    BEGIN
        INSERT INTO dbo.ChuyenGiaoCongNghe_ThanhVien
        (
            CGCNID,
            VaiTro,
            TenVaiTro,
            Is_NhanVien,
            Is_SinhVien,
            MaDinhDanh,
            HoTen,
            Email,
            TenPhongBan,
            TyLeDongGop,
            Is_Xoa,
            CreateTime,
            CreateUser
        )
        SELECT 
            @CGCNID,
            ISNULL(j.VaiTro, 2),
            ISNULL(j.TenVaiTro, CASE j.VaiTro WHEN 1 THEN N'Chủ nhiệm' WHEN 3 THEN N'Thư ký' ELSE N'Thành viên' END),
            ISNULL(j.Is_NhanVien, 1),
            ISNULL(j.Is_SinhVien, 0),
            NULLIF(LTRIM(RTRIM(j.MaDinhDanh)), ''),
            LTRIM(RTRIM(j.HoTen)),
            NULLIF(LTRIM(RTRIM(j.Email)), ''),
            NULLIF(LTRIM(RTRIM(j.TenPhongBan)), ''),
            j.TyLeDongGop,
            0,
            GETDATE(),
            @sys_UserID
        FROM OPENJSON(@MembersJSON) WITH (
            VaiTro TINYINT,
            TenVaiTro NVARCHAR(50),
            Is_NhanVien BIT,
            Is_SinhVien BIT,
            MaDinhDanh VARCHAR(20),
            HoTen NVARCHAR(200),
            Email VARCHAR(100),
            TenPhongBan NVARCHAR(250),
            TyLeDongGop NUMERIC(5,2)
        ) j
        WHERE j.HoTen IS NOT NULL AND LTRIM(RTRIM(j.HoTen)) <> '';
    END

    -- Đồng bộ chuỗi text ChuNhiemDeTai và ThanhVienDeTai trên bảng ChuyenGiaoCongNghe để backward compatible
    DECLARE @ChuNhiemText NVARCHAR(500) = (
        SELECT STRING_AGG(HoTen, ', ')
        FROM dbo.ChuyenGiaoCongNghe_ThanhVien
        WHERE CGCNID = @CGCNID AND Is_Xoa = 0 AND VaiTro = 1
    );

    DECLARE @ThanhVienText NVARCHAR(500) = (
        SELECT STRING_AGG(HoTen, ', ')
        FROM dbo.ChuyenGiaoCongNghe_ThanhVien
        WHERE CGCNID = @CGCNID AND Is_Xoa = 0 AND VaiTro <> 1
    );

    UPDATE dbo.ChuyenGiaoCongNghe
    SET ChuNhiemDeTai = ISNULL(@ChuNhiemText, ChuNhiemDeTai),
        ThanhVienDeTai = ISNULL(@ThanhVienText, ThanhVienDeTai),
        NhanVienCapNhat = @sys_UserID,
        ThoiGianCapNhat = GETDATE()
    WHERE CGCNID = @CGCNID;

    SELECT Message = N'Lưu danh sách thành viên CGCN thành công', Status = 1;
END;
