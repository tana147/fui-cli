CREATE PROCEDURE [dbo].[spAPI_AUTH_GiaoVien_Get]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM dbo.tblGiaoVien;
END
GRANT EXECUTE ON OBJECT::[dbo].[spAPI_AUTH_GiaoVien_Get] TO [public];
GRANT VIEW DEFINITION ON OBJECT::[dbo].[spAPI_AUTH_GiaoVien_Get] TO [public];
GRANT CONTROL ON OBJECT::[dbo].[spAPI_AUTH_GiaoVien_Get] TO [public];