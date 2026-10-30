CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_PublishGrade_Multiple]
    @Json_HocSinhSubmited NVARCHAR(MAX),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    -- Dùng một rule chuẩn giống PublishGrade đơn và các API teacher khác.
    -- Không dùng mapping cũ NA0000022 -> NV0000873 vì có thể khác tài khoản
    -- đang active trong tblEL_User_Assign tại thời điểm chạy.
    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);


    DECLARE @Table_HocSinhSubmited TABLE
    (
        SubmissionID BIGINT,
        SubmissionContent NVARCHAR(MAX),
        Score DECIMAL(5, 2)
    );
    INSERT INTO @Table_HocSinhSubmited (SubmissionID, SubmissionContent, Score)
    SELECT SubmissionID, SubmissionContent, Score
    FROM OPENJSON(@Json_HocSinhSubmited)
    WITH (
        SubmissionID INT '$.SubmissionID',
        SubmissionContent NVARCHAR(MAX) '$.SubmissionContent',
        Score DECIMAL(5, 2) '$.Score'
    );
    -- 🔹 Duyệt từng dòng bằng CURSOR
   DECLARE 
       @SubmissionID BIGINT,
       @SubmissionContent NVARCHAR(MAX),
       @Score DECIMAL(5,2),
       @AssignToClassID BIGINT,
       @AssignToStudentID BIGINT;

   DECLARE cur CURSOR FOR
       SELECT SubmissionID, SubmissionContent, Score FROM @Table_HocSinhSubmited;

   OPEN cur;
   FETCH NEXT FROM cur INTO @SubmissionID, @SubmissionContent, @Score;

   WHILE @@FETCH_STATUS = 0
   BEGIN
       SET @AssignToClassID = NULL;
       SET @AssignToStudentID = NULL;
       SELECT @AssignToClassID = s.AssignToClassID,
              @AssignToStudentID = s.AssignToStudentID
       FROM dbo.tblEL_Submissions s
       WHERE s.SubmissionID = @SubmissionID;

       -- Batch có thể chứa cả bài giao theo lớp và bài giao riêng.
       -- -1/0 là giá trị sentinel cho nhánh không áp dụng, không phải khóa hợp lệ.
       -- Chỉ chọn nhánh STUDENT khi AssignToStudentID là ID dương; nếu không,
       -- submission giao theo lớp sẽ bị gọi nhầm store STUDENT và làm AssignmentID=NULL.
       IF @AssignToStudentID > 0
       BEGIN
           EXEC dbo.spAPI_EL_Teacher_PublishGrade_AssignToStudent
               @SubmissionID = @SubmissionID,
               @Score = @Score,
               @TeacherComment = NULL,
               @SubmissionContent = @SubmissionContent,
               @sys_UserID = @sys_UserID;
       END
       ELSE IF @AssignToClassID > 0
       BEGIN
           EXEC dbo.spAPI_EL_Teacher_PublishGrade
               @SubmissionID = @SubmissionID,
               @Score = @Score,
               @TeacherComment = NULL,
               @SubmissionContent = @SubmissionContent,
               @sys_UserID = @sys_UserID;
       END;

       FETCH NEXT FROM cur INTO @SubmissionID, @SubmissionContent, @Score;
   END;

   CLOSE cur;
   DEALLOCATE cur;
END;
