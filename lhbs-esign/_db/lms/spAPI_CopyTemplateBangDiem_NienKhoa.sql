CREATE PROCEDURE dbo.spAPI_CopyTemplateBangDiem_NienKhoa
    @NienKhoaNguon   INT,        -- NienKhoa nguồn, ví dụ 2025
    @NienKhoaDich    INT,        -- NienKhoa đích,  ví dụ 2026
    @CreateUser      NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Bảng mapping OldID -> NewID
    DECLARE @Mapping TABLE (OldID INT, NewID INT);

    BEGIN TRY
        BEGIN TRAN;

        -- =============================================
        -- Bước 1: INSERT TemplateBangDiem NienKhoa mới
        -- =============================================
        MERGE dbo.TemplateBangDiem AS target
        USING (
            SELECT 
                TemplateBangDiemID AS OldID,
                CASE 
                    WHEN TemplateBangDiemName LIKE '%[[]NH-' + CAST(@NienKhoaNguon AS NVARCHAR) + '%'
                    THEN REPLACE(
                            TemplateBangDiemName, 
                            '[NH-' + CAST(@NienKhoaNguon AS NVARCHAR), 
                            '[NH-' + CAST(@NienKhoaDich  AS NVARCHAR)
                         )
                    WHEN TemplateBangDiemName LIKE '%[[]' + CAST(@NienKhoaNguon AS NVARCHAR) + ']%'
                    THEN REPLACE(
                            TemplateBangDiemName, 
                            '[' + CAST(@NienKhoaNguon AS NVARCHAR) + ']', 
                            '[' + CAST(@NienKhoaDich  AS NVARCHAR) + ']'
                         )
                    ELSE TemplateBangDiemName
                END AS NewName,
                CapID,
                Enable
            FROM dbo.TemplateBangDiem
            WHERE Enable = 1 
              AND NienKhoa = @NienKhoaNguon
              AND TemplateBangDiemID IN (
                  SELECT DISTINCT TemplateBangDiemID
                  FROM dbo.tblMonHocLop
                  WHERE Enable = 1 AND NienKhoa = @NienKhoaNguon
              )
        ) AS src ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT (TemplateBangDiemName, CapID, NienKhoa, Enable, CreateUser, CreateTime, UpdateUser, UpdateTime)
            VALUES (src.NewName, src.CapID, @NienKhoaDich, src.Enable, @CreateUser, GETDATE(), NULL, NULL)
        OUTPUT src.OldID, inserted.TemplateBangDiemID
        INTO @Mapping (OldID, NewID);

        -- =============================================
        -- Bước 2: INSERT TemplateBangDiemChiTiet
        -- =============================================
        INSERT INTO dbo.TemplateBangDiemChiTiet (
             TemplateBangDiemID
            ,IDHeThong
            ,MaCotDiem
            ,TenCotDiem_VI
            ,TenCotDiem_EN
            ,TenHienThi_VI
            ,TenHienThi_EN
            ,MotaCotDiem_VI
            ,MotaCotDiem_EN
            ,LoaiCotDiem
            ,KieuDanhGiaID
            ,GiaTriCotDiem
            ,LamTronBaoNhieuSo
            ,HeSo
            ,DiemMin
            ,DiemMax
            ,Formula
            ,ThuTuCotDiem
            ,MaNhomCotDiem
            ,TenNhomCotDiem_VI
            ,TenNhomCotDiem_EN
            ,ThuTuNhom
            ,IsUserInput
            ,IsVisibleToParents
            ,IsSendToManager
            ,IsNegativeNumber
            ,Enable
            ,CssClass
            ,WidthCSS
            ,HexBackground
            ,Semester
            ,BaoCaoThang_DinhKy
            ,QuyenNhapDiem
            ,CreateUser
            ,CreateTime
            ,UpdateUser
            ,UpdateTime
        )
        SELECT 
             m.NewID
            ,ct.IDHeThong
            ,ct.MaCotDiem
            ,ct.TenCotDiem_VI
            ,ct.TenCotDiem_EN
            ,ct.TenHienThi_VI
            ,ct.TenHienThi_EN
            ,ct.MotaCotDiem_VI
            ,ct.MotaCotDiem_EN
            ,ct.LoaiCotDiem
            ,ct.KieuDanhGiaID
            ,ct.GiaTriCotDiem
            ,ct.LamTronBaoNhieuSo
            ,ct.HeSo
            ,ct.DiemMin
            ,ct.DiemMax
            ,ct.Formula
            ,ct.ThuTuCotDiem
            ,ct.MaNhomCotDiem
            ,ct.TenNhomCotDiem_VI
            ,ct.TenNhomCotDiem_EN
            ,ct.ThuTuNhom
            ,ct.IsUserInput
            ,ct.IsVisibleToParents
            ,ct.IsSendToManager
            ,ct.IsNegativeNumber
            ,ct.Enable
            ,ct.CssClass
            ,ct.WidthCSS
            ,ct.HexBackground
            ,ct.Semester
            ,ct.BaoCaoThang_DinhKy
            ,ct.QuyenNhapDiem
            ,@CreateUser
            ,GETDATE()
            ,NULL
            ,NULL
        FROM dbo.TemplateBangDiemChiTiet ct
        INNER JOIN @Mapping m ON ct.TemplateBangDiemID = m.OldID
        WHERE ct.Enable = 1;

        -- =============================================
        -- Bước 3: Kiểm tra khớp số lượng ChiTiet
        -- =============================================
        SELECT 
            t_nguon.TemplateBangDiemID     AS ID_Nguon,
            t_dich.TemplateBangDiemID      AS ID_Dich,
            t_nguon.CapID,
            t_nguon.TemplateBangDiemName   AS Ten_Nguon,
            t_dich.TemplateBangDiemName    AS Ten_Dich,
            cnt_nguon.SoLuong              AS SoChiTiet_Nguon,
            cnt_dich.SoLuong               AS SoChiTiet_Dich,
            CASE 
                WHEN cnt_nguon.SoLuong = cnt_dich.SoLuong THEN N'✓ Khớp'
                ELSE N'✗ Không khớp'
            END AS KetQua
        FROM @Mapping m
        INNER JOIN dbo.TemplateBangDiem t_nguon  ON m.OldID  = t_nguon.TemplateBangDiemID
        INNER JOIN dbo.TemplateBangDiem t_dich   ON m.NewID  = t_dich.TemplateBangDiemID
        INNER JOIN (
            SELECT TemplateBangDiemID, COUNT(*) AS SoLuong
            FROM dbo.TemplateBangDiemChiTiet
            WHERE Enable = 1
            GROUP BY TemplateBangDiemID
        ) cnt_nguon ON m.OldID = cnt_nguon.TemplateBangDiemID
        INNER JOIN (
            SELECT TemplateBangDiemID, COUNT(*) AS SoLuong
            FROM dbo.TemplateBangDiemChiTiet
            WHERE Enable = 1
            GROUP BY TemplateBangDiemID
        ) cnt_dich  ON m.NewID = cnt_dich.TemplateBangDiemID
        ORDER BY t_nguon.CapID, t_nguon.TemplateBangDiemName;

        COMMIT;

    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
