-- [spAPI_AUTH_LMS_KetQuaHocTap_ByHocSinhID] 2025, 20100129
 CREATE PROC [dbo].[spAPI_AUTH_LMS_KetQuaHocTap_ByHocSinhID]
    @NienKhoa  INT
  , @HocSinhID INT
AS
BEGIN
	


    DECLARE @CapId INT;
    SELECT @CapId = l.CapID
    FROM
           dbo.tblHocSinhLop         hsl
           INNER JOIN dbo.tblLop     l ON l.LopID       = hsl.LopID
                                      AND l.Enable      = 1
                                      AND l.NienKhoa    = @NienKhoa
           AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID
    WHERE
           hsl.Enable  = 1
      AND  hs.HocSinhID = @HocSinhID;
 
    IF (@CapId = 1)
    BEGIN
       EXEC fn_GetKetQuaHocTapTheoLop_C1_ByHocSinhID @NienKhoa = @NienKhoa
                                                    , @HocSinhID = @HocSinhID;
    END;
    ELSE IF (@CapId = 2)
    BEGIN
		
        EXEC fn_GetKetQuaHocTapTheoLop_C2_ByHocSinhID @NienKhoa = @NienKhoa
                                                    , @HocSinhID = @HocSinhID;
    END;
    ELSE IF (@CapId = 3)
    BEGIN
        EXEC fn_GetKetQuaHocTapTheoLop_C3_ByHocSinhID @NienKhoa = @NienKhoa
                                                    , @HocSinhID = @HocSinhID;
    END;

END;