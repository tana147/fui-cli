CREATE PROC [dbo].[spAPI_EL_Student_Achievement_Get]
    @HocSinhID INT,
    @NienKhoa INT
AS
BEGIN
    SELECT ach.AchievementID
         , ach.AchievementCode
         , ach_d.Title
         , ach_d.[Description]
         , ach_d.Color
         , ach_d.Icon
         , ach.PointsEarned
         , ach.HocSinhID
		 , ach_d.ImageUrl
         , hs.Ho + ' ' + hs.Ten AS HoTen
    FROM
           dbo.tblEL_Achievements                       ach
           INNER JOIN dbo.tblEL_Achievement_Definitions ach_d ON ach_d.AchievementCode = ach.AchievementCode
           INNER JOIN dbo.tblHocSinh                    hs ON hs.HocSinhID             = ach.HocSinhID
                                                          AND hs.TinhTrang             = 0
    WHERE
           ach.IsDeleted = 0
      AND  ach.HocSinhID  = @HocSinhID
      AND  ach.NienKhoa   = @NienKhoa;
END;

GRANT EXECUTE ON [dbo].[spAPI_EL_Student_Achievement_Get] TO [lmslhbs];
