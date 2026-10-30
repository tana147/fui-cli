CREATE PROC spAPI_FP_Youtube_Token_Get
AS
BEGIN
    SELECT convert_to_object = ''
         , access_token
         , expires_in
         , scope
         , token_type
    FROM
           dbo.fn_tblGetAccessToken_OAuth_Youtube();
END;