-- exec spAPI_HDKH_Admin_GetThongKeKhoa_Export_v2 'KDP', 2026, 'GV0000611'
CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_GetThongKeKhoa_Export_v2]
    @KhoaID VARCHAR(50),
    @NamHoc INT,
    @sys_userid char(9)
AS
BEGIN
    SET NOCOUNT ON;

    select NhanVienID, nv.HoTen, SoGioQuyDoi_CaNhan, SoGio_DaDuyet, DienGiaiCachTinh,
        case TrangThaiDuyet 
        when 'CHO_DUYET' then N'Chờ Duyệt'
        when 'KHOA_DA_DUYET' then N'Khoa Đã Duyệt'
        when 'KHOA_TU_CHOI' then N'Khoa Từ Chối'
    end as TenTrangThai
    FROM tblHDKH_KeKhai_KetQua_CaNhan kq
        inner join NhanVien nv on kq.NhanVienID = nv.MaNV
    where IsDeleted = 0
        and nv.MaDonVi = @KhoaID
        AND EXISTS (SELECT 1
        FROM dbo.tblHDKH_KeKhai_Submission S
        WHERE S.SubmissionID = kq.SubmissionID AND S.NamHoc = @NamHoc)
    ORDER by nv.MaNV

    exec spAPI_HDKH_Admin_GetThongKeKhoa @KhoaID, @NamHoc, @sys_userid = @sys_userid, @sys_rawData = ''

    select FormID, FormCode, FormTitle
    FROM tblHDKH_Form_Definition
    where IsDeleted = 0


    DECLARE @Field_Valid_Id as TABLE (
        FieldID int not NULL
    )
    INSERT INTO @Field_Valid_Id
    select FieldID
    FROM tblHDKH_Field_Definition
    where FieldLabel like N'%Tên%'
        and IsDeleted = 0
    order by FieldID asc

    SELECT
        form.FormID,
        nv.MaNV,
        nv.HoTen,
        sub.SubmissionID,
        STUFF((
        SELECT ', ' + f.FieldValue
        FROM tblHDKH_KeKhai_FieldValue f
        WHERE f.SubmissionID = sub.SubmissionID
            AND EXISTS (SELECT 1
            FROM @Field_Valid_Id tmp
            WHERE tmp.FieldID = f.FieldID)
            and f.IsDeleted = 0
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS GiaTri
    FROM tblHDKH_KeKhai_Submission sub
        INNER JOIN NhanVien nv ON nv.MaNV = sub.NhanVienID_KeKhai AND nv.MaDonVi = @KhoaID
        INNER JOIN tblHDKH_Form_Definition form ON form.FormID = sub.FormID
    WHERE sub.IsDeleted = 0
    GROUP BY 
    sub.SubmissionID,
    form.FormID, 
    nv.MaNV, 
    nv.HoTen
    ORDER by FormID
END;
