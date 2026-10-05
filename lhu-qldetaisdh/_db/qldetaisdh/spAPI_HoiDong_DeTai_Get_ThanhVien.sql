
-- [dbo].[spAPI_HoiDong_DeTai_Get_ThanhVien] 37,9
CREATE PROC [dbo].[spAPI_HoiDong_DeTai_Get_ThanhVien]
    @NganhID INT,
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MsgError NVARCHAR(500);
    IF (@sys_SystemRight NOT IN (1,2,3,9))
    BEGIN 
        SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này ';
        RAISERROR(@MsgError, 16, 1);
        RETURN 0;
    END

    -- Tạo bảng tạm
    IF OBJECT_ID('tempdb..#TMPSTU') IS NOT NULL
        DROP TABLE #TMPSTU;

    CREATE TABLE #TMPSTU  (
        Student_ID INT,
        Ho_SV NVARCHAR(255),
        Ten_SV NVARCHAR(255),
        Lop_ID VARCHAR(9),
        Nganh_ID INT,
        Ten_Nganh NVARCHAR(255),
        Nien_Khoa VARCHAR(255),
        Email VARCHAR(300),
        PhoneNumber VARCHAR(20),
        Thesis_Name NVARCHAR(255),
        Thesises_Prof1 NVARCHAR(255),
        Thesises_Prof2 NVARCHAR(255)
    );

    -- Chèn dữ liệu vào bảng tạm (giữ nguyên logic gốc)
    INSERT INTO #TMPSTU
        (Student_ID, Ho_SV, Ten_SV, Lop_ID, Nganh_ID, Ten_Nganh, Email, PhoneNumber, Nien_Khoa, Thesis_Name, Thesises_Prof1, Thesises_Prof2)
    SELECT 
        d.StudentID AS Student_ID,
        HoSV AS Ho_SV,
        TenSV AS Ten_SV,
        LopID AS Lop_ID,
        NganhID AS Nganh_ID,
        TenNganh AS Ten_Nganh,
        f.Email, 
        f.PhoneNumber,
        NienKhoa AS Nien_Khoa,
        ThesisName AS Thesis_Name,
        ThesisesProf1 AS Thesises_Prof1,
        ThesisesProf2 AS Thesises_Prof2
    FROM flow_detail a 
    INNER JOIN task_detail b 
        ON a.task_id = b.task_id 
       AND a.task_detail_id = b.task_detail_id 
       AND b.fieldname = 'ThesisNameDefend'
    INNER JOIN flow c 
        ON a.flow_id = c.flow_id 
       AND c.use_yn = 1
    INNER JOIN Process p 
        ON c.Process_ID = p.Process_ID 
       AND p.Process_Action = 1
    INNER JOIN StudentInfo d 
        ON c.student_id = d.studentID
    LEFT JOIN (
        SELECT 
            c.Student_id, 
            MAX(CASE WHEN fieldname='ThesisNameDefend' THEN text_content ELSE ' ' END) ThesisName,
            MAX(CASE WHEN fieldname='Email' THEN text_content ELSE ' ' END) Email,
            MAX(CASE WHEN fieldname='PhoneNumber' THEN text_content ELSE ' ' END) PhoneNumber,
            MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE ' ' END) ThesisesProf1,
            MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE ' ' END) ThesisesProf2
        FROM flow_detail a 
        INNER JOIN task_detail b 
            ON a.task_id = b.task_id 
           AND a.task_detail_id = b.task_detail_id 
           AND b.fieldname IN ('ThesisNameDefend','Email', 'PhoneNumber', 'ThesisesProf1', 'ThesisesProf2') 
        INNER JOIN flow c 
            ON a.flow_id = c.flow_id  
           AND c.use_yn = 1
        INNER JOIN Process p 
            ON c.Process_ID = p.Process_ID 
           AND p.Process_Action = 1
        WHERE a.use_yn = 1
        GROUP BY c.student_id
    ) f 
        ON c.student_id = f.student_id
    WHERE a.flow_detail_status IN ('P','C')
      AND a.use_yn = 1

    UNION
    SELECT 
        d.StudentID AS Student_ID,
        HoSV AS Ho_SV,
        TenSV AS Ten_SV,
        LopID AS Lop_ID,
        NganhID AS Nganh_ID,
        TenNganh AS Ten_Nganh,
        f.Email, 
        f.PhoneNumber,
        NienKhoa AS Nien_Khoa,
        ThesisName AS Thesis_Name,
        f.ThesisesProf1 AS Thesises_Prof1,
        f.ThesisesProf2 AS Thesises_Prof2
    FROM flow_detail a 
    INNER JOIN task_detail b 
        ON a.task_id = b.task_id 
       AND a.task_detail_id = b.task_detail_id 
       AND b.fieldname = 'ThesisName'
    INNER JOIN flow c 
        ON a.flow_id = c.flow_id 
       AND c.use_yn = 1
    INNER JOIN Process p 
        ON c.Process_ID = p.Process_ID 
       AND p.Process_Action = 1
    INNER JOIN StudentInfo d 
        ON c.student_id = d.studentID 
       AND d.NganhID IN (102, 106)
    LEFT JOIN (
        SELECT 
            c.Student_id, 
            MAX(CASE WHEN fieldname='ThesisName' THEN text_content ELSE ' ' END) ThesisName,
            NULL Email,
            NULL PhoneNumber,
            MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE ' ' END) ThesisesProf1,
            MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE ' ' END) ThesisesProf2
        FROM flow_detail a 
        INNER JOIN task_detail b 
            ON a.task_id = b.task_id 
           AND a.task_detail_id = b.task_detail_id 
           AND b.fieldname IN ('ThesisName', 'ThesisesProf1','ThesisesProf2') 
        INNER JOIN flow c 
            ON a.flow_id = c.flow_id  
           AND c.use_yn = 1
        INNER JOIN Process p 
            ON c.Process_ID = p.Process_ID 
           AND p.Process_Action = 1
        WHERE a.use_yn = 1
        GROUP BY c.student_id
    ) f 
        ON c.student_id = f.student_id
    LEFT JOIN (
        SELECT 
            c.student_id, 
            a.text_content AS ThesisesProf1,
            c.Flow_Status AS Flow_Status,
            a.Flow_ID
        FROM flow_detail a
        INNER JOIN task_detail b 
            ON a.task_id = b.task_id 
           AND a.task_detail_id = b.task_detail_id
        INNER JOIN flow c 
            ON a.flow_id = c.flow_id 
           AND c.use_yn = 1
        WHERE b.fieldname = 'fileLyLichKhoaHoc' 
          AND a.use_yn = 1
    ) AS Prof1Data 
        ON d.studentID = Prof1Data.student_id
    WHERE Prof1Data.Flow_Status IN ('P','C')
      AND a.use_yn = 1;

    ------------------------------------------------------------------
    -- Chọn Decision "sau" (mới nhất) MỖI SINH VIÊN, rồi join ra TOÀN BỘ TV
    ------------------------------------------------------------------
    ;WITH DecisionsPerStudent AS (
        SELECT
            H.StudentID,
            H.Decision_ID,
            D.Decision_SoQD,
            D.Decision_NgayQD,
            D.Decision_ThangQD,
            D.Decision_NamQD,
            D.Decision_Status,
            TRY_CONVERT(date, CONCAT(
                RIGHT('0000' + CAST(D.Decision_NamQD   AS varchar(4)),4), '-',
                RIGHT('00'   + CAST(D.Decision_ThangQD AS varchar(2)),2), '-',
                RIGHT('00'   + CAST(D.Decision_NgayQD  AS varchar(2)),2)
            )) AS DecisionDate,
            ROW_NUMBER() OVER (
                PARTITION BY H.StudentID
                ORDER BY
                    CASE WHEN D.Decision_Status IN (1,2,3) THEN 0 ELSE 1 END,
                    TRY_CONVERT(date, CONCAT(
                        RIGHT('0000' + CAST(D.Decision_NamQD   AS varchar(4)),4), '-',
                        RIGHT('00'   + CAST(D.Decision_ThangQD AS varchar(2)),2), '-',
                        RIGHT('00'   + CAST(D.Decision_NgayQD  AS varchar(2)),2)
                    )) DESC,
                    H.Decision_ID DESC
            ) AS rn
        FROM HoiDong H
        INNER JOIN Decision D
            ON D.Decision_ID = H.Decision_ID
           AND D.Decision_Status <> 10
        -- KHÔNG join HoiDongThanhVien ở đây để tránh “lọc mất” các TV
    ),
    LatestDecision AS (
        SELECT *
        FROM DecisionsPerStudent
        WHERE rn = 1
    ),
    HoiDongTV_Chosen AS (
        -- Lấy TOÀN BỘ thành viên của Decision mới nhất vừa chọn
        SELECT
            H.HoiDongID,
            LD.Decision_ID,
            LD.Decision_SoQD,
            LD.Decision_NgayQD,
            LD.Decision_ThangQD,
            LD.Decision_NamQD,
            LD.Decision_Status,
            H.KetQuaHoiDong,
            H.NhanXet,
            H.DiemHoiDong,
            H.HoiDong_Status,
            H.ThoiGianBaoVe,
            H.StudentID,
            TV.GiangVienID,
            TV.HocViHocHam,
            TV.HoTenGiangVien,
            TV.ChucTrach
        FROM LatestDecision LD
        INNER JOIN HoiDong H
            ON H.StudentID = LD.StudentID
           AND H.Decision_ID = LD.Decision_ID
        INNER JOIN HoiDongThanhVien TV
            ON TV.HoiDongID = H.HoiDongID
           AND TV.Is_Xoa = 0
    )
    SELECT DISTINCT
        ROW_NUMBER() OVER (ORDER BY T.Student_ID) AS 'STT'
        , T.Student_ID 
        , T.Ho_SV 
        , T.Ten_SV 
        , T.Lop_ID 
        , T.Nganh_ID 
        , T.Ten_Nganh 
        , T.Nien_Khoa 
        , T.Email
        , T.PhoneNumber
        , T.Thesis_Name 
        , G1.GiangVienID AS GiangVienID1
        , T.Thesises_Prof1 
        , G2.GiangVienID AS GiangVienID2
        , T.Thesises_Prof2
        , C.Decision_ID
        , C.Decision_SoQD
        , C.Decision_NgayQD
        , C.Decision_ThangQD
        , C.Decision_NamQD
        , C.HoiDongID
        , C.KetQuaHoiDong
        , C.NhanXet
        , C.DiemHoiDong
        , C.HoiDong_Status
        , C.Decision_Status
        , C.ThoiGianBaoVe
        , C.GiangVienID AS ThanhVienHoiDong_ID
        , C.HocViHocHam AS ThanhVienHoDong_HocViHocHam
        , C.HoTenGiangVien AS ThanhVienHoiDong_HoTen
        , C.ChucTrach AS ThanhVienHoiDong_ChucTrach
    FROM #TMPSTU T
    LEFT JOIN HoiDongTV_Chosen C
        ON C.StudentID = T.Student_ID 
    LEFT JOIN GiangVien G1 
        ON T.Thesises_Prof1 = G1.HocViHocHam +'. ' + G1.HoTenGiangVien
       AND T.Nganh_ID = G1.NganhID 
        AND G1.Is_Xoa = 0
    LEFT JOIN GiangVien G2 
        ON T.Thesises_Prof2 = G2.HocViHocHam +'. ' + G2.HoTenGiangVien
       AND T.Nganh_ID = G2.NganhID 
       AND G2.Is_Xoa = 0
    WHERE (T.Nganh_ID = @NganhID) OR (@NganhID = 0);
END
