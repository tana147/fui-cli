CREATE PROC [dbo].[spAPI_HocSinhYKienThang_Get_By_LopID_Lop_NhanXetThangID]
    @LopID              INT,
    @Lop_NhanXetThangID INT,
    @NienKhoa           INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Raw AS (
        SELECT 
              ISNULL(hs_ykt.HocSinh_NhanXetThangID, 0)         AS HocSinh_NhanXetThangID
            , hsl.HSLopID
            , ISNULL(hs_ykt.Lop_NhanXetThangID, 0)             AS Lop_NhanXetThangID

            -- LuotXem: 1) có Parent_Comment; hoặc 2) Is_Viewed = 1 và KHÔNG có comment nào
            , CASE 
                WHEN (
                        norm.ParentCommentTrim IS NOT NULL
                        OR (ISNULL(nxt.Is_Viewed,0) = 1 AND norm.ParentCommentTrim IS NULL AND norm.YKienTrim IS NULL)
                     )
                     AND (hs_ykt.LuotXem IS NULL OR hs_ykt.LuotXem = 0)
                  THEN 1
                ELSE ISNULL(hs_ykt.LuotXem, 0)
              END                                              AS LuotXem

            , hs_ykt.TrangThai

            -- PHConfirm (giữ alias)
            , CASE 
                WHEN norm.ParentCommentTrim IS NOT NULL 
                     AND norm.YKienTrim IS NULL 
                     THEN nxt.ParentConfirmUser
                ELSE hs_ykt.PHConfirm
              END                                              AS PHConfirm

            -- Thời điểm raw để xếp hạng và format ra sau
            , CASE 
                WHEN norm.ParentCommentTrim IS NOT NULL 
                     AND hs_ykt.PHConfirmTime IS NULL THEN nxt.ParentConfirmTime
                ELSE hs_ykt.PHConfirmTime
              END                                              AS PHConfirmTimeRaw

            , hs.HocSinhID
            , hs.Ho
            , hs.Ten
            , hs.Ho + ' ' + hs.Ten                              AS HoTen
            , hs.NgaySinh
            , hs.Nu
            , hsl.SoDanhBo

            -- Từ tblNhanXetThang:
            , nxt.Is_Viewed
            , nxt.Parent_Comment

            -- Ý kiến PH hợp nhất (giữ alias)
            , COALESCE(norm.ParentCommentTrim, norm.YKienTrim)  AS YKienPhuHuynh
        FROM dbo.tblHocSinhLop AS hsl
        INNER JOIN dbo.tblLop AS l
            ON  l.LopID = hsl.LopID
            AND l.Enable = 1
            AND (@NienKhoa IS NULL OR l.NienKhoa = @NienKhoa)
            -- Ý kiến phụ huynh cũng phải cùng học sinh của đúng niên khóa.
            AND (@NienKhoa IS NULL OR hsl.NienKhoa = @NienKhoa)
        LEFT JOIN dbo.tblHocSinhYKienThang AS hs_ykt
            ON  hsl.HSLopID               = hs_ykt.HSLopID
            AND hs_ykt.Enable             = 1
            AND hs_ykt.Lop_NhanXetThangID = @Lop_NhanXetThangID
        LEFT JOIN dbo.tblNhanXetThang AS nxt
            ON  nxt.Lop_NhanXetThangID = @Lop_NhanXetThangID
            AND nxt.HocSinhID          = hsl.HocSinhID
        CROSS APPLY (
            SELECT 
                NULLIF(LTRIM(RTRIM(CAST(nxt.Parent_Comment   AS NVARCHAR(MAX)))),'') AS ParentCommentTrim,
                NULLIF(LTRIM(RTRIM(CAST(hs_ykt.YKienPhuHuynh AS NVARCHAR(MAX)))),'') AS YKienTrim
        ) AS norm
        INNER JOIN dbo.tblHocSinh AS hs
            ON  hs.HocSinhID = hsl.HocSinhID
            AND hs.TinhTrang = 0
        WHERE
            hsl.Enable = 1
            AND hsl.LopID = @LopID
    ),
    Ranked AS (
        SELECT R.*,
               ROW_NUMBER() OVER (
                   PARTITION BY R.HocSinhID
                   ORDER BY R.LuotXem DESC,
                            R.PHConfirmTimeRaw DESC,
                            R.HSLopID DESC
               ) AS rn
        FROM Raw AS R
    )
    SELECT 
          HocSinh_NhanXetThangID
        , HSLopID
        , Lop_NhanXetThangID
        , LuotXem
        , TrangThai
        , PHConfirm
        , FORMAT(PHConfirmTimeRaw, 'dd/MM/yyyy HH:mm:ss') AS PHConfirmTime
        , HocSinhID
        , Ho
        , Ten
        , HoTen
        , NgaySinh
        , Nu
        , SoDanhBo
        , Is_Viewed
        , Parent_Comment
        , YKienPhuHuynh
    FROM Ranked
    WHERE rn = 1
    ORDER BY SoDanhBo, Ten;
END
