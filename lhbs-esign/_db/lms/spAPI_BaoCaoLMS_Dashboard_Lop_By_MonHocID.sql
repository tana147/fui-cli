--[dbo].[spAPI_BaoCaoLMS_Dashboard_Lop_By_MonHocID] 53, 2025, '1'
CREATE PROC [dbo].[spAPI_BaoCaoLMS_Dashboard_Lop_By_MonHocID]
    @MonHocID INT
  , @NienKhoa INT
  , @SYS_USERID VARCHAR(9)
AS
BEGIN

    DECLARE @Bang_BaiTap TABLE
    (
        KhoiID                        INT
      , TenLop                        NVARCHAR(255)
      , LopID                         NVARCHAR(255)
      , MonHocID                      INT
      , Title                         NVARCHAR(200)
      , AssignToClassID               INT
      , AssignToStudentID             INT
      , NguoiGiao                     VARCHAR(9)
      , HoTenNguoiGiao                NVARCHAR(200)
      , ThoiGianTao                   DATETIME
      , SoLuongHocSinh                INT
      , SoLuongHocSinh_TreHan_ChuaLam INT
      , SoLuongHocSinh_DaNop          INT
	  , SoLuongHocSinh_ChuaNop			INT
	  , SoLuongHocSinh_DaCham			INT
	  , Tuan_HienThi                    NVARCHAR(100)
	  , MaxScore						DECIMAL(5,2)
    );
    INSERT INTO @Bang_BaiTap
     SELECT 
        l.KhoiID,
        l.TenLop,
        l.LopID,
        mhl.MonHocID,
        asm.Title,
        atc.AssignToClassID,
        NULL AS AssignToStudentID,
        atc.CreateUser AS NguoiGiao,
        gv.HoGV + ' ' + gv.TenGV AS HoTenNguoiGiao,
        atc.CreateTime AS ThoiGianTao,
       
        -- Tổng số học sinh trong lớp
        (
            SELECT COUNT(*)
            FROM dbo.tblHocSinhLop hsl
            INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID AND hs.TinhTrang = 0
            WHERE hsl.Enable = 1
                AND hsl.LopID = mhl.LopNhomID
                AND hsl.NienKhoa = @NienKhoa
        ) AS SoLuongHocSinh,
        
        -- Đếm học sinh trễ hạn
        COUNT(DISTINCT CASE
            WHEN (s.IsOverDue = 1 OR atc.DueDate < GETDATE())
                AND s.SubmissionStatus NOT IN (2, 4) 
            THEN s.HocSinhID
            ELSE NULL
        END) AS SoLuongHocSinh_TreHan_ChuaLam,
        
        -- Đếm học sinh đã nộp
        COUNT(DISTINCT CASE 
            WHEN s.SubmissionStatus IN (2,3)
            THEN s.HocSinhID 
            ELSE NULL 
        END) AS SoLuongHocSinh_DaNop,
		 -- Đếm học sinh chưa nộp
		COUNT(DISTINCT CASE 
            WHEN s.SubmissionStatus < 2 
            THEN s.HocSinhID 
            ELSE NULL 
        END) AS SoLuongHocSinh_ChuaNop,
		 -- Đếm học sinh chưa chấm
		COUNT(DISTINCT CASE 
            WHEN s.SubmissionStatus = 4 
            THEN s.HocSinhID 
            ELSE NULL 
        END) AS SoLuongHocSinh_DaCham,
		 N'Tuần ' + CAST(th.Tuan AS VARCHAR(2)) 
			+ N' - Tháng ' + CAST(th.ThangHoc as varchar(2))
			+ N' - (' + FORMAT(NgayBatDau ,'dd/MM/yyyy') 
			+ N' - ' + FORMAT(NgayKetThuc,'dd/MM/yyyy') + ')'  AS Tuan_HienThi
        ,atc.MaxScore
    FROM dbo.tblEL_AssignToClass atc
    LEFT JOIN dbo.tblGiaoVien gv 
        ON gv.GiaoVienID = atc.CreateUser
    INNER JOIN dbo.tblEL_Assignments asm 
        ON asm.AssignmentID = atc.AssignmentID
        AND asm.IsDeleted = 0
        AND asm.MonHocID = @MonHocID
        AND ISNULL(asm.IsDev, 0) = 0
    INNER JOIN dbo.tblMonHocLop mhl 
        ON mhl.MonHocLopID = atc.MonHocLopID
        AND mhl.MonHocID = @MonHocID
        AND mhl.Enable = 1
    INNER JOIN dbo.tblLop l 
        ON l.LopID = mhl.LopNhomID
        AND l.NienKhoa = @NienKhoa
        AND l.Enable = 1
    LEFT JOIN dbo.tblEL_Submissions s  -- ĐỔI THÀNH LEFT JOIN
        ON s.AssignToClassID = atc.AssignToClassID
        AND s.IsDeleted = 0
    INNER JOIN dbo.tblTuanHocTap th ON th.TuanHocID = asm.TuanHocID 
    WHERE atc.IsDeleted = 0
    
    GROUP BY
        l.KhoiID,
        l.TenLop,
        l.LopID,
        mhl.MonHocID,
        asm.Title,
        mhl.LopNhomID,
        atc.AssignToClassID,
        atc.CreateUser,
        atc.CreateTime,
        gv.HoGV,
        gv.TenGV,
		N'Tuần ' + CAST(th.Tuan AS VARCHAR(2)) 
			+ N' - Tháng ' + CAST(th.ThangHoc as varchar(2))
			+ N' - (' + FORMAT(NgayBatDau ,'dd/MM/yyyy') 
			+ N' - ' + FORMAT(NgayKetThuc,'dd/MM/yyyy') + ')',
			atc.MaxScore
        
    ORDER BY l.TenLop;

    --Lấy danh sách bài tập sắp hết hạn làm
    SELECT mhl.LopNhomID        AS LopID
         , l.TenLop
         , s.HocSinhID
         , hs.Ho + ' ' + hs.Ten AS HoTen
         , asm.Title
         , atc.DueDate
         , s.SubmissionStatus
    FROM
           dbo.tblEL_Submissions              s
           INNER JOIN dbo.tblEL_AssignToClass atc ON atc.AssignToClassID = s.AssignToClassID
                                                 AND atc.IsDeleted       = 0
           INNER JOIN dbo.tblEL_Assignments   asm ON asm.AssignmentID    = atc.AssignmentID
                                                 AND asm.IsDeleted       = 0
                                                 AND asm.MonHocID        = @MonHocID
												 AND ISNULL(asm.IsDev, 0) = 0
           INNER JOIN dbo.tblMonHocLop        mhl ON mhl.MonHocLopID     = atc.MonHocLopID
                                                 AND mhl.Enable          = 1
                                                 AND mhl.NienKhoa        = @NienKhoa
                                                 AND mhl.MonHocID        = @MonHocID
           INNER JOIN dbo.tblLop              l ON l.LopID               = mhl.LopNhomID
                                               AND l.Enable              = 1
                                               AND l.NienKhoa            = @NienKhoa
           INNER JOIN dbo.tblHocSinh          hs ON hs.HocSinhID         = s.HocSinhID
                                                AND hs.TinhTrang         = 0
    WHERE
           s.IsDeleted = 0
      AND
           (
               s.IsOverDue  = 1
          OR   atc.DueDate  < GETDATE()
           )
      AND  s.SubmissionStatus NOT IN (2, 4)
      AND  mhl.LopNhomID IN
           (
               SELECT LopID
               FROM
                      @Bang_BaiTap
           )
    ORDER BY
           l.TenLop
         , Ten;

    --Lấy danh sách bài tập theo môn
    SELECT *
    FROM
           @Bang_BaiTap
    ORDER BY
           TenLop;
END;
