CREATE PROC [dbo].[spAPI_NhanXetThang_Copy]
    @Lop_NhanXetThangID      INT
  , @Lop_NhanXetThangID_Copy INT
  , @SYS_USERID              VARCHAR(9)
AS
BEGIN

    DECLARE @Table TABLE
    (
        Lop_NhanXetThangID       INT
      , HSLopID                  INT
      , HocSinhID                INT
      , NoiDungKienThuc_HTML     NVARCHAR(2000)
      , NoiDungNangLuc_HTML      NVARCHAR(2000)
      , NoiDungHoatDongKhac_HTML NVARCHAR(2000)
      , NoiDungToan_HTML         NVARCHAR(2000)
      , NoiDungTiengViet_HTML    NVARCHAR(2000)
      , NoiDungMonHocKhac_HTML   NVARCHAR(2000)
      , NhanXetCuoiNam_HTML      NVARCHAR(2000)
      , DiemToan                 INT
      , SoSao_Toan               INT
      , NhanXetToan_HTML         NVARCHAR(4000)
      , DiemTiengViet            INT
      , SoSao_TiengViet          INT
      , NhanXetTiengViet_HTML    NVARCHAR(4000)
      , NhanXetMonHocKhac_HTML   NVARCHAR(4000)
      , HoatDongGiaoDucKhac_HTML NVARCHAR(4000)
      , PhamChatNangLuc_HTML     NVARCHAR(4000)
    );
    INSERT INTO @Table
    (
        Lop_NhanXetThangID
      , HSLopID
      , HocSinhID
      , NoiDungKienThuc_HTML
      , NoiDungNangLuc_HTML
      , NoiDungHoatDongKhac_HTML
      , NoiDungToan_HTML
      , NoiDungTiengViet_HTML
      , NoiDungMonHocKhac_HTML
      , NhanXetCuoiNam_HTML
      , DiemToan
      , SoSao_Toan
      , NhanXetToan_HTML
      , DiemTiengViet
      , SoSao_TiengViet
      , NhanXetTiengViet_HTML
      , NhanXetMonHocKhac_HTML
      , HoatDongGiaoDucKhac_HTML
      , PhamChatNangLuc_HTML
    )
    SELECT Lop_NhanXetThangID
         , HSLopID
         , HocSinhID
         , NoiDungKienThuc_HTML
         , NoiDungNangLuc_HTML
         , NoiDungHoatDongKhac_HTML
         , NoiDungToan_HTML
         , NoiDungTiengViet_HTML
         , NoiDungMonHocKhac_HTML
         , NhanXetCuoiNam_HTML
         , DiemToan
         , SoSao_Toan
         , NhanXetToan_HTML
         , DiemTiengViet
         , SoSao_TiengViet
         , NhanXetTiengViet_HTML
         , NhanXetMonHocKhac_HTML
         , HoatDongGiaoDucKhac_HTML
         , PhamChatNangLuc_HTML
    FROM
           dbo.tblNhanXetThang
    WHERE
           Lop_NhanXetThangID = @Lop_NhanXetThangID;

    INSERT INTO dbo.tblNhanXetThang
    (
        Lop_NhanXetThangID
      , HSLopID
      , HocSinhID
      , DiemToan
      , SoSao_Toan
      , NhanXetToan_HTML
      , DiemTiengViet
      , SoSao_TiengViet
      , NhanXetTiengViet_HTML
      , NhanXetMonHocKhac_HTML
      , HoatDongGiaoDucKhac_HTML
      , PhamChatNangLuc_HTML
      -- --C2 và C3
      , NoiDungKienThuc_HTML
      , NoiDungNangLuc_HTML
      , NoiDungHoatDongKhac_HTML
      , Enable
      , CreateUser
      , CreateTime
    )
    SELECT @Lop_NhanXetThangID_Copy
         , HSLopID
         , HocSinhID
         , DiemToan
         , dbo.Convert_Star_By_Diem_NhanXetThang(DiemToan)      AS SoSao_Toan
         , NhanXetToan_HTML
         , DiemTiengViet
         , dbo.Convert_Star_By_Diem_NhanXetThang(DiemTiengViet) AS SoSao_TiengViet
         , NhanXetTiengViet_HTML
         , NhanXetMonHocKhac_HTML
         , HoatDongGiaoDucKhac_HTML
         , PhamChatNangLuc_HTML
         , NoiDungKienThuc_HTML
         , NoiDungNangLuc_HTML
         , NoiDungHoatDongKhac_HTML
         , 1
         , @SYS_USERID
         , GETDATE()
    FROM
           @Table;
END;