
CREATE PROC [dbo].[spAPI_SDH_Get_Student_FlowStatus] -- 0, 1
@Nganh_ID INT,
@NienKhoa NVARCHAR(7),
@Process_Action INT,
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	DECLARE @tbl AS TABLE(Student_ID VARCHAR(9)
						, Student_Name NVARCHAR(100)
						, Class_ID VARCHAR(10)
						, Nganh_ID INT
						, Student_Major NVARCHAR(100)
						, Student_Level NVARCHAR(20)
						, Student_Year	VARCHAR(10)
						, Task_ID INT
						, Task_Name NVARCHAR(500)
						, Flow_ID INT
						, Seq INT
						, Flow_Status VARCHAR(5))
	INSERT INTO @tbl(Student_ID , Student_Name , Class_ID, Nganh_ID, Student_Major, Student_Level, Student_Year, Task_ID, Task_Name, Flow_ID, Seq, Flow_Status)
	SELECT A.Student_ID
		, HoSV+' '+TenSV 
		, LopID 
		, B.NganhID AS Nganh_ID
		, TenNganh 
		, HeDaoTao 
		, NienKhoa 
		, D.TASK_ID
		, E.task_name
		, D.Flow_ID
		, D.Seq
		, D.Flow_Status
	FROM Process_Student A 
			INNER JOIN StudentInfo B ON A.Student_ID = B.StudentID
			INNER JOIN Process C ON C.Process_ID = A.Process_ID AND C.Process_Action = @Process_Action 
			INNER JOIN Flow D ON D.Process_ID = C.Process_ID AND D.Student_ID = A.Student_ID  AND d.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Tasks E ON E.Task_ID = D.Task_ID
	WHERE Flow_Status ='P' AND A.use_yn = 1  AND ( B.NganhID = @Nganh_ID OR @Nganh_ID = 0) AND (@NienKhoa = '0' OR @NienKhoa = B.NienKhoa)

	-----------------------------
	DECLARE @TaskID_ChinhSua_NC INT
	DECLARE @TaskID_ChinhSua_UD INT

	SELECT
		@TaskID_ChinhSua_NC = MAX(CASE WHEN Task_Code = 'ThS06' THEN Task_ID END),
		@TaskID_ChinhSua_UD = MAX(CASE WHEN Task_Code = 'ThSUD06' THEN Task_ID END)
	FROM Tasks
	WHERE Task_Code IN ('ThS06', 'ThSUD06')

	DECLARE @TempTable AS TABLE
	(
		Student_ID VARCHAR(9)
		, TenNgoaiNguDauRa NVARCHAR(200)
		, VanBangChungChiDauRa NVARCHAR(200)
		, ThoiGianCapDauRa VARCHAR(10)
		, DiaChiLienHe NVARCHAR(500)
		, ChucVu NVARCHAR(250)
		, DonViCongTac NVARCHAR (500)
		, DiemHoiDong FLOAT
	)

	INSERT @TempTable
	(
		Student_ID
		, TenNgoaiNguDauRa
		, VanBangChungChiDauRa
		, ThoiGianCapDauRa
		, DiaChiLienHe
		, ChucVu
		, DonViCongTac
		, DiemHoiDong
	)
	SELECT DISTINCT
			si.StudentID
		 , TenNgoaiNguDauRa
		 , VanBangChungChiDauRa
		 , NgayCapNgoaiNguDauRa AS ThoiGianCapDauRa
		 , DiaChiLienHe
		 , ChucVu
		 , DonViCongTac
		 , hd.DiemHoiDong
	FROM Flow_Detail fd
	INNER JOIN Task_Detail tb ON fd.Task_ID = tb.Task_ID
		AND fd.Task_Detail_ID = tb.Task_Detail_ID
	INNER JOIN Flow fl ON fd.Flow_ID = fl.Flow_ID 
		AND fl.use_yn = 1 
		AND fd.Flow_Detail_Status IN ('C')
	INNER JOIN StudentInfo si ON si.StudentID = fl.Student_ID
	INNER JOIN HoiDong hd ON hd.StudentID = si.StudentID AND hd.Is_Xoa = 0 AND hd.DiemHoiDong IS NOT NULL AND hd.DiemHoiDong <> ''
	--INNER JOIN Decision de ON de.Decision_ID = hd.Decision_ID
	LEFT JOIN (SELECT c.Student_id
			, MAX(CASE WHEN fieldname='TenNgoaiNguDauRa' THEN text_content ELSE '' END) TenNgoaiNguDauRa
			, MAX(CASE WHEN fieldname='VanBangChungChiDauRa' THEN text_content ELSE '' END) VanBangChungChiDauRa
			, MAX(CASE WHEN fieldname='NgayCapNgoaiNguDauRa' THEN text_content ELSE '' END) NgayCapNgoaiNguDauRa
			, MAX(CASE WHEN fieldname='DiaChiLienHe' THEN text_content ELSE '' END) DiaChiLienHe
			, MAX(CASE WHEN fieldname='ChucVu' THEN text_content ELSE '' END) ChucVu
			, MAX(CASE WHEN fieldname='DonViCongTac' THEN text_content ELSE '' END) DonViCongTac
		FROM Flow_Detail a 
		INNER JOIN Task_Detail b ON a.Task_ID = b.Task_ID 
			AND a.Task_Detail_ID = b.Task_Detail_ID 
			AND b.FieldName IN('TenNgoaiNguDauRa'
								,'VanBangChungChiDauRa'
								,'NgayCapNgoaiNguDauRa'
								,'DiaChiLienHe'
								,'ChucVu'
								,'DonViCongTac') 
		 INNER JOIN Flow c on a.Flow_ID = c.Flow_ID  and c.use_yn = 1
			WHERE   a.use_yn = 1
			GROUP BY c.Student_ID
		) f ON fl.Student_ID = f.Student_ID
	WHERE fd.use_yn = 1
	AND ( si.NganhID = @Nganh_ID OR @Nganh_ID = 0)
	-----------------------------
	SELECT ROW_NUMBER() OVER (ORDER BY t2.Student_Year DESC, t2.Class_ID, t2.Student_ID, t2.Seq, t2.Task_ID) AS STT
	, t2.Student_ID 
	, t2.Student_Name 
	--------
	, si.HoSV
	, si.TenSV
	, si.GioiTinh
	, si.NgaySinh
	, si.NienKhoa
	, si.SoDienThoai
	, si.Email
	, tb.DiaChiLienHe
	, tb.ChucVu
	, tb.DonViCongtac
	, si.Loai_NgoaiNgu_DauVao
	, si.NganhID AS Nganh_ID
	, si.TenNganh
	, tb.VanBangChungChiDauRa
	, tb.ThoiGianCapDauRa
	, tb.DiemHoiDong
	, tb.TenNgoaiNguDauRa
	---------
	, t2.Class_ID
	, t2.Student_Major
	, t2.Student_Level
	, t2.Student_Year
	, t2.Task_ID
	, t2.Task_Name
	, t2.Flow_ID
	, t2.Flow_Status
	FROM @tbl t2
	INNER JOIN StudentInfo si ON si.StudentID = t2.Student_ID AND (si.IsXuLyHocVu IN (0) OR si.IsXuLyHocVu IS NULL)
	LEFT JOIN @TempTable tb ON tb.Student_ID = t2.Student_ID
	ORDER BY STT
END

