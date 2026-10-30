CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetMyContentLibrary_OLD]
    @sys_UserID VARCHAR(9),
    @KhoiID INT,
    @MonHocID INT,
    @SearchTerm NVARCHAR(255),
    @NienKhoa VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
	IF @sys_UserID = 'NA0000022'
	BEGIN
		SET @sys_UserID = 'NV0000907'
	END

    -- CTE 1: Lấy tất cả nội dung (Assignments và Lessons) do giáo viên tạo.
    -- Đây là nguồn dữ liệu chính và duy nhất.
    ;WITH AllContent AS (
        SELECT 
            a.AssignmentID AS ResourceID, 
            'ASSIGNMENT' AS ResourceType, 
            a.Title, 
            a.Instructions, 
            a.KhoiID, 
            a.MonHocID, 
            a.TuanHocID, 
            a.Chuong, 
            3 AS Status_Internal, -- Gán một trạng thái nội bộ
            ISNULL(a.UpdateTime, a.CreateTime) AS LastUpdateTime
        FROM dbo.tblEL_Assignments a
        WHERE a.CreateUser = @sys_UserID AND a.IsDeleted = 0
        
        UNION ALL
        
        SELECT 
            l.LessonID, 
            'LESSON', 
            l.Title, 
            l.[Description], 
            l.KhoiID, 
            l.MonHocID, 
            l.TuanHocID, 
            l.Chuong, 
            l.Status, 
            ISNULL(l.UpdateTime, l.CreateTime)
        FROM dbo.tblEL_Lessons l
        WHERE l.CreateUser = @sys_UserID AND l.IsDeleted = 0
    ),

    -- CTE 2: Tính toán chi tiết các lần giao bài.
    AssignmentDetails AS (
        SELECT
            atc.ResourceID, 
            atc.ResourceType,
            COUNT(DISTINCT atc.MonHocLopID) AS AssignedClassCount,
            STUFF((
                SELECT DISTINCT ', ' + l.TenLop 
                FROM dbo.tblEL_AssignToClass i 
                JOIN dbo.tblMonHocLop mhl ON i.MonHocLopID = mhl.MonHocLopID 
                JOIN dbo.tblLop l ON mhl.LopNhomID = l.LopID AND l.NienKhoa = mhl.NienKhoa
                WHERE i.ResourceID = atc.ResourceID AND i.ResourceType = atc.ResourceType AND i.IsDeleted = 0 
                FOR XML PATH('')
            ), 1, 2, '') AS AssignedClassNames,
            (
                SELECT 
                    l.TenLop, l.LopID, i.AssignToClassID, i.AssignmentID, i.ResourceType, 
                    i.ResourceID, i.Status, i.DueDate, i.MaxScore 
                FROM dbo.tblEL_AssignToClass i 
                JOIN dbo.tblMonHocLop mhl ON i.MonHocLopID = mhl.MonHocLopID 
                JOIN dbo.tblLop l ON mhl.LopNhomID = l.LopID AND l.NienKhoa = mhl.NienKhoa
                WHERE i.ResourceID = atc.ResourceID AND i.ResourceType = atc.ResourceType AND i.IsDeleted = 0 
                FOR JSON PATH
            ) AS AssignedDetails
        FROM dbo.tblEL_AssignToClass atc
        WHERE atc.IsDeleted = 0
        GROUP BY atc.ResourceID, atc.ResourceType
    )

    -- Câu lệnh SELECT chính: Chỉ lấy từ AllContent và join thông tin.
    SELECT 
        ac.ResourceID, 
        ac.ResourceType, 
        ac.Title,
        ac.Instructions,
        mh.MonHocName, 
        k.TenKhoiHoc AS TenKhoi,
        ISNULL(ad.AssignedClassCount, 0) AS AssignedClassCount,
        ad.AssignedClassNames,
        ad.AssignedDetails,
        CASE
            WHEN ISNULL(ad.AssignedClassCount, 0) > 0 THEN 3 -- Đã giao
            WHEN ac.Status_Internal = 2 THEN 2 -- Đã xuất bản (Lesson)
            ELSE 1 -- Nháp
        END AS Status,
        ac.LastUpdateTime, 
        ac.KhoiID, 
        ac.MonHocID,
        ac.TuanHocID,
        N'Tuần ' + CAST(tht.TuanTrongNam AS VARCHAR(2)) + N' - Tháng ' + CAST(tht.ThangHoc AS VARCHAR(2)) + N' - Năm ' + CAST(YEAR(tht.NgayBatDau) AS VARCHAR(4)) AS Tuan_HienThi,
        ac.Chuong,
        CASE WHEN ac.ResourceType = 'ASSIGNMENT' THEN ac.ResourceID ELSE NULL END AS AssignmentID
    FROM AllContent ac
    LEFT JOIN dbo.tblMonHoc mh ON ac.MonHocID = mh.MonHocID
    LEFT JOIN dbo.tblKhoi k ON ac.KhoiID = k.KhoiID
    LEFT JOIN AssignmentDetails ad ON ac.ResourceID = ad.ResourceID AND ac.ResourceType = ad.ResourceType
    LEFT JOIN dbo.tblTuanHocTap AS tht ON tht.TuanHocID = ac.TuanHocID
    WHERE
        (@KhoiID IS NULL OR ac.KhoiID = @KhoiID)
        AND (@MonHocID IS NULL OR ac.MonHocID = @MonHocID)
        AND (@SearchTerm IS NULL OR ac.Title LIKE '%' + @SearchTerm + '%')
    ORDER BY
        KhoiID, MonHocID, TuanHocID, Chuong, LastUpdateTime DESC;

END
