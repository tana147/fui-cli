CREATE PROC [dbo].[spAPI_PhucKhaoDiem_Get]
    @MonHocLopID    INT
  , @List_HocSinhID NVARCHAR(1000)
AS
BEGIN
    DECLARE @Table_HocSinhID TABLE
    (
        HocSinhID INT
    );

    INSERT INTO @Table_HocSinhID
    (
        HocSinhID
    )
    SELECT [value] AS HocSinhID
    FROM
           STRING_SPLIT(@List_HocSinhID, ',') AS value;

    SELECT hs.HocSinhID
         , hs.Ho + ' ' + hs.Ten AS HoTen
         , pk.PhucKhaoID
         , pk.MonHocLopID
         , pk.CotDiemID
         , pk.KetQuaBanDau
         , pk.PhucKhao_Lan1
         , pk.PhucKhao_Lan2
         , pk.PhucKhao_Lan3
         , pk.PhucKhao_Lan4
         , pk.PhucKhao_Lan5
         , pk.LyDoPhucKhao_Lan1
         , pk.LyDoPhucKhao_Lan2
         , pk.LyDoPhucKhao_Lan3
         , pk.LyDoPhucKhao_Lan4
         , pk.LyDoPhucKhao_Lan5
    FROM
           dbo.tblHocSinh        hs
           LEFT JOIN tblPhucKhao pk ON pk.HocSinhID   = hs.HocSinhID
                                   AND pk.Enable      = 1
                                   AND pk.MonHocLopID = @MonHocLopID
    WHERE
           hs.HocSinhID IN
           (
               SELECT HocSinhID
               FROM
                      @Table_HocSinhID
           );
END;

--spAPI_PhucKhaoDiem_Get 6588, '21000133,24000168'