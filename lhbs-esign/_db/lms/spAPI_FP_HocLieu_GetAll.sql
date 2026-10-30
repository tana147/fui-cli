CREATE PROCEDURE [dbo].[spAPI_FP_HocLieu_GetAll]
    @PageNumber INT,
    @PageSize INT,
    @KhoiID INT,
    @MonHocID INT,
    @BoSachID INT,
    @Loai VARCHAR(50),
    @NgayBatDau DATE,
    @NgayKetThuc DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        hl.HocLieuID, hl.TenHocLieu, hl.KhoiID, hl.HocKy, hl.TinhTrang,
        bs.TenBoSach, mh.MonHocName AS TenMonHoc,
        hl.ThumbnailURL,
        hl.ThumbnailURLs,
        hl.MonHocID,
        hl.BoSachID,
        hl.Loai,
        hl.CreateUser,
        hl.CreateTime,
        hl.UpdateUser,
        hl.UpdateTime,
        COUNT(*) OVER () AS TotalRecords
    FROM
        dbo.tblHocLieu_FP hl
    LEFT JOIN dbo.tblBoSach_FP bs ON hl.BoSachID = bs.BoSachID
    LEFT JOIN dbo.tblMonHoc mh ON hl.MonHocID = mh.MonHocID
    WHERE
        hl.Is_Xoa = 0
        AND (@Loai IS NULL OR hl.Loai = @Loai OR hl.Loai IS NULL)
        AND (ISNULL(@KhoiID, 0) = 0 OR hl.KhoiID = @KhoiID)
        AND (ISNULL(@MonHocID, 0) = 0 OR hl.MonHocID = @MonHocID)
        AND (ISNULL(@BoSachID, 0) = 0 OR hl.BoSachID = @BoSachID)
    ORDER BY
        hl.UpdateTime DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END