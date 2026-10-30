CREATE PROC [dbo].[spAPI_CongBoBangDiem_Get] --1,''
    @CapID      INT,
	@NienKhoa INT = 2025
  , @Sys_UserID VARCHAR(9)
AS
BEGIN
    IF (@Sys_UserID IN ('P21100117', 'NV0000195','NV0000009'))
    BEGIN
        SELECT *
        FROM
               [dbo].[tblCongBoBangDiem]
        WHERE
               CapID = @CapID AND NamHoc = @NienKhoa;
    END;
    ELSE
    BEGIN
        SELECT *
        FROM
               [dbo].[tblCongBoBangDiem]
        WHERE
               [Is_Public] = 1
          AND  CapID        = @CapID AND NamHoc = @NienKhoa;
    END;

END; 
