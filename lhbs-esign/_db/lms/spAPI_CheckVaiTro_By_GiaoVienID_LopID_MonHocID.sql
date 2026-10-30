CREATE PROC [dbo].[spAPI_CheckVaiTro_By_GiaoVienID_LopID_MonHocID]
    @LopID      INT,
    @MonHocID   INT,
    @SYS_USERID VARCHAR(10),
	@HocKi INT
AS
BEGIN
    DECLARE @VaiTro INT = 0;
    DECLARE @GVLopID INT  = NULL;
    DECLARE @IsGiaoVienDayMon BIT = 0;

    -- Kiểm tra giáo viên có dạy môn học đó không
    SELECT TOP 1
           @GVLopID = GVLopID,
           @VaiTro  = VaiTro
    FROM dbo.tblGiaoVienLop
    WHERE GiaoVienID = @SYS_USERID
      AND MonHocID   = @MonHocID
      AND LopID      = @LopID
      AND Enable     = 1
	  AND HocKy =  @HocKi;

    -- Nếu giáo viên có dạy môn học đó, đánh dấu IsGiaoVienDayMon = 1
    IF @GVLopID IS NOT NULL
        SET @IsGiaoVienDayMon = 1;

    -- Nếu chưa có VaiTro (chưa tìm thấy giáo viên dạy môn), kiểm tra giáo viên chủ nhiệm
    IF @VaiTro = 0
    BEGIN
        SELECT TOP 1 @VaiTro = VaiTro
        FROM dbo.tblGiaoVienLop
        WHERE GiaoVienID = @SYS_USERID
          AND LopID      = @LopID
          AND VaiTro     = 1 -- Giáo viên chủ nhiệm
          AND Enable     = 1
		  AND HocKy =  @HocKi;
          
        -- Nếu vẫn không tìm thấy vai trò nào, gán mặc định là 0 (không có vai trò)
        IF @VaiTro IS NULL
            SET @VaiTro = 0;
    END;

    -- Trả kết quả
    SELECT convert_to_object = '',
           @VaiTro AS VaiTro,
           @IsGiaoVienDayMon AS Is_MonHoc_GiangDay;
END;
