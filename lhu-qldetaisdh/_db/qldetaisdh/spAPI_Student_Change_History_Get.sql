CREATE PROC [dbo].[spAPI_Student_Change_History_Get]
@Student_ID VARCHAR(20)
AS
BEGIN
    SELECT 
        ps.Process_Stu_ID,
        ps.Process_ID,
        ps.Process_Student_Status,
        ps.Created_At,
        MAX(CASE WHEN td.FieldName = 'ThesisNameNew' OR td.Task_Detail_ID = 122 THEN fd.Text_Content END) AS ThesisNameNew,
        MAX(CASE WHEN td.FieldName = 'ThesisesProf1New' OR td.Task_Detail_ID = 123 THEN fd.Text_Content END) AS ThesisesProf1New,
        MAX(CASE WHEN td.FieldName = 'ThesisesProf2New' OR td.Task_Detail_ID = 124 THEN fd.Text_Content END) AS ThesisesProf2New,
        MAX(CASE WHEN td.Task_Detail_ID IN (11, 129, 255) OR td.Task_Detail_Type IN ('FILE', 'FILEVIEW') THEN fd.File_Name END) AS QD_FileName,
        MAX(CASE WHEN td.Task_Detail_ID IN (11, 129, 255) OR td.Task_Detail_Type IN ('FILE', 'FILEVIEW') THEN fd.File_URL END) AS QD_FileURL,
        MAX(CASE WHEN td.Task_Detail_ID IN (12, 130, 256) THEN fd.Text_Content END) AS QD_SoQD,
        COALESCE(
            MAX(CASE WHEN fd.File_Type IN ('1', '2', '3') THEN fd.File_Type END),
            CASE 
                WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL 
                 AND MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '3'
                WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL THEN '1'
                WHEN MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '2'
                ELSE '1'
            END
        ) AS LoaiDieuChinh,
        CASE 
            WHEN COALESCE(
                MAX(CASE WHEN fd.File_Type IN ('1', '2', '3') THEN fd.File_Type END),
                CASE 
                    WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL 
                     AND MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '3'
                    WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL THEN '1'
                    WHEN MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '2'
                    ELSE '1'
                END
            ) = '1' THEN N'File Quyết định đổi/điều chỉnh tên đề tài'
            WHEN COALESCE(
                MAX(CASE WHEN fd.File_Type IN ('1', '2', '3') THEN fd.File_Type END),
                CASE 
                    WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL 
                     AND MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '3'
                    WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL THEN '1'
                    WHEN MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '2'
                    ELSE '1'
                END
            ) = '2' THEN N'File Quyết định thay đổi GVHD'
            WHEN COALESCE(
                MAX(CASE WHEN fd.File_Type IN ('1', '2', '3') THEN fd.File_Type END),
                CASE 
                    WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL 
                     AND MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '3'
                    WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL THEN '1'
                    WHEN MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '2'
                    ELSE '1'
                END
            ) = '3' THEN N'File Quyết định đổi tên đề tài và thay đổi GVHD'
            ELSE N'File Quyết định đổi/điều chỉnh đề tài'
        END AS Description_QD_File,
        CASE 
            WHEN COALESCE(
                MAX(CASE WHEN fd.File_Type IN ('1', '2', '3') THEN fd.File_Type END),
                CASE 
                    WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL 
                     AND MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '3'
                    WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL THEN '1'
                    WHEN MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '2'
                    ELSE '1'
                END
            ) = '1' THEN N'Số quyết định đổi/điều chỉnh tên đề tài'
            WHEN COALESCE(
                MAX(CASE WHEN fd.File_Type IN ('1', '2', '3') THEN fd.File_Type END),
                CASE 
                    WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL 
                     AND MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '3'
                    WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL THEN '1'
                    WHEN MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '2'
                    ELSE '1'
                END
            ) = '2' THEN N'Số quyết định thay đổi GVHD'
            WHEN COALESCE(
                MAX(CASE WHEN fd.File_Type IN ('1', '2', '3') THEN fd.File_Type END),
                CASE 
                    WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL 
                     AND MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '3'
                    WHEN MAX(CASE WHEN td.Task_Detail_ID = 122 THEN fd.Text_Content END) IS NOT NULL THEN '1'
                    WHEN MAX(CASE WHEN td.Task_Detail_ID IN (123, 124) THEN fd.Text_Content END) IS NOT NULL THEN '2'
                    ELSE '1'
                END
            ) = '3' THEN N'Số quyết định đổi tên đề tài và thay đổi GVHD'
            ELSE N'Số quyết định đổi/điều chỉnh đề tài'
        END AS Description_QD_No
    FROM Process_Student ps
    JOIN Flow f ON ps.Process_Stu_ID = f.Process_Student_ID
    JOIN Flow_Detail fd ON f.Flow_ID = fd.Flow_ID
    JOIN Task_Detail td ON fd.Task_Detail_ID = td.Task_Detail_ID
    WHERE ps.Student_ID = @Student_ID 
      AND ps.Process_ID IN (2, 5)
      AND ps.Process_Student_Status NOT IN ('W', 'P')
    GROUP BY ps.Process_Stu_ID, ps.Process_ID, ps.Process_Student_Status, ps.Created_At
    HAVING MAX(CASE WHEN td.Task_Detail_ID IN (11, 129, 255) OR td.Task_Detail_Type IN ('FILE', 'FILEVIEW') THEN fd.File_Name END) IS NOT NULL
        OR MAX(CASE WHEN td.Task_Detail_ID IN (12, 130, 256) THEN fd.Text_Content END) IS NOT NULL
    ORDER BY ps.Created_At ASC;
END;
