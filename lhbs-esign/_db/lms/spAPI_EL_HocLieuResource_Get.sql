
CREATE   PROCEDURE dbo.spAPI_EL_HocLieuResource_Get
    @ResourceType VARCHAR(20),
    @ResourceID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
        m.MappingID,
        m.ResourceType,
        m.ResourceID,
        m.HocLieuID,
        m.NoiDungID,
        hl.TenHocLieu,
        nd.TenNoiDung,
        nd.ParentID,
        nd.LoaiNoiDung
    FROM dbo.tblEL_HocLieuResourceMapping m
    INNER JOIN dbo.tblHocLieu_FP hl ON hl.HocLieuID = m.HocLieuID
        AND hl.Loai = 'HOC_LIEU' AND hl.Is_Xoa = 0
    INNER JOIN dbo.tblNoiDungHocLieu_FP nd ON nd.NoiDungID = m.NoiDungID
        AND nd.HocLieuID = m.HocLieuID
        AND nd.LoaiNoiDung IN ('CHUONG', 'BAI', 'NHOM_KY_NANG')
        AND nd.Is_Xoa = 0
    WHERE m.ResourceType = UPPER(@ResourceType)
      AND m.ResourceID = @ResourceID
      AND m.IsDeleted = 0;
END;
