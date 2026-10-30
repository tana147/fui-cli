CREATE PROCEDURE dbo.spAPI_HocSinhLop_ChuyenLop_Preview
    @Json_HocSinhID nvarchar(max),
    @LopMoiID varchar(10),
    @NienKhoa int
AS
BEGIN
    SET NOCOUNT ON;

    IF @NienKhoa IS NULL OR @NienKhoa = 0
    BEGIN
        RAISERROR(N'NienKhoa là bắt buộc khi rà soát chuyển lớp.', 16, 1);
        RETURN;
    END;

    IF ISJSON(@Json_HocSinhID) <> 1
    BEGIN
        RAISERROR(N'Danh sách HocSinhID không hợp lệ.', 16, 1);
        RETURN;
    END;

    DECLARE @TenLopMoi nvarchar(100);
    SELECT TOP (1) @TenLopMoi = TenLop
    FROM dbo.tblLop
    WHERE CONVERT(varchar(10), LopID) = @LopMoiID
      AND NienKhoa = @NienKhoa
      AND Enable = 1;

    IF @TenLopMoi IS NULL
    BEGIN
        RAISERROR(N'Lớp nhận không tồn tại hoặc đã ngừng sử dụng trong niên khóa này.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM OPENJSON(@Json_HocSinhID)
        WHERE TRY_CONVERT(int, [value]) IS NOT NULL
          AND TRY_CONVERT(int, [value]) > 0
    )
    BEGIN
        RAISERROR(N'Danh sách học sinh đang rà soát bị trống.', 16, 1);
        RETURN;
    END;

    ;WITH Selected AS (
        SELECT DISTINCT TRY_CONVERT(int, [value]) AS HocSinhID
        FROM OPENJSON(@Json_HocSinhID)
        WHERE TRY_CONVERT(int, [value]) IS NOT NULL
          AND TRY_CONVERT(int, [value]) > 0
    ),
    NewClass AS (
        SELECT LopID = @LopMoiID, TenLop = @TenLopMoi
    )
    SELECT
        selected.HocSinhID,
        HoTen = COALESCE(NULLIF(LTRIM(RTRIM(CONCAT(hs.Ho, N' ', hs.Ten))), N''), CONCAT(N'Học sinh ', selected.HocSinhID)),
        currentClass.HSLopID AS HSLopIDCu,
        currentClass.LopID AS LopCuID,
        oldClass.TenLop AS TenLopCu,
        newClass.LopID AS LopMoiID,
        newClass.TenLop AS TenLopMoi,
        SoLopDangHoc = currentClass.ActiveMembershipCount,
        IsChuyenLop = CONVERT(bit, CASE WHEN currentClass.LopID IS NOT NULL AND currentClass.LopID <> newClass.LopID THEN 1 ELSE 0 END),
        SoDiemLopCu = (
            SELECT COUNT(*)
            FROM dbo.tblKetQuaHocTap k
            WHERE k.HocSinhID = selected.HocSinhID
              AND k.NienKhoa = @NienKhoa
              AND k.Enable = 1
              AND k.LopID = currentClass.LopID
        ),
        SoDiemLopMoi = (
            SELECT COUNT(*)
            FROM dbo.tblKetQuaHocTap k
            WHERE k.HocSinhID = selected.HocSinhID
              AND k.NienKhoa = @NienKhoa
              AND k.Enable = 1
              AND k.LopID = newClass.LopID
        ),
        SoDiemNhomDangHoc = (
            SELECT COUNT(*)
            FROM dbo.tblKetQuaHocTap k
            INNER JOIN dbo.tblHocSinhNhom studyMembership
                ON CONVERT(varchar(50), studyMembership.NhomID) = k.LopID
               AND studyMembership.HocSinhID = selected.HocSinhID
               AND studyMembership.Enable = 1
            INNER JOIN dbo.tblNhom studyGroup
                ON studyGroup.NhomID = studyMembership.NhomID
               AND studyGroup.NienKhoa = @NienKhoa
               AND studyGroup.Enable = 1
            WHERE k.HocSinhID = selected.HocSinhID
              AND k.NienKhoa = @NienKhoa
              AND k.Enable = 1
        ),
        SoNhomDangHoc = (
            SELECT COUNT(*)
            FROM dbo.tblHocSinhNhom membership
            INNER JOIN dbo.tblNhom studyGroup
                ON studyGroup.NhomID = membership.NhomID
               AND studyGroup.NienKhoa = @NienKhoa
               AND studyGroup.Enable = 1
            WHERE membership.HocSinhID = selected.HocSinhID
              AND membership.Enable = 1
        ),
        SoNhomLopCu = (
            SELECT COUNT(*)
            FROM dbo.tblHocSinhNhom membership
            INNER JOIN dbo.tblNhom studyGroup
                ON studyGroup.NhomID = membership.NhomID
               AND studyGroup.NienKhoa = @NienKhoa
               AND studyGroup.Enable = 1
            WHERE membership.HocSinhID = selected.HocSinhID
              AND membership.Enable = 1
              AND CONVERT(varchar(10), membership.LopID) = currentClass.LopID
        ),
        SoBaiTapLopCu = (
            SELECT COUNT(DISTINCT atc.AssignToClassID)
            FROM dbo.tblMonHocLop mhl
            INNER JOIN dbo.tblEL_AssignToClass atc ON atc.MonHocLopID = mhl.MonHocLopID
            LEFT JOIN dbo.tblEL_Submissions sub
                ON sub.AssignToClassID = atc.AssignToClassID
               AND sub.HocSinhID = selected.HocSinhID
               AND sub.IsDeleted = 0
            WHERE mhl.LopNhomID = currentClass.LopID
              AND mhl.NienKhoa = @NienKhoa
              AND mhl.Enable = 1
              AND atc.IsDeleted = 0
              AND atc.Status IN (1, 2)
              AND (sub.SubmissionID IS NULL OR sub.SubmissionStatus < 2)
        ),
        SoBaiNopLopCu = (
            SELECT COUNT(DISTINCT sub.SubmissionID)
            FROM dbo.tblMonHocLop mhl
            INNER JOIN dbo.tblEL_AssignToClass atc ON atc.MonHocLopID = mhl.MonHocLopID
            INNER JOIN dbo.tblEL_Submissions sub
                ON sub.AssignToClassID = atc.AssignToClassID
               AND sub.HocSinhID = selected.HocSinhID
               AND sub.IsDeleted = 0
            WHERE mhl.LopNhomID = currentClass.LopID
              AND mhl.NienKhoa = @NienKhoa
              AND mhl.Enable = 1
              AND atc.IsDeleted = 0
        ),
        SoBaiGiaoTrucTiep = (
            SELECT COUNT(*)
            FROM dbo.tblEL_AssignToStudent ats
            WHERE ats.HocSinhID = selected.HocSinhID
              AND ats.NienKhoa = @NienKhoa
              AND ats.IsDeleted = 0
        ),
        SoKetQuaLMSLopCu = (
            SELECT COUNT(*)
            FROM dbo.tblEL_Analytics_QuestionResults result
            WHERE result.HocSinhID = selected.HocSinhID
              AND result.NienKhoa = @NienKhoa
              AND result.LopID = currentClass.LopID
              AND ISNULL(result.IsDeleted, 0) = 0
        ),
        SoNhanXetThangLopCu = (
            SELECT COUNT(*)
            FROM dbo.tblNhanXetThang nx
            INNER JOIN dbo.tblNhanXetThang_Lop nxLop ON nxLop.Lop_NhanXetThangID = nx.Lop_NhanXetThangID
            WHERE nx.HocSinhID = selected.HocSinhID
              AND nxLop.NienKhoa = @NienKhoa
              AND CONVERT(varchar(10), nxLop.LopID) = currentClass.LopID
              AND nx.Enable = 1
              AND ISNULL(nxLop.Enable, 1) = 1
        ),
        SoTheoDoiGVCNLopCu = (
            (SELECT COUNT(*) FROM dbo.tblSoGVCNTheoDoiRenLuyen x
             INNER JOIN dbo.tblSoGVCN b ON b.SoGVCNID = x.SoGVCNID
             INNER JOIN dbo.tblHocSinhLop m ON m.HSLopID = x.HSLopID
             WHERE m.HocSinhID = selected.HocSinhID AND m.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), m.LopID) = currentClass.LopID
               AND b.NienKhoa = @NienKhoa AND CONVERT(varchar(10), b.LopID) = currentClass.LopID AND x.Enable = 1)
            + (SELECT COUNT(*) FROM dbo.tblSoGVCNCanBoLop x
             INNER JOIN dbo.tblSoGVCN b ON b.SoGVCNID = x.SoGVCNID
             WHERE x.HocSinhID = selected.HocSinhID AND b.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), b.LopID) = currentClass.LopID AND x.Enable = 1)
            + (SELECT COUNT(*) FROM dbo.tblSoGVCNHuongNghiep x
             INNER JOIN dbo.tblSoGVCN b ON b.SoGVCNID = x.SoGVCNID
             WHERE x.HocSinhID = selected.HocSinhID AND b.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), b.LopID) = currentClass.LopID AND x.Enable = 1)
            + (SELECT COUNT(*) FROM dbo.tblSoGVCNHocSinhCanQuanTam x
             INNER JOIN dbo.tblSoGVCN b ON b.SoGVCNID = x.SoGVCNID
             WHERE x.HocSinhID = selected.HocSinhID AND b.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), b.LopID) = currentClass.LopID AND x.Enable = 1)
            + (SELECT COUNT(*) FROM dbo.tblSoGVCNHocSinhNhanXetThangLms x
             INNER JOIN dbo.tblSoGVCN b ON b.SoGVCNID = x.SoGVCNID
             WHERE x.HocSinhID = selected.HocSinhID AND b.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), b.LopID) = currentClass.LopID AND x.Enable = 1)
            + (SELECT COUNT(*) FROM dbo.tblSoGVCNNhanXetSoLienLac x
             INNER JOIN dbo.tblSoGVCN b ON b.SoGVCNID = x.SoGVCNID
             WHERE x.HSLopID IN (SELECT HSLopID FROM dbo.tblHocSinhLop WHERE HocSinhID = selected.HocSinhID AND NienKhoa = @NienKhoa AND CONVERT(varchar(10), LopID) = currentClass.LopID)
               AND b.NienKhoa = @NienKhoa AND CONVERT(varchar(10), b.LopID) = currentClass.LopID AND x.Enable = 1)
            + (SELECT COUNT(*) FROM dbo.tblSoGVCNTheoDoiPhuHuynhHop x
             INNER JOIN dbo.tblSoGVCN b ON b.SoGVCNID = x.SoGVCNID
             WHERE x.HocSinhID = selected.HocSinhID AND b.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), b.LopID) = currentClass.LopID AND x.Enable = 1)
            + (SELECT COUNT(*) FROM dbo.tblSoGVCNTheoDoiThanhTichHocSinh x
             INNER JOIN dbo.tblSoGVCN b ON b.SoGVCNID = x.SoGVCNID
             WHERE x.HocSinhID = selected.HocSinhID AND b.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), b.LopID) = currentClass.LopID AND x.Enable = 1)
            + (SELECT COUNT(*) FROM dbo.tblSoGVCNToNhomHocSinh x
             INNER JOIN dbo.tblSoGVCN b ON b.SoGVCNID = x.SoGVCNID
             WHERE x.HocSinhID = selected.HocSinhID AND b.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), b.LopID) = currentClass.LopID AND x.Enable = 1)
            + (SELECT COUNT(*) FROM dbo.tblSoGVCNBanDaiDienCMHS x
             INNER JOIN dbo.tblSoGVCN b ON b.SoGVCNID = x.SoGVCNID
             WHERE x.HocSinhID = selected.HocSinhID AND b.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), b.LopID) = currentClass.LopID AND x.Enable = 1)
        ),
        SoBaoNghi = (
            SELECT COUNT(*)
            FROM dbo.xxxxBaoNghiHocSinh absence
            WHERE TRY_CONVERT(int, absence.HocSinhID) = selected.HocSinhID
              AND CONVERT(varchar(50), absence.LopID) = currentClass.LopID
        ),
        SoDanhGiaKhenThuong = (
            (SELECT COUNT(*)
             FROM dbo.tblKhenThuong award
             WHERE award.HSLopID IN (
                 SELECT membership.HSLopID
                 FROM dbo.tblHocSinhLop membership
                 WHERE membership.HocSinhID = selected.HocSinhID
                   AND membership.NienKhoa = @NienKhoa
                   AND CONVERT(varchar(10), membership.LopID) = currentClass.LopID
             )
               AND award.NienKhoa = @NienKhoa
               AND ISNULL(award.Enable, 1) = 1)
            +
            (SELECT COUNT(*)
             FROM dbo.tblXetKetQuaRenLuyen conduct
             WHERE conduct.HocSinhID = selected.HocSinhID
               AND conduct.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), conduct.LopID) = currentClass.LopID)
            +
            (SELECT COUNT(*)
             FROM dbo.tblXetKetQuaHocBong scholarship
             WHERE scholarship.HocSinhID = selected.HocSinhID
               AND scholarship.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), scholarship.LopID) = currentClass.LopID)
        ),
        SoDiemTALopCu = (
            SELECT COUNT(*)
            FROM dbo.tbl_DiemTA_C2_C3 score
            WHERE score.HocSinhID = selected.HocSinhID
              AND CONVERT(varchar(10), score.LopID) = currentClass.LopID
        ),
        SoDiemBangKhacLopCu = (
            (SELECT COUNT(*) FROM dbo.tblBangDiemChiTiet_GK1_C1 score
             WHERE score.HocSinhID = selected.HocSinhID AND CONVERT(varchar(10), score.LopID) = currentClass.LopID)
            + (SELECT COUNT(*) FROM dbo.tblBangDiemChiTiet_CK1_C1 score
             WHERE score.HocSinhID = selected.HocSinhID AND CONVERT(varchar(10), score.LopID) = currentClass.LopID)
            + (SELECT COUNT(*) FROM dbo.tblDiem_HocSinh_Keo_Diem score
             WHERE score.HocSinhID = selected.HocSinhID AND CONVERT(varchar(10), score.LopID) = currentClass.LopID)
            + (SELECT COUNT(*) FROM dbo.tbl_QLDiem_Tam_C1 score
             WHERE TRY_CONVERT(int, score.HocSinhID) = selected.HocSinhID AND CONVERT(varchar(10), score.LopID) = currentClass.LopID)
            + (SELECT COUNT(*) FROM dbo.tbl_QLDiem_Tam_C2 score
             WHERE TRY_CONVERT(int, score.HocSinhID) = selected.HocSinhID AND CONVERT(varchar(10), score.LopID) = currentClass.LopID)
            + (SELECT COUNT(*) FROM dbo.tbl_QLDiem_Tam_C2_HK2 score
             WHERE TRY_CONVERT(int, score.HocSinhID) = selected.HocSinhID AND CONVERT(varchar(10), score.LopID) = currentClass.LopID)
            + (SELECT COUNT(*) FROM dbo.tbl_QLDiem_Tam_C3 score
             WHERE TRY_CONVERT(int, score.HocSinhID) = selected.HocSinhID AND CONVERT(varchar(10), score.LopID) = currentClass.LopID)
        ),
        SoYkienPhuHuynhLopCu = (
            (SELECT COUNT(*)
             FROM dbo.tblHocSinhYKienThang opinion
             INNER JOIN dbo.tblNhanXetThang_Lop nxLop
                 ON nxLop.Lop_NhanXetThangID = opinion.Lop_NhanXetThangID
             WHERE opinion.HSLopID = currentClass.HSLopID
               AND nxLop.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), nxLop.LopID) = currentClass.LopID
               AND opinion.Enable = 1
               AND ISNULL(nxLop.Enable, 1) = 1)
            +
            (SELECT COUNT(*)
             FROM dbo.tblHocSinhYKienThang_ManHinh opinion
             WHERE opinion.HocSinhID = selected.HocSinhID
               AND CONVERT(varchar(10), opinion.LopID) = currentClass.LopID
               AND opinion.Enable = 1)
        ),
        SoIeltsLopCu = (
            SELECT COUNT(*)
            FROM dbo.tblDanhSachHocSinh_CoIELTS ielts
            WHERE ielts.HocSinhID = selected.HocSinhID
              AND ielts.NienKhoa = @NienKhoa
              AND CONVERT(varchar(10), ielts.LopID) = currentClass.LopID
              AND ielts.Enable = 1
        ),
        SoBaoCaoCambridge = (
            SELECT COUNT(*)
            FROM dbo.tblBaoCao_Cambridge cambridge
            WHERE cambridge.HocSinhID = selected.HocSinhID
              AND cambridge.NienKhoa = @NienKhoa
        ),
        SoCuocThiLopCu = (
            SELECT COUNT(*)
            FROM dbo.tblTong_Hop_Du_Lieu_Cuoc_Thi contest
            WHERE contest.HocSinhID = selected.HocSinhID
              AND contest.NienKhoa = @NienKhoa
              AND CONVERT(varchar(10), contest.LopID) = currentClass.LopID
              AND contest.Enable = 1
        ),
        SoChungNhanLopCu = (
            (SELECT COUNT(*)
             FROM dbo.tblGiayKhenPhongTraoCert cert
             WHERE cert.HocSinhID = selected.HocSinhID
               AND cert.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), cert.LopID) = currentClass.LopID
               AND cert.Enable = 1)
            +
            (SELECT COUNT(*)
             FROM dbo.tblGiayKhenPhongTraoChiTiet cert
             WHERE cert.HocSinhID = selected.HocSinhID
               AND CONVERT(varchar(10), cert.LopID) = currentClass.LopID
               AND cert.Enable = 1)
            +
            (SELECT COUNT(*)
             FROM dbo.tblGiayKhenTapTheCert cert
             WHERE cert.HocSinhID = selected.HocSinhID
               AND cert.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), cert.LopID) = currentClass.LopID
               AND cert.Enable = 1)
            +
            (SELECT COUNT(*)
             FROM dbo.tblHocBongCert cert
             WHERE cert.HocSinhID = selected.HocSinhID
               AND cert.NienKhoa = @NienKhoa
               AND CONVERT(varchar(10), cert.LopID) = currentClass.LopID
               AND cert.Enable = 1)
        ),
        SoDangKyLaptopLopCu = (
            SELECT COUNT(*)
            FROM dbo.tblDangKyMangLaptop_HocSinh bookingStudent
            INNER JOIN dbo.tblDangKyMangLaptop booking ON booking.DangKyID = bookingStudent.DangKyID
            WHERE bookingStudent.HocSinhID = selected.HocSinhID
              AND bookingStudent.Enable = 1
              AND booking.NienKhoa = @NienKhoa
              AND CONVERT(varchar(10), booking.LopID) = currentClass.LopID
              AND booking.Enable = 1
        ),
        SoPhucKhaoLopCu = (
            SELECT COUNT(*)
            FROM dbo.tblPhucKhao appeal
            INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = appeal.MonHocLopID
            WHERE appeal.HocSinhID = selected.HocSinhID
              AND appeal.Enable = 1
              AND mhl.NienKhoa = @NienKhoa
              AND CONVERT(varchar(10), mhl.LopNhomID) = currentClass.LopID
        ),
        SoTuChoiLopCu = (
            SELECT COUNT(*)
            FROM dbo.tblTuChoi rejection
            INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = rejection.MonHocLopID
            WHERE rejection.HocSinhID = selected.HocSinhID
              AND rejection.Enable = 1
              AND mhl.NienKhoa = @NienKhoa
              AND CONVERT(varchar(10), rejection.LopID) = currentClass.LopID
        ),
        SoTienDoLMSCaNhan = (
            (SELECT COUNT(*)
             FROM dbo.tblEL_Element_Progress progress
             WHERE progress.HocSinhID = selected.HocSinhID)
            +
            (SELECT COUNT(*)
             FROM dbo.tblEL_Learning_Progress progress
             WHERE progress.HocSinhID = selected.HocSinhID
               AND ISNULL(progress.IsDeleted, 0) = 0)
        ),
        SoThanhTichLMSNamHoc = (
            SELECT COUNT(*)
            FROM dbo.tblEL_Achievements achievement
            WHERE achievement.HocSinhID = selected.HocSinhID
              AND achievement.NienKhoa = @NienKhoa
              AND ISNULL(achievement.IsDeleted, 0) = 0
        )
    FROM Selected selected
    LEFT JOIN dbo.tblHocSinh hs ON hs.HocSinhID = selected.HocSinhID
    CROSS JOIN NewClass newClass
    OUTER APPLY (
        SELECT TOP (1)
            membership.HSLopID,
            LopID = CONVERT(varchar(10), membership.LopID),
            ActiveMembershipCount = (
                SELECT COUNT(*)
                FROM dbo.tblHocSinhLop activeMembership
                WHERE activeMembership.HocSinhID = selected.HocSinhID
                  AND activeMembership.NienKhoa = @NienKhoa
                  AND activeMembership.Enable = 1
            )
        FROM dbo.tblHocSinhLop membership
        WHERE membership.HocSinhID = selected.HocSinhID
          AND membership.NienKhoa = @NienKhoa
        ORDER BY CASE WHEN membership.Enable = 1 THEN 0 ELSE 1 END,
                 ISNULL(membership.UpdateTime, membership.CreateTime) DESC,
                 membership.HSLopID DESC
    ) currentClass
    LEFT JOIN dbo.tblLop oldClass
        ON CONVERT(varchar(10), oldClass.LopID) = currentClass.LopID
       AND oldClass.NienKhoa = @NienKhoa
       AND oldClass.Enable = 1
    ORDER BY HoTen;
END


