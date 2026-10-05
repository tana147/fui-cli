CREATE PROC [dbo].[spAPI_RPT_Process_Summarry]
@NienKhoa VARCHAR(8)
AS
BEGIN
	--cây toàn bộ các ngành
	 with TREE_TASK as(
			select TASK_PARENT, a.TASK_ID, SEQ,c.task_name from TASK_TASK a inner join tasks c on a.task_id=c.task_id where TASK_PARENT = 1
			union all
			select a.TASK_PARENT, a.TASK_ID, a.SEQ,  c.task_name
			from TASK_TASK a inner join TREE_TASK b on a.TASK_PARENT = b.TASK_ID
							 inner join tasks c on a.task_id=c.task_id
			)
	select NienKhoa, HeDaoTaoID, HeDaoTao, process_description, a.process_id, a.task_begin,
		d.task_id, task_name, d.seq, count(1) total,
		sum(case when flow_status='W' then 1 else 0 end) W_Process, 
		sum(case when flow_status='P' then 1 else 0 end) P_Process,
		sum(case when flow_status='C' then 1 else 0 end) C_Process
	from process_student a inner join studentInfo b on a.student_id = b.studentid  and HedaotaoId=9 -- and nienkhoa ='2022-02'
						   inner join process c on a.process_id = c.process_id
						   left join tree_task d on a.task_begin = d.task_parent
						   left join flow e on a.student_id = e.student_id and d.task_id = e.task_id
	where a.process_id = 1 and process_student_status <>'X' and b.NienKhoa = @NienKhoa
	group by NienKhoa, HeDaoTaoID, HeDaoTao, process_description, a.process_id, a.task_begin,
		d.task_id, task_name, d.seq
		;

	--cây tổng theo từng ngành

	with TREE_TASK as(
			select TASK_PARENT, a.TASK_ID, SEQ,c.task_name from TASK_TASK a inner join tasks c on a.task_id=c.task_id where TASK_PARENT = 1
			union all
			select a.TASK_PARENT, a.TASK_ID, a.SEQ,  c.task_name
			from TASK_TASK a inner join TREE_TASK b on a.TASK_PARENT = b.TASK_ID
							 inner join tasks c on a.task_id=c.task_id
			)
	select NienKhoa, HeDaoTaoID, HeDaoTao, process_description, a.process_id, a.task_begin,
		d.task_id, task_name, d.seq, count(1) total,
		sum(case when   NganhID=102 then 1 else 0 end) NNA_TOTAL, 
		sum(case when flow_status='W' and NganhID=102 then 1 else 0 end) NNA_W_Process, 
		sum(case when flow_status='P' and NganhID=102 then 1 else 0 end) NNA_P_Process,
		sum(case when flow_status='C' and NganhID=102 then 1 else 0 end) NNA_C_Process,
		sum(case when   NganhID=37 then 1 else 0 end) CNTT_TOTAL, 
		sum(case when flow_status='W' and NganhID=37 then 1 else 0 end) CNTT_W_Process, 
		sum(case when flow_status='P' and NganhID=37 then 1 else 0 end) CNTT_P_Process,
		sum(case when flow_status='C' and NganhID=37 then 1 else 0 end) CNTT_C_Process,
		sum(case when   NganhID=38 then 1 else 0 end) QTKD_TOTAL, 
		sum(case when flow_status='W' and NganhID=38 then 1 else 0 end) QTKD_W_Process, 
		sum(case when flow_status='P' and NganhID=38 then 1 else 0 end) QTKD_P_Process,
		sum(case when flow_status='C' and NganhID=38 then 1 else 0 end) QTKD_C_Process,
		sum(case when   NganhID=39 then 1 else 0 end) KT_TOTAL, 
		sum(case when flow_status='W' and NganhID=39 then 1 else 0 end) KT_W_Process, 
		sum(case when flow_status='P' and NganhID=39 then 1 else 0 end) KT_P_Process,
		sum(case when flow_status='C' and NganhID=39 then 1 else 0 end) KT_C_Process,
		sum(case when   NganhID=40 then 1 else 0 end) TCNH_TOTAL, 
		sum(case when flow_status='W' and NganhID=40 then 1 else 0 end) TCNH_W_Process, 
		sum(case when flow_status='P' and NganhID=40 then 1 else 0 end) TCNH_P_Process,
		sum(case when flow_status='C' and NganhID=40 then 1 else 0 end) TCNH_C_Process,
		sum(case when   NganhID=42 then 1 else 0 end) KTCT_TOTAL, 
		sum(case when flow_status='W' and NganhID=42 then 1 else 0 end) KTCT_W_Process, 
		sum(case when flow_status='P' and NganhID=42 then 1 else 0 end) KTCT_P_Process,
		sum(case when flow_status='C' and NganhID=42 then 1 else 0 end) KTCT_C_Process
	from process_student a inner join studentInfo b on a.student_id = b.studentid  and HedaotaoId=9 --and nienkhoa ='2022-02'
						   inner join process c on a.process_id = c.process_id
						   left join tree_task d on a.task_begin = d.task_parent
						   left join flow e on a.student_id = e.student_id and d.task_id = e.task_id
	where a.process_id = 1 and process_student_status <>'X' and b.NienKhoa = @NienKhoa
	group by NienKhoa, HeDaoTaoID, HeDaoTao, process_description, a.process_id, a.task_begin,
		d.task_id, task_name, d.seq
		;

	--cây theo chi tiết ngành
	with TREE_TASK as(
			select TASK_PARENT, a.TASK_ID, SEQ,c.task_name from TASK_TASK a inner join tasks c on a.task_id=c.task_id where TASK_PARENT = 1
			union all
			select a.TASK_PARENT, a.TASK_ID, a.SEQ,  c.task_name
			from TASK_TASK a inner join TREE_TASK b on a.TASK_PARENT = b.TASK_ID
							 inner join tasks c on a.task_id=c.task_id
			)
	select NienKhoa, HeDaoTaoID, HeDaoTao, process_description, KhoaID, NganhID, TenNganh, a.process_id, a.task_begin,
		d.task_id, task_name, d.seq, count(1) total,
		sum(case when flow_status='W' then 1 else 0 end) W_Process, 
		sum(case when flow_status='P' then 1 else 0 end) P_Process,
		sum(case when flow_status='C' then 1 else 0 end) C_Process
	from process_student a inner join studentInfo b on a.student_id = b.studentid  and HedaotaoId=9 --and nienkhoa ='2022-02'
						   inner join process c on a.process_id = c.process_id
						   left join tree_task d on a.task_begin = d.task_parent
						   left join flow e on a.student_id = e.student_id and d.task_id = e.task_id
	where a.process_id = 1 and process_student_status <>'X' and b.NienKhoa = @NienKhoa
	group by NienKhoa, HeDaoTaoID, HeDaoTao, process_description, KhoaID, NganhID, TenNganh, a.process_id, a.task_begin,
		d.task_id, task_name, d.seq
		;
END