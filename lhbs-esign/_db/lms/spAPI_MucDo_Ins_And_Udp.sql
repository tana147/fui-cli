CREATE PROC [dbo].[spAPI_MucDo_Ins_And_Udp]
    @JsonMucDo NVARCHAR(MAX)
  , @SYS_USERID  VARCHAR(9)
AS
BEGIN
   
    DECLARE @Table_ChiTieu TABLE
    (
        MucDo_ID   INT
      , MonHocLopID INT
      , TenMucDo    NVARCHAR(100)
      , DiemMin     FLOAT
      , DiemMax     FLOAT
      , Prefix      VARCHAR(10)
      , Suffix      VARCHAR(10)
    );
    INSERT INTO @Table_ChiTieu
    (
        MucDo_ID
      , MonHocLopID
      , TenMucDo
      , DiemMin
      , DiemMax
      , Prefix
      , Suffix
    )
    SELECT MucDo_ID
         , MonHocLopID
         , TenMucDo
         , DiemMin
         , DiemMax
         , Prefix
         , Suffix
    FROM
           OPENJSON(@JsonMucDo)
           WITH
           (
               MucDo_ID INT
             , MonHocLopID INT
             , TenMucDo NVARCHAR(100)
             , DiemMin FLOAT
             , DiemMax FLOAT
             , Prefix VARCHAR(10)
             , Suffix VARCHAR(10)
           );
    UPDATE ct
    SET    ct.TenMucDo = ISNULL(t_ct.TenMucDo, ct.TenMucDo)
         , ct.DiemMin = ISNULL(t_ct.DiemMin, ct.DiemMin)
         , ct.DiemMax = ISNULL(t_ct.DiemMax, ct.DiemMax)
         , ct.Prefix = ISNULL(t_ct.Prefix, ct.Prefix)
         , ct.Suffix = ISNULL(t_ct.Suffix, ct.Suffix)
		 , ct.UpdateUser = @SYS_USERID,
		 ct.UpdateTime = GETDATE()
    FROM
           dbo.tbl_MucDo                AS ct
           INNER JOIN @Table_ChiTieu AS t_ct ON t_ct.MucDo_ID = ct.MucDo_ID;

    INSERT INTO tbl_MucDo
    (
        MonHocLopID
      , TenMucDo
      , DiemMin
      , DiemMax
      , Prefix
      , Suffix
	  , Enable
	  , CreateUser
	  , CreateTime
    )
    SELECT t_ct.MonHocLopID
         , t_ct.TenMucDo
         , t_ct.DiemMin
         , t_ct.DiemMax
         , t_ct.Prefix
         , t_ct.Suffix
		 , 1
		 , @SYS_USERID
		 , GETDATE()
    FROM
           @Table_ChiTieu AS t_ct
    WHERE
           NOT EXISTS
    (
        SELECT *
        FROM
               dbo.tbl_MucDo AS ct
        WHERE
               t_ct.MucDo_ID = ct.MucDo_ID
    );


END;