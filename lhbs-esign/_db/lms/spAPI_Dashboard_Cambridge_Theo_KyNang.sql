-- [dbo].[spAPI_Dashboard_Cambridge_Theo_KyNang]
CREATE PROC [dbo].[spAPI_Dashboard_Cambridge_Theo_KyNang]
    @NienKhoa INT
  , @CapID    INT
  , @Semester VARCHAR(20)
AS
BEGIN

    DECLARE @GK NVARCHAR(20) = N'';
    DECLARE @CK NVARCHAR(20) = N'';
 
	IF @Semester = 'HK1'
	BEGIN
		SET @GK = N'S1_Mid';
		SET @CK = N'S1_Final';
	END;
	ELSE IF @Semester = 'HK2'
	BEGIN
		SET @GK = N'S2_Mid';
		SET @CK = N'S2_Final';
	END;
	 
	 --Giữa kì
SELECT 
      l.KhoiID
    , COUNT(DISTINCT hsl.HocSinhID) AS TongHocSinh

    /* ================== ĐỌC ================== */
    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Reading%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END) AS Doc_VYC
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Reading%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Doc_VYC_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Reading%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END) AS Doc_D
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Reading%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Doc_D_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Reading%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END) AS  Doc_CD
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Reading%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS  Doc_CD_PCT

    /* ================== NGHE ================== */
    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Listening%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END) AS Nghe_VYC
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Listening%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Nghe_VYC_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Listening%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END) AS Nghe_D
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Listening%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Nghe_D_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Listening%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END) AS  Nghe_CD
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Listening%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS  Nghe_CD_PCT

    /* ================== VIẾT ================== */
    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Writing%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END) AS Viet_VYC
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Writing%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Viet_VYC_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Writing%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END) AS Viet_D
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Writing%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Viet_D_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Writing%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END) AS  Viet_CD
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Writing%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS  Viet_CD_PCT

    /* ================== NÓI ================== */
    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Speaking%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END) AS Noi_VYC
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Speaking%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Noi_VYC_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Speaking%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END) AS Noi_D
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Speaking%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Noi_D_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Speaking%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END) AS  Noi_CD
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Speaking%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS  Noi_CD_PCT

      /* ================== Trung bình ================== */
    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Avg%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END) AS TrungBinh_VYC
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Avg%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS TrungBinh_VYC_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Avg%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END) AS TrungBinh_D
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Avg%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS TrungBinh_D_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Avg%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END) AS  TrungBinh_CD
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @GK + '%_CB_Avg%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) 
      AS DECIMAL(5,2)) AS  TrungBinh_CD_PCT

FROM dbo.tblKetQuaHocTap kqht
INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.CotDiemID = kqht.CotDiemID
       AND ct.Enable = 1
       AND ct.MaCotDiem LIKE @GK + '%_CB_%'
INNER JOIN dbo.tblMonHocLop mhl 
        ON mhl.MonHocLopID = kqht.MonHocLopID
       AND mhl.Enable = 1
       AND mhl.MonHocID = 46
INNER JOIN dbo.tblLop l 
        ON l.LopID = kqht.LopID
       AND l.NienKhoa = @NienKhoa
INNER JOIN dbo.tblHocSinhLop hsl
        ON hsl.LopID = l.LopID
       AND hsl.HocSinhID = kqht.HocSinhID
WHERE kqht.NienKhoa = @NienKhoa
  AND kqht.Enable = 1
  AND ct.MaCotDiem LIKE '%Conv'
GROUP BY l.KhoiID;

--Cuối kì
SELECT 
      l.KhoiID
    , COUNT(DISTINCT hsl.HocSinhID) AS TongHocSinh

    /* ================== ĐỌC ================== */
    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Reading%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END) AS Doc_VYC
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Reading%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Doc_VYC_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Reading%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END) AS Doc_D
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Reading%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Doc_D_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Reading%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END) AS  Doc_CD
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Reading%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS  Doc_CD_PCT

    /* ================== NGHE ================== */
    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Listening%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END) AS Nghe_VYC
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Listening%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Nghe_VYC_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Listening%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END) AS Nghe_D
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Listening%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Nghe_D_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Listening%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END) AS  Nghe_CD
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Listening%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS  Nghe_CD_PCT

    /* ================== VIẾT ================== */
    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Writing%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END) AS Viet_VYC
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Writing%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Viet_VYC_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Writing%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END) AS Viet_D
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Writing%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Viet_D_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Writing%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END) AS  Viet_CD
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Writing%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS  Viet_CD_PCT

    /* ================== NÓI ================== */
    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Speaking%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END) AS Noi_VYC
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Speaking%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Noi_VYC_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Speaking%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END) AS Noi_D
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Speaking%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS Noi_D_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Speaking%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END) AS  Noi_CD
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Speaking%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS  Noi_CD_PCT

      /* ================== Trung bình ================== */
    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Avg%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END) AS TrungBinh_VYC
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Avg%' 
             AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS TrungBinh_VYC_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Avg%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END) AS TrungBinh_D
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Avg%' 
             AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0)
      AS DECIMAL(5,2)) AS TrungBinh_D_PCT

    , SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Avg%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END) AS  TrungBinh_CD
    , CAST(
        100.0 * SUM(CASE 
            WHEN ct.MaCotDiem LIKE @CK + '%_CB_Avg%' 
             AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' 
          THEN 1 ELSE 0 END)
        / NULLIF(COUNT(DISTINCT hsl.HocSinhID),0) 
      AS DECIMAL(5,2)) AS  TrungBinh_CD_PCT

FROM dbo.tblKetQuaHocTap kqht
INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.CotDiemID = kqht.CotDiemID
       AND ct.Enable = 1
       AND ct.MaCotDiem LIKE @CK + '%_CB_%'
INNER JOIN dbo.tblMonHocLop mhl 
        ON mhl.MonHocLopID = kqht.MonHocLopID
       AND mhl.Enable = 1
       AND mhl.MonHocID = 46
INNER JOIN dbo.tblLop l 
        ON l.LopID = kqht.LopID
       AND l.NienKhoa = @NienKhoa
INNER JOIN dbo.tblHocSinhLop hsl
        ON hsl.LopID = l.LopID
       AND hsl.HocSinhID = kqht.HocSinhID
WHERE kqht.NienKhoa = @NienKhoa
  AND kqht.Enable = 1
  AND ct.MaCotDiem LIKE '%Conv'
GROUP BY l.KhoiID;

END;

