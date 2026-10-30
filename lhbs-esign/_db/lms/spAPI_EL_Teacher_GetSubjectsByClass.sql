CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetSubjectsByClass]
    @sys_UserID VARCHAR(9)
  , @LopID      VARCHAR(100) -- Đây là LopID hoặc NhomID do người dùng chọn
  , @HocKi      INT
  , @NienKhoa   INT
AS
BEGIN
    SET NOCOUNT ON;

    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    DECLARE @NienKhoa_HienTai INT = @NienKhoa;
    IF (@NienKhoa_HienTai IS NULL OR @NienKhoa_HienTai = 0)
        SET @NienKhoa_HienTai = dbo.fn_GetNienKhoa_HienTai();

    -- Lấy danh sách các môn học mà giáo viên (@sys_UserID) phụ trách
    -- hoặc được phân quyền chấm bài / chia sẻ tài nguyên cho Lớp hoặc Nhóm (@LopID)

    SELECT DISTINCT
           t.MonHocID
         , t.MonHocName
    FROM
    (
        -- 1. tblGiaoVienLop (phân công giảng dạy chính khóa)
        SELECT DISTINCT
               gvl.MonHocID
             , mh.MonHocName
        FROM
               dbo.tblGiaoVienLop gvl
               JOIN dbo.tblMonHoc mh ON gvl.MonHocID = mh.MonHocID
        WHERE
               gvl.GiaoVienID = @sys_UserID
          AND  gvl.LopID       = @LopID
          AND  gvl.NienKhoa    = @NienKhoa_HienTai
          AND  gvl.Enable      = 1
          AND  (@HocKi IS NULL OR @HocKi = 0 OR gvl.HocKy = @HocKi)
          AND  EXISTS
        (
            SELECT 1 FROM dbo.tblLop l WHERE l.LopID = @LopID AND l.NienKhoa = @NienKhoa_HienTai
            UNION
            SELECT 1 FROM dbo.tblNhom n WHERE n.NhomID = @LopID AND n.NienKhoa = @NienKhoa_HienTai
        )

        UNION

        -- 2. tblEL_GiaoVienLop (phân công giảng dạy E-Learning)
        SELECT DISTINCT
               gvl.MonHocID
             , mh.MonHocName
        FROM
               dbo.tblEL_GiaoVienLop gvl
               JOIN dbo.tblMonHoc    mh ON gvl.MonHocID = mh.MonHocID
        WHERE
               gvl.GiaoVienID = @sys_UserID
          AND  gvl.LopID       = @LopID
          AND  gvl.NienKhoa    = @NienKhoa_HienTai
          AND  gvl.Enable      = 1
          AND  (@HocKi IS NULL OR @HocKi = 0 OR gvl.HocKy = @HocKi)
          AND  EXISTS
        (
            SELECT 1 FROM dbo.tblLop l WHERE l.LopID = @LopID AND l.NienKhoa = @NienKhoa_HienTai
            UNION
            SELECT 1 FROM dbo.tblNhom n WHERE n.NhomID = @LopID AND n.NienKhoa = @NienKhoa_HienTai
        )

        UNION

        -- 3. tblEL_Resoucre_TeacherPermissions (phân quyền chấm bài / chia sẻ tài nguyên theo môn)
        SELECT DISTINCT
               rtp.MonHocID
             , mh.MonHocName
        FROM
               dbo.tblEL_Resoucre_TeacherPermissions rtp
               JOIN dbo.tblMonHoc                    mh  ON rtp.MonHocID   = mh.MonHocID
               JOIN dbo.tblMonHocLop                 mhl ON mhl.LopNhomID  = @LopID
                                                        AND mhl.MonHocID   = rtp.MonHocID
                                                        AND mhl.NienKhoa   = @NienKhoa_HienTai
                                                        AND mhl.Enable     = 1
        WHERE
               rtp.Enable = 1
          AND  (rtp.GiaoVienID = @sys_UserID OR rtp.CreateUser = @sys_UserID)
          -- Chỉ quyền SUBJECT mở rộng theo môn; quyền theo từng bài được xử lý ở nhánh 4.
          AND  rtp.PermissionScope = 'SUBJECT'
          -- Không để quyền của niên khóa cũ làm xuất hiện môn ở lớp hiện tại.
          AND  (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa_HienTai)

        UNION

        -- 4. tblEL_Resoucre_TeacherPermissions theo AssignToClassID cụ thể
        SELECT DISTINCT
               ISNULL(a.MonHocID, mhl.MonHocID) AS MonHocID
             , mh.MonHocName
        FROM
               dbo.tblEL_Resoucre_TeacherPermissions rtp
               JOIN dbo.tblEL_AssignToClass          atc ON atc.AssignToClassID = rtp.AssignToClassID
                                                        AND atc.IsDeleted       = 0
               JOIN dbo.tblMonHocLop                 mhl ON mhl.MonHocLopID     = atc.MonHocLopID
                                                        AND mhl.LopNhomID       = @LopID
                                                        AND mhl.NienKhoa        = @NienKhoa_HienTai
               JOIN dbo.tblEL_Assignments           a   ON a.AssignmentID       = atc.ResourceID
               JOIN dbo.tblMonHoc                    mh  ON mh.MonHocID         = ISNULL(a.MonHocID, mhl.MonHocID)
        WHERE
               rtp.Enable = 1
          AND  (rtp.GiaoVienID = @sys_UserID OR rtp.CreateUser = @sys_UserID)

        UNION

        -- 5. Bài tập do chính giáo viên này tạo và giao cho lớp
        SELECT DISTINCT
               ISNULL(a.MonHocID, mhl.MonHocID) AS MonHocID
             , mh.MonHocName
        FROM
               dbo.tblEL_AssignToClass atc
               JOIN dbo.tblMonHocLop   mhl ON atc.MonHocLopID = mhl.MonHocLopID
                                          AND mhl.LopNhomID   = @LopID
                                          AND mhl.NienKhoa    = @NienKhoa_HienTai
               JOIN dbo.tblEL_Assignments a ON a.AssignmentID = atc.ResourceID
               JOIN dbo.tblMonHoc mh ON mh.MonHocID = ISNULL(a.MonHocID, mhl.MonHocID)
        WHERE
               atc.CreateUser = @sys_UserID
          AND  atc.IsDeleted  = 0
          AND  atc.ResourceType = 'ASSIGNMENT'
    ) AS t
    ORDER BY
        t.MonHocName;

END;
