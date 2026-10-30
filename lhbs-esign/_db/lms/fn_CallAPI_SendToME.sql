CREATE FUNCTION dbo.fn_CallAPI_SendToME(@ThongBao_ID INT)
RETURNS nvarchar(max)
AS
BEGIN
DECLARE @HocSinhID varchar(9);
DECLARE @TemplateContent NVARCHAR(MAX);
    ;WITH TB AS
    (
        SELECT tb.ThongBaoID
             ,  ISNULL( tb.SubmissionID, tb.ResourceID) as SubmissionID
             -- Nếu môn học NULL → hiện: 'Không có môn học'
             , ISNULL(mh.TenMonHoc_HienThi, N'Không có môn học')         AS TenMonHoc_HienThi
             -- Nếu Title NULL → hiện: 'Không có tiêu đề'
             , ISNULL(asm.Title, N'Không có tiêu đề')                    AS Title
             , tb.Is_DaXem
             , tb.NguoiXem
             , tb.ThoiGianXem
             , tb.NguoiNhan
             , tb.ThoiGianNhan
             , tb_t.TemplateContent
             , tb_t_t.TypeTitle
             , tb_t_t.Color
             , tb_t_t.Icon
             , hs.HocSinhID
             , hs.Ho + ' ' + hs.Ten                                      AS HoTen
             , l.TenLop
             , FORMAT(TRY_CONVERT(DATE, hs.NgaySinh, 103), 'dd/MM/yyyy') AS NgaySinh
             , hs.Nu
             , ISNULL(atc.DueDate,ats.DueDate) as Duedate
             , tb_t.ThongBao_TypeID
			 , s.Score
             , CONCAT(gv.HoGV,' ', gv.TenGV) as HoTenGV
             , atc.AssignToClassID
             , s.SubmissionTime
        FROM
               dbo.tblEL_ThongBao                          tb
               INNER JOIN dbo.tblEL_ThongBao_Template      tb_t ON tb_t.ThongBao_TemplateID         = tb.ThongBao_TemplateID
                                                               AND tb_t.IsDeleted                   = 0
               INNER JOIN dbo.tblEL_ThongBao_Template_Type tb_t_t ON tb_t_t.ThongBao_TypeID         = tb_t.ThongBao_TypeID
               INNER JOIN dbo.tblHocSinh                   hs ON CONVERT(VARCHAR(50), hs.HocSinhID) = tb.NguoiNhan
               INNER JOIN dbo.tblHocSinhLop                hsl ON hsl.HocSinhID                     = hs.HocSinhID
               INNER JOIN dbo.tblLop                       l ON l.LopID                             = hsl.LopID
                                                            AND l.NienKhoa                          = dbo.fn_GetNienKhoa_HienTai()
                                                            AND l.Enable                            = 1
               AND hsl.NienKhoa = l.NienKhoa
        LEFT JOIN dbo.tblEL_Submissions             s ON s.SubmissionID                      = ISNULL(tb.SubmissionID,tb.ResourceID)
                                                            AND s.IsDeleted                         = 0
               LEFT JOIN dbo.tblEL_AssignToClass           atc ON atc.AssignToClassID               = s.AssignToClassID
                                                              AND atc.IsDeleted                     = 0
               LEFT JOIN dbo.tblEL_AssignToStudent          ats ON ats.AssignToStudentID              = s.AssignToStudentID
                                                              AND ats.IsDeleted                     = 0
               LEFT JOIN dbo.tblEL_Assignments             asm ON (asm.AssignmentID                  = atc.AssignmentID OR asm.AssignmentID = ats.AssignmentID)
                                                              AND asm.IsDeleted                     = 0
               LEFT JOIN dbo.tblGiaoVien gv on gv.GiaoVienID = ISNULL(atc.CreateUser,ats.CreateUser)
               LEFT JOIN dbo.tblMonHoc                     mh ON mh.MonHocID                        = asm.MonHocID
                                                             AND mh.Enable                          = 1
        WHERE
               ISNULL(tb.IsDeleted, 0) = 0
          AND  tb.ThongBaoID            = @ThongBao_ID
    )
    --------------------------------------------------------------------------------
    -- 2) Thay thế template param
    --------------------------------------------------------------------------------
 SELECT 
    @HocSinhID = CAST(tb.NguoiNhan as varchar(9)) ,
    @TemplateContent =  REPLACE( REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        TemplateContent,
                                        '@HoTenGV', HoTenGV
                                    ),
                                    '@TenLop', TenLop
                                ),
                                '@Title', Title
                            ),
                            '@TenMonHoc_HienThi', TenMonHoc_HienThi
                        ),
                        '@NgaySinh', NgaySinh
                    ),
                '@DueDate', ISNULL(CONVERT(VARCHAR(20), DueDate, 103), '')
            ),
            '@Score', ISNULL(CAST(Score AS VARCHAR(20)), '')
        ),
        '@CreateDate', ISNULL(CONVERT(VARCHAR(20), SubmissionTime, 103), '')
    ),'@HoTen',HoTen)
FROM TB
ORDER BY ThongBaoID DESC;

     --Bước 1 – Khởi tạo upload (initiate session)
    DECLARE @HEADER NVARCHAR(MAX) = CONCAT('Authorization: Bearer ', '');
    DECLARE @BODY NVARCHAR(MAX)= N'{
       "HocSinhID": "'+CAST(@HocSinhID as varchar(9))+N'",
       "NoiDung": "'+CAST(@TemplateContent as nvarchar(max))+N'"
    }'
    --DECLARE @Response NVARCHAR(MAX) = dbo.httpAPI('POST', N'https://tapi.lhbs.vn/student/LMS_SendMessageToME', @HEADER, @BODY);
    RETURN @BODY
END