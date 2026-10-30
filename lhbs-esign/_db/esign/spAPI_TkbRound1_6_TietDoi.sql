CREATE PROCEDURE spAPI_TkbRound1_6_TietDoi
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @MaxSecs INT = 600,
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-13 (theo de xuat nguoi dung, sau khi phat hien qua RunID 1269: 22/62 nhom con ket sau
    -- Round 2+4 la mon tiet doi ENG2/STEM/GDQP du VAN CON slot rong hop le cho ca GV lan lop — nguyen
    -- nhan Round 2 xep TUNG GV mot theo do khan hiem co the "an" mat 1 nua cap slot lien tiep truoc khi
    -- den luot GV can tiet doi). Round 1.6: giai GOP toan bo nhu cau MON TIET DOI (BatBuocXepDoi=1)
    -- cho khoi 1-9 (cap 1+2) NGAY SAU Round 1.5 (khoi 10-12), TRUOC Round 2 — dung nguyen ly "giai phan
    -- rang buoc chat nhat (can 2 slot lien tiep) truoc khi ban co con trong nhat", giong het ly do
    -- Round 1.5 tach rieng cum tach AV khoi 10-12. Round 2 sau do se tu dong chi con xu ly phan tiet
    -- don con lai (PCGDLoc cua spAPI_TkbXepDoKhanHiem da tu loai nhung gi da xep qua daKhoa/SoTietDaXep).
    EXEC spAPI_TkbChayAuto
        @Khoi = '01,02,03,04,05,06,07,08,09',
        @HocKy = @HocKy,
        @MaxSecs = @MaxSecs,
        @TuanHienTai = @TuanHienTai,
        @RunIDDangXay = @RunID,
        @ChiMonDoi = 1,
        @KhongChoSkip = 0,
        @sys_UserID = @sys_UserID;
END
