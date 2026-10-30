CREATE PROCEDURE [dbo].[spAPI_TemplateBangDiem_Get]
    @NienKhoa           INT = 2024
  , @TemplateBangDiemID INT
  , @CapID              INT
  , @SYS_USERID         VARCHAR(9)
  , @Sys_GroupID        INT
AS
BEGIN

    DECLARE @MsgError NVARCHAR(500);
    --IF @Sys_GroupID <> 1
    --BEGIN
    --	SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
    --	RAISERROR(@MsgError, 16, 1)
    --	RETURN 0;
    --END
    --ELSE


    SELECT MS.TemplateBangDiemID
         , MS.TemplateBangDiemName
         , MS.CreateUser
         , COUNT(DT.CotDiemID) AS SoCotDiem
    FROM
           dbo.TemplateBangDiem                  MS
           LEFT JOIN dbo.TemplateBangDiemChiTiet AS DT ON DT.TemplateBangDiemID = MS.TemplateBangDiemID
                                                      AND DT.Enable             = 1
    WHERE
           (
               @TemplateBangDiemID   = 0
          OR   MS.TemplateBangDiemID = @TemplateBangDiemID
           )
      AND  MS.CapID                   = @CapID
      AND  MS.Enable                  = 1
      AND  MS.NienKhoa                = @NienKhoa
    GROUP BY
           MS.TemplateBangDiemID
         , MS.TemplateBangDiemName
         , MS.CreateUser
    ORDER BY
           MS.TemplateBangDiemName ASC;

END;
