
CREATE PROC [dbo].[spAPI_GetALLGiangVienHuongDan] -- 0,0
@Nganh_ID INT,
@HeDaoTao INT
AS
BEGIN
	select  case when seq =1 then GVHD_1 when seq=2 then GVHD_2 else ' 'end GVHD
		from (
				select flow_id
				, max(case when d.fieldname ='ThesisesProf1' then isnull(c.text_content,' ') else ' ' end) GVHD_1
				, max(case when d.fieldname ='ThesisesProf2' then isnull(c.text_content,' ') else ' ' end) GVHD_2
				from flow_detail c 
					inner join task_detail d on c.task_detail_id = d.task_detail_id and d.fieldname in( 'ThesisesProf1','ThesisesProf2')
				group by flow_id
		) a inner join (select 1 seq union select 2 seq) b on 1=1
		group by case when seq =1 then GVHD_1 when seq=2 then GVHD_2 else ' 'end
		having case when seq =1 then GVHD_1 when seq=2 then GVHD_2 else ' 'end<>' '
		order by GVHD

END

