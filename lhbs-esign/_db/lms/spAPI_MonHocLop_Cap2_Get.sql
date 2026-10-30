
CREATE proc [dbo].[spAPI_MonHocLop_Cap2_Get]
AS
begin
	SELECT 
        mhl.LopNhomID AS LopID, 
        l.TenLop, 
        mh.MonHocCode, 
        mh.MonHocName 
    FROM tblMonHocLop mhl 
	    inner join tblLop l on l.LopID = mhl.LopNhomID AND l.NienKhoa = mhl.NienKhoa
	    inner join tblMonHoc mh on mh.MonHocID = mhl.MonHocID
	where mh.CapID <> 1
	and l.CapID <> 1
    order by l.TenLop, mh.MonHocName
end
