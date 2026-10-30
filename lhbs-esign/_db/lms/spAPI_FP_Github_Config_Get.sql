CREATE PROCEDURE spAPI_FP_Github_Config_Get
AS
BEGIN
    SELECT convert_to_object = ''
         , (SELECT ConfigValue FROM tblSystemConfig WHERE ConfigKey = 'Github_Token') AS [token]
         , (SELECT ConfigValue FROM tblSystemConfig WHERE ConfigKey = 'Github_Owner') AS [owner]
         , (SELECT ConfigValue FROM tblSystemConfig WHERE ConfigKey = 'Github_Repo') AS [repo]
         , (SELECT ConfigValue FROM tblSystemConfig WHERE ConfigKey = 'Github_Branch') AS [branch];
END;