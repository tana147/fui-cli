-- name=spAPI_EL_Teacher_GetGradebook.sql
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetGradebook]
    @LopID VARCHAR(100), -- Tham số này thực chất là LopID hoặc NhomID
    @MonHocID INT,
    @sys_UserID VARCHAR(9),
    @NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;
    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);
    DECLARE @SqlStatement NVARCHAR(MAX);
    DECLARE @PivotColumns NVARCHAR(MAX);

    DECLARE @Key NVARCHAR(100) = @LopID;
    -- Phân biệt lớp/nhóm bằng khóa đầy đủ; không lấy niên khóa mới nhất theo mã đơn lẻ.
    IF (@NienKhoa IS NULL OR @NienKhoa = 0)
    BEGIN
        RAISERROR(N'NienKhoa là bắt buộc khi mở sổ điểm.', 16, 1);
        RETURN;
    END;

    DECLARE @NienKhoaID INT = @NienKhoa;
    DECLARE @IsLop BIT = CASE WHEN EXISTS (
        SELECT 1 FROM dbo.tblLop
        WHERE LopID = @Key AND NienKhoa = @NienKhoaID AND Enable = 1
    ) THEN 1 ELSE 0 END;
    DECLARE @IsNhom BIT = CASE WHEN EXISTS (
        SELECT 1 FROM dbo.tblNhom
        WHERE NhomID = @Key AND NienKhoa = @NienKhoaID AND Enable = 1
    ) THEN 1 ELSE 0 END;

    -- === Bước 1: Chuẩn hóa danh sách Học sinh (Lớp VÀ Nhóm) ===
    IF OBJECT_ID('tempdb..#QueryUnitStudents') IS NOT NULL DROP TABLE #QueryUnitStudents;

    CREATE TABLE #QueryUnitStudents (
        HocSinhID INT PRIMARY KEY,
        HoTen NVARCHAR(255),
        LopID VARCHAR(100),        -- sẽ chứa: LopID nếu truy vấn lớp; NGƯỢC LẠI chứa @Key (NhomID) nếu truy vấn nhóm
        NhomID VARCHAR(100) NULL,  -- lưu NhomID nếu truy vấn nhóm
        SoDanhBo VARCHAR(10)
    );

    INSERT INTO #QueryUnitStudents (HocSinhID, HoTen, LopID, NhomID, SoDanhBo)
    SELECT
        hs.HocSinhID,
        hs.Ho + ' ' + hs.Ten AS HoTen,
        -- Nếu đang truy vấn theo Nhom, gán LopID = @Key để UI/logic nào so sánh với tham số đầu vào thấy khớp.
        CASE WHEN @IsNhom = 1 THEN @Key ELSE hsl_cur.LopID END AS LopID,
        CASE WHEN @IsNhom = 1 THEN @Key ELSE NULL END AS NhomID,
        hsl_cur.SoDanhBo
    FROM dbo.tblHocSinh hs
    OUTER APPLY (
        SELECT TOP 1 hsl.LopID, hsl.SoDanhBo
        FROM dbo.tblHocSinhLop hsl
        INNER JOIN dbo.tblLop l
            ON l.LopID = hsl.LopID
           AND l.NienKhoa = hsl.NienKhoa
           AND l.NienKhoa = @NienKhoaID
        WHERE hsl.HocSinhID = hs.HocSinhID
          AND hsl.Enable = 1
          AND hsl.NienKhoa = @NienKhoaID
          AND (
                (@IsLop = 1 AND hsl.LopID = @Key)
             OR (@IsLop = 0 AND @IsNhom = 1)
          )
        ORDER BY hsl.SoDanhBo
    ) hsl_cur
    WHERE hs.TinhTrang = 0
      AND (
            -- @Key là LopID
            (@IsLop = 1 AND EXISTS (
                SELECT 1 FROM dbo.tblHocSinhLop hsl2
                INNER JOIN dbo.tblLop l2 ON l2.LopID = hsl2.LopID AND l2.NienKhoa = hsl2.NienKhoa AND l2.NienKhoa = @NienKhoaID
                WHERE hsl2.HocSinhID = hs.HocSinhID
                  AND hsl2.Enable = 1
                  AND hsl2.NienKhoa = @NienKhoaID
                  AND hsl2.LopID = @Key
            ))
            -- @Key là NhomID
         OR (@IsLop = 0 AND @IsNhom = 1 AND EXISTS (
                SELECT 1 FROM dbo.tblHocSinhNhom hsn2
                INNER JOIN dbo.tblNhom n2 ON n2.NhomID = hsn2.NhomID AND n2.NienKhoa = @NienKhoaID
                WHERE hsn2.HocSinhID = hs.HocSinhID
                  AND hsn2.Enable = 1
                  AND hsn2.NhomID = @Key
            ))
      )
    ORDER BY hsl_cur.SoDanhBo;

    -- === Bước 2: Chuẩn bị dữ liệu nguồn vào bảng tạm #GradebookData ===
    IF OBJECT_ID('tempdb..#GradebookData') IS NOT NULL DROP TABLE #GradebookData;

    SELECT
        qus.HocSinhID,
        qus.HoTen,
        qus.SoDanhBo,
        qus.LopID,
        qus.NhomID,
        atc.AssignToClassID,
        CASE
            WHEN s.Score IS NOT NULL THEN 
                '{"status":"GRADED", "score":' + CAST(s.Score AS VARCHAR(50)) + ', "submissionId":' + CAST(s.SubmissionID AS VARCHAR(50)) + '}'
            WHEN s.SubmissionID IS NOT NULL AND (s.SubmissionStatus IN (2, 3, 4) OR s.SubmissionTime IS NOT NULL) THEN 
                '{"status":"PENDING", "submissionId":' + CAST(s.SubmissionID AS VARCHAR(50)) + '}'
            ELSE 
                '{"status":"NOT_SUBMITTED"}'
        END AS ResultJSON
    INTO #GradebookData
    FROM #QueryUnitStudents qus -- Lấy danh sách học sinh đã chuẩn hóa
    CROSS JOIN dbo.tblEL_AssignToClass atc
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    LEFT JOIN dbo.tblEL_Submissions s ON qus.HocSinhID = s.HocSinhID AND atc.AssignToClassID = s.AssignToClassID
    WHERE mhl.LopNhomID = @LopID
      AND mhl.MonHocID = @MonHocID
      AND atc.IsDeleted = 0
      AND atc.NienKhoa = @NienKhoaID;

    -- === BẢNG 1: TRẢ VỀ DANH SÁCH BÀI TẬP (Header) ===
    SELECT DISTINCT
        atc.AssignToClassID,
        a.Title AS AssignmentTitle,
        atc.DueDate,
        atc.MaxScore
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblEL_Assignments a ON atc.AssignmentID = a.AssignmentID
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    WHERE mhl.LopNhomID = @LopID AND mhl.MonHocID = @MonHocID AND atc.IsDeleted = 0
      AND atc.NienKhoa = @NienKhoaID
    ORDER BY atc.DueDate;

    -- === BẢNG 2: TRẢ VỀ DỮ LIỆU ĐIỂM SỐ ĐÃ PIVOT ===
    SELECT @PivotColumns = STUFF(
        (
            SELECT DISTINCT ',' + QUOTENAME(CAST(AssignToClassID AS VARCHAR(8000)))
            FROM #GradebookData
            FOR XML PATH('')
        ), 1, 1, ''
    );

    IF @PivotColumns IS NULL
    BEGIN
        -- Nếu không có dữ liệu, trả về danh sách học sinh (bao gồm LopID/NhomID)
        SELECT HocSinhID, HoTen, SoDanhBo, LopID, NhomID
        FROM #QueryUnitStudents
        ORDER BY HoTen;
    END
    ELSE
    BEGIN
        SET @SqlStatement = N'
        SELECT
            HocSinhID,
            HoTen,
            SoDanhBo,
            LopID,
            NhomID,
            ' + @PivotColumns + '
        FROM #GradebookData
        PIVOT (
            MAX(ResultJSON)
            FOR AssignToClassID IN (' + @PivotColumns + ')
        ) AS PivotTable
        ORDER BY SoDanhBo, HoTen;';

        EXEC sp_executesql @SqlStatement;
    END

    -- === BẢNG 3: TRẢ VỀ DỮ LIỆU THỐNG KÊ CỘT ===
    SELECT
        s.AssignToClassID,
        AVG(s.Score) AS AverageScore
    FROM dbo.tblEL_Submissions s
    JOIN dbo.tblMonHocLop mhl ON s.AssignToClassID IN (SELECT AssignToClassID FROM dbo.tblEL_AssignToClass WHERE MonHocLopID = mhl.MonHocLopID)
    WHERE mhl.LopNhomID = @LopID AND mhl.MonHocID = @MonHocID AND s.Score IS NOT NULL
    GROUP BY s.AssignToClassID;

    -- Dọn dẹp
    IF OBJECT_ID('tempdb..#QueryUnitStudents') IS NOT NULL DROP TABLE #QueryUnitStudents;
    IF OBJECT_ID('tempdb..#GradebookData') IS NOT NULL DROP TABLE #GradebookData;
END;
