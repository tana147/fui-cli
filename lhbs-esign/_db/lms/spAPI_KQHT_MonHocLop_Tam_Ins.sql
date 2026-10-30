CREATE PROC [dbo].[spAPI_KQHT_MonHocLop_Tam_Ins]
@MonHocLopID INT,
@LopID INT,
@MonHocID INT,
@TemplateBangDiemID INT,
@KetQuaObjArr NVARCHAR(MAX),
@SYS_UserID VARCHAR(9),
@Sys_GroupID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra tính hợp lệ của JSON đầu vào
    IF ISJSON(@KetQuaObjArr) = 0
    BEGIN
        RAISERROR('Dữ liệu JSON không hợp lệ.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        -- Bắt đầu giao dịch
        BEGIN TRANSACTION;

        -- Lấy năm học hiện tại
        DECLARE @NienKhoa INT;
        SET @NienKhoa = [dbo].fn_GetNienKhoa_HienTai();

        -- MERGE dữ liệu từ JSON vào bảng tblKetQuaHocTap
        MERGE INTO [dbo].[tblKetQuaHocTap] AS target
        USING (
            SELECT
                @MonHocLopID AS MonHocLopID,
                JSON_VALUE(value, '$.HocSinhID') AS HocSinhID,
                @LopID AS LopID,
                @NienKhoa AS NienKhoa,
                JSON_VALUE(value, '$.CotDiemID') AS CotDiemID,
                JSON_VALUE(value, '$.KetQuaDanhGia_VI') AS KetQuaDanhGia_VI,
                JSON_VALUE(value, '$.KetQuaDanhGia_EN') AS KetQuaDanhGia_EN,
                JSON_VALUE(value, '$.Is_Reject') AS Is_Reject,
                JSON_VALUE(value, '$.ReasonReject') AS ReasonReject,
                @SYS_UserID AS CreateUser
            FROM OPENJSON(@KetQuaObjArr)
        ) AS source
        ON target.HocSinhID = source.HocSinhID 
            AND target.MonHocLopID = source.MonHocLopID 
            AND target.CotDiemID = source.CotDiemID 
            AND target.LopID = @LopID
        WHEN MATCHED THEN
            UPDATE SET 
                target.KetQuaDanhGia_VI = source.KetQuaDanhGia_VI,
                target.KetQuaDanhGia_EN = source.KetQuaDanhGia_EN,
                target.Is_Reject = source.Is_Reject,
                target.ReasonReject = source.ReasonReject,
                target.UpdateUser = source.CreateUser,
                target.UpdateTime = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT ([MonHocLopID], [HocSinhID], [LopID], [NienKhoa], [CotDiemID], [KetQuaDanhGia_VI], [KetQuaDanhGia_EN], [CreateUser], [CreateTime])
            VALUES (source.MonHocLopID, source.HocSinhID, source.LopID, @NienKhoa, source.CotDiemID, source.KetQuaDanhGia_VI, source.KetQuaDanhGia_EN, source.CreateUser, GETDATE());

        -- Lấy danh sách công thức điểm từ TemplateBangDiemChiTiet
        DECLARE @tblFormula TABLE (CotDiemID INT, Formula NVARCHAR(MAX));
        INSERT INTO @tblFormula (CotDiemID, Formula)
        SELECT CotDiemID, Formula 
        FROM TemplateBangDiemChiTiet
        WHERE TemplateBangDiemID = @TemplateBangDiemID 
		AND LoaiCotDiem = N'Công thức'
		ORDER BY ThuTuNhom, ThuTuCotDiem;

        -- Lấy danh sách học sinh từ JSON
        DECLARE @HocSinhList TABLE (HocSinhID INT);
        INSERT INTO @HocSinhList (HocSinhID)
        SELECT DISTINCT JSON_VALUE(value, '$.HocSinhID')
        FROM OPENJSON(@KetQuaObjArr);

        -- Biến để xử lý logic
        DECLARE @HocSinhID INT;
        DECLARE @CotDiemID INT;
        DECLARE @Formula NVARCHAR(MAX);
        DECLARE @Result FLOAT;
        DECLARE @ResultFormular NVARCHAR(MAX);

        -- Lặp qua từng cột công thức
        DECLARE FormulaCursor CURSOR FOR 
        SELECT CotDiemID, Formula FROM @tblFormula;

        OPEN FormulaCursor;
        FETCH NEXT FROM FormulaCursor INTO @CotDiemID, @Formula;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Lặp qua từng học sinh
            DECLARE HocSinhCursor CURSOR FOR 
            SELECT HocSinhID FROM @HocSinhList;

            OPEN HocSinhCursor;
            FETCH NEXT FROM HocSinhCursor INTO @HocSinhID;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Gọi thủ tục Pro_GetMark để tính toán
                EXEC dbo.Pro_GetMark 
                    @formular = @Formula,
                    @studentId = @HocSinhID,
                    @lopid = @LopID,
                    @monhoclopid = @MonHocLopID,
					@Templatebangdiemid = @TemplateBangDiemID,
                    @Result = @Result OUTPUT,
                    @ResultFormular = @ResultFormular OUTPUT;

                -- Cập nhật kết quả vào bảng tblKetQuaHocTap
                UPDATE tblKetQuaHocTap_Tam
                SET KetQuaDanhGia_VI = @Result
                WHERE HocSinhID = @HocSinhID
                  AND CotDiemID = @CotDiemID
                  AND LopID = @LopID
                  AND MonHocLopID = @MonHocLopID;

                FETCH NEXT FROM HocSinhCursor INTO @HocSinhID;
            END;

            CLOSE HocSinhCursor;
            DEALLOCATE HocSinhCursor;

            FETCH NEXT FROM FormulaCursor INTO @CotDiemID, @Formula;
        END;

        CLOSE FormulaCursor;
        DEALLOCATE FormulaCursor;

        -- Commit giao dịch
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback giao dịch nếu có lỗi
        ROLLBACK TRANSACTION;

        -- Log lỗi nếu cần
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;

END
