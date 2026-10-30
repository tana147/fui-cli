CREATE PROCEDURE [dbo].[spAPI_AUTH_TKB_Khoi_Get]
    @NamHoc VARCHAR(20),
    @DonViID INT,
    @CapHoc INT,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        KhoiID,
        NamHoc,
        DonViID,
        TenKhoi
    FROM tblTKB_Khoi
    WHERE (@NamHoc IS NULL OR NamHoc = @NamHoc)
      AND (@DonViID IS NULL OR DonViID = @DonViID)
      AND (
            @CapHoc IS NULL 
            OR (@CapHoc = 0 AND (KhoiID <= 5 OR KhoiID >= 19 OR KhoiID < 0 OR TenKhoi LIKE N'%Tháng%' OR TenKhoi LIKE N'%Mầm%' OR TenKhoi LIKE N'%Chồi%' OR TenKhoi LIKE N'%Lá%' OR TenKhoi LIKE N'%Nhà trẻ%')) -- Cấp 0: Mầm non (bao gồm KhoiID 19-23)
            OR (@CapHoc = 1 AND (KhoiID >= 6 AND KhoiID <= 10)) -- Cấp 1: Tiểu học
            OR (@CapHoc = 2 AND (KhoiID >= 11 AND KhoiID <= 14)) -- Cấp 2: THCS
            OR (@CapHoc = 3 AND (KhoiID >= 15 AND KhoiID <= 17)) -- Cấp 3: THPT
          )
    ORDER BY KhoiID;
END