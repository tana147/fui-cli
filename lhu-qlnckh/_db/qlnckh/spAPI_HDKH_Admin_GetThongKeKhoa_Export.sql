-- exec spAPI_HDKH_Admin_GetThongKeKhoa_Export 'KDP', 2026, 'GV0000611'
CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_GetThongKeKhoa_Export]
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

    Declare @AllDataInSource as table (
        ID int IDENTITY not NULL,
        DataSource varchar(50) not NULL,
        DataID int not null,
        DataValue nvarchar(250) not null
    )

    insert into @AllDataInSource
        (DataSource, DataID, DataValue)
                                                                SELECT 'DM_BacDaoTao', id, Tenbac
        FROM tblHDKH_DM_BacDaoTao
    UNION ALL
        SELECT 'DM_CapCuocThi', id, Tencap
        FROM tblHDKH_DM_CapCuocThi
    UNION ALL
        SELECT 'DM_CapDeTai', id, TenCapDeTai
        FROM tblHDKH_DM_CapDeTai
    UNION ALL
        SELECT 'DM_CapHoiThao', id, Tencap
        FROM tblHDKH_DM_CapHoiThao
    UNION ALL
        SELECT 'DM_DanhMucTapChi', id, TenDanhMuc
        FROM tblHDKH_DM_DanhMucTapChi
    UNION ALL
        SELECT 'DM_KetQuaGiai', id, TenGiai
        FROM tblHDKH_DM_KetQuaGiai
    UNION ALL
        SELECT 'DM_LoaiHinhPhanBien', id, Tenloaihinh
        FROM tblHDKH_DM_LoaiHinhPhanBien
    UNION ALL
        SELECT 'DM_NgonNgu', id, Tenngonngu
        FROM tblHDKH_DM_NgonNgu
    UNION ALL
        SELECT 'DM_NhiemVuHoiDong', id, Tennhiemvu
        FROM tblHDKH_DM_NhiemVuHoiDong
    UNION ALL
        SELECT 'DM_PhamVi', id, Tenphamvi
        FROM tblHDKH_DM_PhamVi
    UNION ALL
        SELECT 'DM_TheLoaiBienSoan', id, Tentheloai
        FROM tblHDKH_DM_TheLoaiBienSoan
    UNION ALL
        SELECT 'DM_TheLoaiSach', id, Tentheloai
        FROM tblHDKH_DM_TheLoaiSach
    UNION ALL
        SELECT 'DM_ThoiLuong', id, Tenthoiluong
        FROM tblHDKH_DM_ThoiLuong
    UNION ALL
        SELECT 'DM_VaiTro', id, Tenvaitro
        FROM tblHDKH_DM_VaiTro
    UNION ALL
        SELECT 'LoaiHinhSHTT', id, Tenloaihinh
        FROM tblHDKH_DM_LoaiHinhSHTT;

    SELECT
        form.FormID,
        nv.MaNV,
        nv.HoTen,
        sub.SubmissionID,
        STUFF((
        SELECT '\n ' + field.FieldLabel + ': ' + iif(field.FieldType <> 'SELECT', f.FieldValue, (select TOP 1 t.DataValue FROM @AllDataInSource t where t.DataSource = field.DataSource and t.DataID = TRY_CAST(f.FieldValue AS INT)))
        FROM tblHDKH_KeKhai_FieldValue f
            right join tblHDKH_Field_Definition field on f.FieldID = field.FieldID
        WHERE f.SubmissionID = sub.SubmissionID
            AND f.IsDeleted = 0
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 3, '') AS ThongTin
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
