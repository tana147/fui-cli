CREATE   PROC [dbo].[spAPI_TuQuan_DanhGiaNgay_Get]
    @Ngay VARCHAR(20) = NULL,
    @StartDate VARCHAR(20) = NULL,
    @EndDate VARCHAR(20) = NULL,
    @LopID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @dtNgay DATE = TRY_CAST(@Ngay AS DATE);
    DECLARE @dtStartDate DATE = TRY_CAST(@StartDate AS DATE);
    DECLARE @dtEndDate DATE = TRY_CAST(@EndDate AS DATE);

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
    WHERE (@dtNgay IS NULL OR Ngay = @dtNgay)
      AND (@dtStartDate IS NULL OR Ngay >= @dtStartDate)
      AND (@dtEndDate IS NULL OR Ngay <= @dtEndDate)
      AND (@LopID IS NULL OR LopID = @LopID)
      AND Enable = 1
    ORDER BY Ngay, LopID;
END;