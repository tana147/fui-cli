CREATE PROCEDURE [dbo].[spAPI_TemplateBangDiemChiTiet_DSNhomDiem_Del_By_MaNhomDiem]
    @JSON_MaNhomCotDiem NVARCHAR(MAX)
  , @SYS_USERID         VARCHAR(9)
AS
BEGIN
    DECLARE @Table_MaNhomCotDiem TABLE
    (
        MaNhomCotDiem      NVARCHAR(100)
      , TemplateBangDiemID INT
    );
    INSERT @Table_MaNhomCotDiem
    (
        MaNhomCotDiem
      , TemplateBangDiemID
    )
    SELECT *
    FROM
           OPENJSON(@JSON_MaNhomCotDiem)
           WITH
           (
               MaNhomCotDiem NVARCHAR(100)
             , TemplateBangDiemID INT
           );

    UPDATE dbo.TemplateBangDiemChiTiet
    SET    Enable = 0
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    FROM
           dbo.TemplateBangDiemChiTiet     AS tbdct
           INNER JOIN @Table_MaNhomCotDiem AS t_mnct ON t_mnct.MaNhomCotDiem      = tbdct.MaNhomCotDiem
                                                    AND t_mnct.TemplateBangDiemID = tbdct.TemplateBangDiemID;

END;
