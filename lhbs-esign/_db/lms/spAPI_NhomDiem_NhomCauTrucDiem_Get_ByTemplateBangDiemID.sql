CREATE PROC [dbo].[spAPI_NhomDiem_NhomCauTrucDiem_Get_ByTemplateBangDiemID] -- 4,'',0
    @TemplateBangDiemID INT,
    @MonHocLopID INT,
    @SYS_USERID VARCHAR(9),
    @Sys_GroupID INT
AS
BEGIN
    --SELECT DISTINCT [MaNhomCotDiem]
    --, [TenNhomCotDiem_VI]
    --, [TenNhomCotDiem_EN]
    --, [ThuTuNhom]
    ----, [CssClass]
    --, [Semester]

    --FROM [dbo].[TemplateBangDiemChiTiet] WHERE [TemplateBangDiemID] = @TemplateBangDiemID
    --AND [Enable] = 1
    --ORDER BY Semester, ThuTuNhom

    --1: Gửi tổ trưởng, 2: Duyệt điểm, 3: Từ chối điểm, 4: Công bố phụ huynh
    SELECT nd_tbd.NhomDiem_MonHocLopID,
           t_bd.TemplateBangDiemID,
           nd_tbd.MaNhomCotDiem,
           nd_tbd.TenNhomCotDiem_VI,
           nd_tbd.TenNhomCotDiem_EN,
           nd_tbd.ThuTuNhom,
           nd_tbd.Semester,
           nd_tbd.TinhTrang,
           CASE
               WHEN nd_tbd.TinhTrang = 0 THEN
                   N'Chưa lưu điểm'
               WHEN nd_tbd.TinhTrang = 1 THEN
                   N'Lưu tạm'
               WHEN nd_tbd.TinhTrang = 2 THEN
                   N'Gửi tổ trưởng'
               WHEN nd_tbd.TinhTrang = 3 THEN
                   N'Từ chối điểm'
               WHEN nd_tbd.TinhTrang = 4 THEN
                   N'Duyệt điểm'
               ELSE
                   'UNKNOW'
           END AS TenTinhTrang,
           CASE
               WHEN nd_tbd.TinhTrang = 0 THEN
                   N'black'
               WHEN nd_tbd.TinhTrang = 1 THEN
                   N'primary'
               WHEN nd_tbd.TinhTrang = 2 THEN
                   N'warning'
               WHEN nd_tbd.TinhTrang = 3 THEN
                   N'error'
               WHEN nd_tbd.TinhTrang = 4 THEN
                   N'success'
               ELSE
                   'UNKNOW'
           END AS MauTinhTrang,
           CASE
               WHEN nd_tbd.TinhTrang = 0 THEN
                   N'mdi-flask-empty-outline'
               WHEN nd_tbd.TinhTrang = 1 THEN
                   N'mdi-content-save-outline'
               WHEN nd_tbd.TinhTrang = 2 THEN
                   N'mdi-content-save-move-outline'
               WHEN nd_tbd.TinhTrang = 3 THEN
                   N'mdi-content-save-off-outline'
               WHEN nd_tbd.TinhTrang = 4 THEN
                   N'mdi-content-save-check-outline'
               ELSE
                   'UNKNOW'
           END AS IconTinhTrang
    FROM dbo.tblNhomDiem_MonHocLop nd_tbd
        INNER JOIN dbo.tblMonHocLop mhl
            ON mhl.MonHocLopID = nd_tbd.MonHocLopID
        INNER JOIN dbo.TemplateBangDiem t_bd
            ON t_bd.TemplateBangDiemID = mhl.TemplateBangDiemID
               AND t_bd.Enable = 1
    WHERE nd_tbd.Enable = 1
          AND nd_tbd.MonHocLopID = @MonHocLopID
    ORDER BY nd_tbd.Semester,
             nd_tbd.ThuTuNhom;

    -- Tạo bảng tạm
    DECLARE @TinhTrangTable TABLE
    (
        TinhTrang INT,
        TenTinhTrang NVARCHAR(50),
        MauTinhTrang NVARCHAR(20),
        IconTinhTrang NVARCHAR(50)
    );

    -- Thêm các dòng vào bảng tạm
    INSERT INTO @TinhTrangTable
    (
        TinhTrang,
        TenTinhTrang,
        MauTinhTrang,
        IconTinhTrang
    )
    VALUES
    (0, N'Chưa lưu điểm', N'black', N'mdi-flask-empty-outline'),
    (1, N'Lưu tạm', N'primary', N'mdi-content-save-outline'),
    (2, N'Gửi tổ trưởng', N'warning', N'mdi-content-save-move-outline'),
    (3, N'Từ chối điểm', N'error', N'mdi-content-save-off-outline'),
    (4, N'Duyệt điểm', N'success', N'mdi-content-save-check-outline');

    -- SELECT từ bảng tạm
    SELECT TinhTrang,
           TenTinhTrang,
           MauTinhTrang,
           IconTinhTrang
    FROM @TinhTrangTable;

END;