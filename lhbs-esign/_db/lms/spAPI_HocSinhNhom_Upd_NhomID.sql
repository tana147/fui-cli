CREATE PROC [dbo].[spAPI_HocSinhNhom_Upd_NhomID]
    @HSNhomID   INT
  , @NhomID     NVARCHAR(20)
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblHocSinhNhom
    SET    NhomID = @NhomID
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           HSNhomID = @HSNhomID;

    --Insert log
    INSERT INTO dbo.tbl_LOG_HocSinhNhom
    (
        HSNhomID
      , HocSinhID
      , LopID
      , NhomID
      , SoDanhBo
      , SoTT
      , Enable
      , CreateUser
      , CreateTime
    )
    SELECT HSNhomID
         , HocSinhID
         , LopID
         , @NhomID
         , SoDanhBo
         , SoTT
         , 1
         , @SYS_USERID
         , GETDATE()
    FROM
           dbo.tblHocSinhNhom
    WHERE
           HSNhomID = @HSNhomID;
END; 