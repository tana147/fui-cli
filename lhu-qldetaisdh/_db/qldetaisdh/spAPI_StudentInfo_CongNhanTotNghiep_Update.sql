
CREATE PROC [dbo].[spAPI_StudentInfo_CongNhanTotNghiep_Update]
@JsonStudentID NVARCHAR(MAX),

@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	
	IF ISJSON(@JsonStudentID) = 0
		BEGIN
		    RAISERROR(N'Dữ liệu chưa đúng hoặc đang thiếu', 16, 1);
		    RETURN 0;
		END

	DECLARE @TempTable AS TABLE(StudentID VARCHAR(9) NOT NULL)

	INSERT INTO @TempTable(StudentID)
        SELECT StudentID
        FROM
            OPENJSON(@JsonStudentID)
            WITH(StudentID NVARCHAR(500) '$.StudentID')

	UPDATE si
	SET IsHoanThanhThacSi = 1
	FROM StudentInfo si
	INNER JOIN @TempTable t ON t.StudentID = si.StudentID
END