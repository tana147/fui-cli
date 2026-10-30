CREATE   PROC [dbo].[spAPI_TuQuan_DanhGiaNgay_Save]
    @Ngay VARCHAR(20),
    @TuanHocID INT = NULL,
    @EvaluationsJson NVARCHAR(MAX) = NULL,
    @UserCode VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @dtNgay DATE = TRY_CAST(@Ngay AS DATE);
    IF @dtNgay IS NULL SET @dtNgay = CAST(GETDATE() AS DATE);

    IF @EvaluationsJson IS NOT NULL AND ISJSON(@EvaluationsJson) = 1
    BEGIN
        MERGE INTO dbo.tblTuQuan_DanhGiaNgay AS target
        USING (
            SELECT 
                LopID,
                @dtNgay AS Ngay,
                @TuanHocID AS TuanHocID,
                CAST(ISNULL(IsTuQuan, 1) AS BIT) AS IsTuQuan,
                CAST(ISNULL(GVCNCoMat, 0) AS BIT) AS GVCNCoMat,
                TieuChiList,
                ISNULL(GhiChuViPham, N'') AS GhiChuViPham,
                ISNULL(NguoiCham, N'') AS NguoiCham,
                ISNULL(XepLoai, '') AS XepLoai,
                @UserCode AS UserCode
            FROM OPENJSON(@EvaluationsJson)
            WITH (
                LopID INT,
                IsTuQuan BIT,
                GVCNCoMat BIT,
                TieuChiList NVARCHAR(MAX) AS JSON,
                GhiChuViPham NVARCHAR(500),
                NguoiCham NVARCHAR(100),
                XepLoai VARCHAR(20)
            )
        ) AS source
        ON (target.LopID = source.LopID AND target.Ngay = source.Ngay AND target.Enable = 1)
        WHEN MATCHED THEN
            UPDATE SET 
                target.IsTuQuan = source.IsTuQuan,
                target.GVCNCoMat = source.GVCNCoMat,
                target.TieuChiList = source.TieuChiList,
                target.GhiChuViPham = source.GhiChuViPham,
                target.NguoiCham = source.NguoiCham,
                target.XepLoai = source.XepLoai,
                target.TuanHocID = source.TuanHocID,
                target.UpdateUser = source.UserCode,
                target.UpdateTime = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (LopID, Ngay, TuanHocID, IsTuQuan, GVCNCoMat, TieuChiList, GhiChuViPham, NguoiCham, XepLoai, CreateUser, CreateTime, Enable)
            VALUES (source.LopID, source.Ngay, source.TuanHocID, source.IsTuQuan, source.GVCNCoMat, source.TieuChiList, source.GhiChuViPham, source.NguoiCham, source.XepLoai, source.UserCode, GETDATE(), 1);
    END;

    SELECT 
        DanhGiaID,
        LopID,
        CONVERT(VARCHAR(10), Ngay, 120) AS NgayYMD,
        TuanHocID,
        IsTuQuan,
        GVCNCoMat,
        TieuChiList,
        GhiChuViPham,
        NguoiCham,
        XepLoai
    FROM dbo.tblTuQuan_DanhGiaNgay
    WHERE Ngay = @dtNgay AND Enable = 1;
END;