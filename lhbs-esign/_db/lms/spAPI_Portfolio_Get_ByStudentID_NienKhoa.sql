

-- 7. CREATE STORED PROCEDURE: spAPI_Portfolio_Get_ByStudentID_NienKhoa
-- Retrieve approved portfolio (Status = 4) for parent view.
CREATE   PROC [dbo].[spAPI_Portfolio_Get_ByStudentID_NienKhoa]
    @HocSinhID INT
  , @NienKhoa  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.PortfolioID
      , p.Template_PorfolioID
      , p.HocSinhID
      , p.JsonData
      , p.CoutPDF
      , p.CountImage
      , p.NienKhoa
      , p.Status
      , p.ReasonReject
      , p.ApproverUser
      , p.ApproveTime
      , p.FileID_Portfolio_IMG
      , p.FileID_Portfolio_PDF
      , tp.MonHocID
      , mh.MonHocName
    FROM dbo.tblPortfolio p
    LEFT JOIN dbo.tblTemplate_Portfolio tp ON tp.Template_PortfolioID = p.Template_PorfolioID AND tp.Enable = 1
    LEFT JOIN dbo.tblMonHoc mh ON mh.MonHocID = tp.MonHocID
    WHERE p.HocSinhID = @HocSinhID
      AND p.NienKhoa  = @NienKhoa
   --   AND p.Status    = 4  -- Chỉ lấy những portfolio đã được duyệt
      AND p.Enable    = 1;
END;