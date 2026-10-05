-- [dbo].[spAPI_GetDetaiByGiaoVien]  N'PGS.TS. Nguyễn Thanh Lâm'
CREATE PROC [dbo].[spAPI_GetDetaiByGiaoVien] 
@GiaoVien nvarchar(200) 
AS
BEGIN
	
	declare @task_code_cur_ varchar(20)
	declare @task_status_cur varchar(20)

	declare @tbl_StudentCanMoi AS TABLE (studentid VARCHAR(9))
	insert into @tbl_StudentCanMoi(studentid)
	select a.student_id --, c.Task_Code, b.Flow_Status
			from process_student a 
					inner join flow b on a.student_id = b.student_id and a.process_id = b.process_id and b.use_yn =1
					inner join Tasks c on b.Task_ID = c.Task_ID
			where a.use_yn = 1 and c.Task_Code IN ('ThS03','ThSUD02') and b.Flow_Status = 'W'
			


	 declare @TenGiaoVien nvarchar(300);
	 set @TenGiaoVien= rtrim(ltrim(replace(replace(replace(replace(replace(@GiaoVien,'PGS.',''),'TS.',''),'GS.',''),'TSKH.',''),'DS.','')));

	
	--from giangvien a 
	--where  hotengiangvien=@TenGiaoVien
	;

	DECLARE @data as TABLE (studentid VARCHAR(9), lopId Varchar(9), HoSV nvarchar(300), TenSV nvarchar(200), NgaySinh varchar(10), SoDienThoai Varchar(20), Email nvarchar(500), TenNganh nvarchar(200), NienKhoa varchar(10), TenDeTai nvarchar(max), GVHD_1 nvarchar(200), GVHD_2 nvarchar(200))
	INSERT INTO @data(studentid, lopId, HoSV, TenSV, NgaySinh, SoDienThoai, Email, TenNganh, NienKhoa, TenDeTai, GVHD_1, GVHD_2)
	select b.studentid, lopId, HoSV, TenSV, NgaySinh, SoDienThoai, Email, TenNganh, NienKhoa, TenDeTai, GVHD_1, GVHD_2
	from (
			select a.student_id
				, max(case when d.fieldname ='ThesisNameSuggest'  then isnull(c.text_content,' ') else ' ' end) TenDeTai
				, max(case when d.fieldname ='ThesisesProf1' then isnull(c.text_content,' ') else ' ' end) GVHD_1
				, max(case when d.fieldname ='ThesisesProf2' then isnull(c.text_content,' ') else ' ' end) GVHD_2
			from process_student a inner join flow b on a.student_id = b.student_id and a.process_id = b.process_id and b.use_yn =1
								   inner join flow_detail c on b.flow_id = c.flow_id and c.text_content is not null
								   inner join task_detail d on c.task_detail_id = d.task_detail_id and d.fieldname in('ThesisNameSuggest','ThesisesProf1','ThesisesProf2')
			where a.use_yn = 1
			--and  a.student_id='923000002'
			--and case when d.fieldname in('ThesisesProf1','ThesisesProf2') then case when c.text_content like N'%'+@TenGiaoVien+N'%' then 1 else 0 end 
			--			else 1 end = 1
			group by a.student_id
		) a 
			inner join studentinfo b on a.student_id = b.studentid
			inner join @tbl_StudentCanMoi c on c.studentid = a.Student_ID
	where GVHD_1 like N'%'+@TenGiaoVien+N'%'  or GVHD_2 like N'%'+@TenGiaoVien+N'%'
	
	SELECT  1 GiangVienID, replace(@GiaoVien,@TenGiaoVien,'') HocHamHocVi, @TenGiaoVien HoTenGiangVien, N'Trường ĐH Lạc Hồng' CoQuanCongTac
	, STUFF((
            SELECT  ',' + UPPER(TenNganh)
            FROM (SELECT DISTINCT TenNganh FROM @Data) F
            FOR XML PATH('')
            ), 1, 1, '') as NganhGiangDay, 0 NganhID, 0 Khoa

	SELECT studentid
	, lopId
	, HoSV
	, TenSV
	, NgaySinh
	, ISNULL(SoDienThoai,'') SoDienThoai
	, ISNULL(Email,'') Email
	, TenNganh
	, NienKhoa
	, TenDeTai
	, GVHD_1
	, GVHD_2 FROM @data
END

