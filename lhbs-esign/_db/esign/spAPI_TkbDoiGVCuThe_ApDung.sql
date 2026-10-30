CREATE PROCEDURE spAPI_TkbDoiGVCuThe_ApDung
    @Tuan       INT,
    @MaGVCu     VARCHAR(15),
    @MaGVMoi    VARCHAR(15),
    @SlotsJson  NVARCHAR(MAX),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-04: doi tu @RunID sang @Tuan (xem XacDinhAnhHuong cung ten). Voi moi slot cua GV cu
    -- (trong dung RunID cua khoi do):
    --   1) GV moi RANH (trong CHINH RunID do) -> gan THANG MaGV=GVMoi vao dong hien co, khoa lai.
    --   2) GV moi BAN  -> xu ly nhu GV bao ban: xoa dong cu, cam GVCu tai slot do (RunID tuong ung).
    -- SP nay KHONG tu goi solver — tra ve danh sach RunID THAT SU can xep lai (chi cac RunID co slot
    -- roi vao nhanh "GV moi ban") de FE xep hang doi, tu goi spAPI_TkbChayAutoPhanConLai tuan tu.

    ;WITH RunHienHanh AS (
        SELECT Khoi, MAX(RunID) AS RunID
        FROM tblTKB_ChayAutoLog
        WHERE TuanHienTai = @Tuan AND KhaThi = 1 AND Enable = 1
        GROUP BY Khoi
    ),
    slots AS (
        SELECT Thu, Buoi, Tiet FROM OPENJSON(@SlotsJson)
        WITH (Thu INT '$.Thu', Buoi VARCHAR(10) '$.Buoi', Tiet INT '$.Tiet')
    ),
    ranh AS (
        SELECT k.ID FROM RunHienHanh r
        JOIN tblTKB_KetQuaXep k ON k.RunID = r.RunID AND k.MaGV = @MaGVCu
        JOIN slots s ON s.Thu = k.Thu AND s.Buoi = k.Buoi AND s.Tiet = k.Tiet
        WHERE NOT EXISTS (
            SELECT 1 FROM tblTKB_KetQuaXep c
            WHERE c.RunID = k.RunID AND c.MaGV = @MaGVMoi AND c.Thu = k.Thu AND c.Buoi = k.Buoi AND c.Tiet = k.Tiet
          )
    )
    UPDATE tblTKB_KetQuaXep SET MaGV = @MaGVMoi WHERE ID IN (SELECT ID FROM ranh);

    ;WITH RunHienHanh AS (
        SELECT Khoi, MAX(RunID) AS RunID
        FROM tblTKB_ChayAutoLog
        WHERE TuanHienTai = @Tuan AND KhaThi = 1 AND Enable = 1
        GROUP BY Khoi
    ),
    slots AS (
        SELECT Thu, Buoi, Tiet FROM OPENJSON(@SlotsJson)
        WITH (Thu INT '$.Thu', Buoi VARCHAR(10) '$.Buoi', Tiet INT '$.Tiet')
    )
    INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID, KhoaUser, KhoaTime)
    SELECT k.ID, @sys_UserID, GETDATE()
    FROM RunHienHanh r
    JOIN tblTKB_KetQuaXep k ON k.RunID = r.RunID AND k.MaGV = @MaGVMoi
    JOIN slots s ON s.Thu = k.Thu AND s.Buoi = k.Buoi AND s.Tiet = k.Tiet
    WHERE NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep_Khoa kk WHERE kk.KetQuaXepID = k.ID);

    -- Cac slot GV moi dang BAN — xu ly y het GV bao ban: xoa dong cu cua GVCu, cam GVCu tai do (RunID
    -- tuong ung), gom RunID lien quan de tra ve cho FE xep lai.
    DECLARE @AnhHuong TABLE (RunID INT, KetQuaXepID INT, Thu INT, Buoi VARCHAR(10), Tiet INT);
    ;WITH RunHienHanh AS (
        SELECT Khoi, MAX(RunID) AS RunID
        FROM tblTKB_ChayAutoLog
        WHERE TuanHienTai = @Tuan AND KhaThi = 1 AND Enable = 1
        GROUP BY Khoi
    ),
    slots AS (
        SELECT Thu, Buoi, Tiet FROM OPENJSON(@SlotsJson)
        WITH (Thu INT '$.Thu', Buoi VARCHAR(10) '$.Buoi', Tiet INT '$.Tiet')
    )
    INSERT INTO @AnhHuong (RunID, KetQuaXepID, Thu, Buoi, Tiet)
    SELECT k.RunID, k.ID, k.Thu, k.Buoi, k.Tiet
    FROM RunHienHanh r
    JOIN tblTKB_KetQuaXep k ON k.RunID = r.RunID AND k.MaGV = @MaGVCu
    JOIN slots s ON s.Thu = k.Thu AND s.Buoi = k.Buoi AND s.Tiet = k.Tiet
    WHERE EXISTS (
        SELECT 1 FROM tblTKB_KetQuaXep c
        WHERE c.RunID = k.RunID AND c.MaGV = @MaGVMoi AND c.Thu = k.Thu AND c.Buoi = k.Buoi AND c.Tiet = k.Tiet
      );

    INSERT INTO tblTKB_GVCamTuyetDoi (RunID, MaGV, Thu, Buoi, Tiet, LyDo, CreateUser, CreateTime)
    SELECT DISTINCT a.RunID, @MaGVCu, a.Thu, a.Buoi, a.Tiet, N'Đổi GV (chatbot)', @sys_UserID, GETDATE()
    FROM @AnhHuong a
    WHERE NOT EXISTS (
        SELECT 1 FROM tblTKB_GVCamTuyetDoi g
        WHERE g.RunID = a.RunID AND g.MaGV = @MaGVCu AND g.Thu = a.Thu AND g.Buoi = a.Buoi AND g.Tiet = a.Tiet
      );

    DELETE FROM tblTKB_KetQuaXep WHERE ID IN (SELECT KetQuaXepID FROM @AnhHuong);

    SELECT DISTINCT a.RunID, c.Khoi
    FROM @AnhHuong a
    JOIN tblTKB_ChayAutoLog c ON c.RunID = a.RunID
    ORDER BY c.Khoi;
END
