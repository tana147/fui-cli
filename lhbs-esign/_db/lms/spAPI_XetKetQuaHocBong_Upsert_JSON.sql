CREATE PROCEDURE [dbo].[spAPI_XetKetQuaHocBong_Upsert_JSON]
    @json       NVARCHAR(MAX)
  , @NienKhoa   INT
  , @Sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Parse JSON array
    -- Giả sử mỗi object có: HocSinhID, LopID, KQRL_Sau
    -- Bạn có thể truyền thêm nếu muốn KQRL_Truoc

    -- Tạo bảng tạm từ JSON
    WITH ParsedData AS
    (
        SELECT JSON_VALUE(Value, '$.HocSinhID')   AS HocSinhID
             , JSON_VALUE(Value, '$.TenLop')      AS TenLop
             , JSON_VALUE(Value, '$.HocBong_Sau') AS HocBong_Sau
        FROM
               OPENJSON(@json)
    )

    -- Tiến hành UPSERT
    MERGE dbo.tblXetKetQuaHocBong AS Target
    USING ParsedData AS Source
    ON Target.HocSinhID = Source.HocSinhID
   AND Target.TenLop = Source.TenLop

    -- Nếu đã tồn tại thì cập nhật
    WHEN MATCHED THEN UPDATE SET   Target.HocBong_Sau = Source.HocBong_Sau
                               , Target.UpdateUser = @Sys_UserID
                               , Target.UpdateTime = GETDATE()

    -- Nếu chưa có thì thêm mới
    WHEN NOT MATCHED THEN INSERT
                          (
                              HocSinhID
                            , LopID
                            , TenLop
                            , HocBong_Truoc
                            , HocBong_Sau
                            , NienKhoa
                            , CreateUser
                            , CreateTime
                          )
                          VALUES
                          (
                              Source.HocSinhID
                            , (
                                  SELECT LopID
                                  FROM
                                         dbo.tblLop
                                  WHERE
                                         TenLop  = Source.TenLop
                                    AND  NienKhoa = @NienKhoa
                              )
                            , Source.TenLop
                            , Source.HocBong_Sau
                            , NULL
                            , @NienKhoa
                            , @Sys_UserID
                            , GETDATE()
                          );
END;
