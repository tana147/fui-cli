-- =================================================================================
-- Author:         AI Agent (for Fast Project)
-- Create date:    [Ngày hiện tại]
-- Description:    Lấy danh sách các bài giảng do giáo viên hiện tại tạo.
--                 Hỗ trợ tìm kiếm, lọc và phân trang.
--                 Quy ước: Tham số INT = 0 có nghĩa là không lọc.
-- API Endpoint:   GET lms/EL_Lesson_GetListByTeacher
-- Ví dụ Payload:  {"SearchTerm": "cộng", "Status": 2, "MonHocLopID": 7801, "PageNumber": 1, "PageSize": 10}
--                 {"SearchTerm": null, "Status": 0, "MonHocLopID": 0, "PageNumber": 1, "PageSize": 10}
-- =================================================================================
-- [dbo].[spAPI_EL_Assigment_GetListByTeacher] 'NV0000593'

 CREATE PROCEDURE [dbo].[spAPI_EL_Assigment_GetListByTeacher] --'NA0000022',NULL,0,0,1,20
    @sys_UserID VARCHAR(9),
    @SearchTerm NVARCHAR(255),
    @Status TINYINT,           -- Mặc định là 0
    @MonHocLopID INT,           -- Mặc định là 0
    @PageNumber INT,
    @PageSize INT
AS
BEGIN
   select 
		atc.AssignToClassID,
		asm.AssignmentID,
		asm.Title,
		asm.Instructions,
		atc.AssignmentConfig,
		atc.DueDate,
		atc.MaxScore,
		MonHocName,
		TenLop,
		asm.IntegrationSource
   from dbo.tblEL_AssignToClass as atc
		inner join tblEL_Assignments as asm on asm.AssignmentID = atc.AssignmentID and asm.IsDeleted = 0
		inner join tblMonHocLop as mhl on mhl.MonHocLopID = atc.MonHocLopId and mhl.Enable = 1
		inner join tblMonHoc as mh on mh.MonHocID = mhl.MonHocID and mh.Enable = 1
		inner join tblLop as l on l.LopID = mhl.LopNhomID and l.Enable = 1 AND l.NienKhoa = mhl.NienKhoa
   where atc.CreateUser = @sys_UserID and atc.IsDeleted = 0
END
