CREATE PROCEDURE [dbo].[spAPI_AnPham_LoaiAnPham_Dev_Get_All]
AS
    BEGIN
        SET NOCOUNT ON;
        SELECT
            ap.LoaiAnPhamID,
            ap.TenLoaiAnPham,
            (
            SELECT
                aps.LoaiSubAnPhamID,
                aps.TenLoaiSubAnPham,
                (
                SELECT
                    tc.DanhMucLoaiTapChiID,
                    COALESCE(tc.TenLoaiDanhMucTapChi, tc.TenVietTatLoaiDanhMucTapChi) AS TenLoaiDanhMucTapChi
                FROM dbo.LoaiDanhMucTapChi tc
                WHERE tc.LoaiSubAnPhamID = aps.LoaiSubAnPhamID
                      AND tc.Is_Xoa      = 0
                ORDER BY tc.Sort ASC
                FOR JSON AUTO
                ) AS sub
            FROM dbo.AnPham_Loai_Sub aps
            WHERE aps.LoaiAnPhamID = ap.LoaiAnPhamID
                  AND aps.Is_Xoa   = 0
            ORDER BY aps.Sort ASC
            FOR JSON AUTO
            ) AS sub
        FROM dbo.AnPham_Loai ap
        WHERE Is_Xoa = 0
        ORDER BY ap.Sort ASC;
    END;
