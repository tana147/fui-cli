CREATE PROC spAPI_HocSinhNhom_Del_HSNhomID
@HSNhomID INT,
@SYS_USERID VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblHocSinhNhom
	SET
		Enable = 0,
		UpdateUser = @SYS_USERID,
		UpdateTime = GETDATE()
	WHERE HSNhomID = @HSNhomID

	INSERT INTO tbl_LOG_HocSinhNhom
	(
		 HSNhomID,
		 HocSinhID, 
		 LopID, 
		 NhomID, 
		 SoDanhBo,
		 SoTT, 
		 Enable, 
		 CreateUser,
		 CreateTime
	)
	SELECT 
		HSNhomID
      , HocSinhID
      , LopID
      , NhomID
      , SoDanhBo
      , SoTT
      , 0
      , @SYS_USERID
      , GETDATE()
	FROM dbo.tblHocSinhNhom
	WHERE HSNhomID = @HSNhomID
END