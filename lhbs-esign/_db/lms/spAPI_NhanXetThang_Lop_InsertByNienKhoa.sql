 CREATE PROC dbo.spAPI_NhanXetThang_Lop_InsertByNienKhoa
    @NienKhoa  INT,
    @Thang     TINYINT,        -- 1..12
    @Nam       SMALLINT,       -- 2024/2025...
    @Is_HienThiPhuHuynh BIT = 1,
    @CreateUser VARCHAR(50) = 'AUTO_JOB',
    @TinhTrang  TINYINT = 0    -- 0: mới tạo
AS
BEGIN
    SET NOCOUNT ON;

    -- Map tháng -> VI/EN/icon
    WITH MonthMap AS (
        SELECT *
        FROM (VALUES
             (1 ,N'Tháng Một'     ,N'January' ,N'/_cdn/lhbs-lms/icon_thang/icon_thang_1.png')
            ,(2 ,N'Tháng Hai'     ,N'February',N'/_cdn/lhbs-lms/icon_thang/icon_thang_2.png')
            ,(3 ,N'Tháng Ba'      ,N'March'   ,N'/_cdn/lhbs-lms/icon_thang/icon_thang_3.png')
            ,(4 ,N'Tháng Tư'      ,N'April'   ,N'/_cdn/lhbs-lms/icon_thang/icon_thang_4.png')
            ,(5 ,N'Tháng Năm'     ,N'May'     ,N'/_cdn/lhbs-lms/icon_thang/icon_thang_5.png')
            ,(6 ,N'Tháng Sáu'     ,N'June'    ,N'/_cdn/lhbs-lms/icon_thang/icon_thang_6.png')
            ,(7 ,N'Tháng Bảy'     ,N'July'    ,N'/_cdn/lhbs-lms/icon_thang/icon_thang_7.png')
            ,(8 ,N'Tháng Tám'     ,N'August'  ,N'/_cdn/lhbs-lms/icon_thang/icon_thang_8.png')
            ,(9 ,N'Tháng Chín'    ,N'September',N'/_cdn/lhbs-lms/icon_thang/icon_thang_9.png')
            ,(10,N'Tháng Mười'    ,N'October' ,N'/_cdn/lhbs-lms/icon_thang/icon_thang_10.png')
            ,(11,N'Tháng Mười Một',N'November',N'/_cdn/lhbs-lms/icon_thang/icon_thang_11.png')
            ,(12,N'Tháng Mười Hai',N'December',N'/_cdn/lhbs-lms/icon_thang/icon_thang_12.png')
        ) AS M(Thang, Text_Thang_VI, Text_Thang_EN, IconUrl)
        WHERE Thang = @Thang
    ),
    Lop AS (
        SELECT LopID
        FROM dbo.tblLop
        WHERE NienKhoa = @NienKhoa AND Enable = 1
    )
    INSERT INTO dbo.tblNhanXetThang_Lop
        ([LopID], [Thang], [Nam], [Text_Thang_VI], [Text_Thang_EN],
         [NienKhoa], [IconUrl], [TinhTrang], [Is_HienThiPhuHuynh],
         [ReasonReject], [Enable], [CreateUser], [CreateTime])
    SELECT
        L.LopID, @Thang, @Nam, M.Text_Thang_VI, M.Text_Thang_EN,
        @NienKhoa, M.IconUrl, @TinhTrang, @Is_HienThiPhuHuynh,
        NULL, 1, @CreateUser, GETDATE()
    FROM Lop L
    CROSS JOIN MonthMap M
    LEFT JOIN dbo.tblNhanXetThang_Lop T
        ON T.LopID = L.LopID
       AND T.Thang = @Thang
       AND T.Nam = @Nam
       AND T.NienKhoa = @NienKhoa
       AND T.Enable = 1
    WHERE T.LopID IS NULL;  -- chỉ thêm mới nếu chưa tồn tại

    SELECT InsertedCount = @@ROWCOUNT;
END
