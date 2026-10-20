-- DDL BACKUP OF 23 OLD BACKUP TABLES
-- DATE: 2026-10-20

CREATE TABLE [dbo].[Decision2026_06_02_11_23_36] (
    [Decision_ID] int NOT NULL,
    [Decision_SoQD] nvarchar(50) NULL,
    [Decision_NgayQD] varchar(2) NULL,
    [Decision_ThangQD] varchar(2) NULL,
    [Decision_NamQD] varchar(4) NULL,
    [Decision_TieuDe] nvarchar(500) NULL,
    [Decision_NganhID] int NULL,
    [Decision_Nganh] nvarchar(200) NULL,
    [Decision_NienKhoa] nvarchar(20) NULL,
    [Decision_Dot] nvarchar(10) NULL,
    [Decision_MaSo] nvarchar(50) NULL,
    [Decision_Type] nvarchar(20) NULL,
    [Decision_Description] nvarchar(MAX) NULL,
    [DecisionFile_ID] nvarchar(50) NULL,
    [DecisionFile_Url] nvarchar(500) NULL,
    [DecisionFile_Name] nvarchar(255) NULL,
    [Decision_TemplateID] tinyint NULL,
    [Decision_Status] tinyint NOT NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL,
    [HoiDong_ID] int NULL
);
GO

CREATE TABLE [dbo].[Flow_2026_06_02_11_23_36] (
    [Flow_ID] int NOT NULL,
    [Process_Student_ID] int NULL,
    [Process_ID] int NULL,
    [Student_ID] varchar(20) NULL,
    [Task_Parent] int NULL,
    [Task_ID] int NULL,
    [Seq] int NULL,
    [Task_Require] tinyint NULL,
    [use_yn] bit NULL,
    [Flow_Status] varchar(20) NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[Flow_Detail_2026_06_02_11_23_36] (
    [Flow_Detail_ID] int NOT NULL,
    [Flow_ID] int NULL,
    [Task_ID] int NULL,
    [Task_Detail_ID] int NULL,
    [File_URL] nvarchar(500) NULL,
    [Text_Content] nvarchar(MAX) NULL,
    [File_Name] nvarchar(255) NULL,
    [File_ID] varchar(50) NULL,
    [File_Type] nvarchar(50) NULL,
    [Flow_Detail_Status] varchar(20) NULL,
    [use_yn] bit NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[HoiDong2026_06_02_11_23_36] (
    [HoiDongID] int NOT NULL,
    [StudentID] varchar(9) NULL,
    [DeTai] nvarchar(500) NULL,
    [Decision_ID] int NULL,
    [LoaiHoiDong] tinyint NULL,
    [DiemHoiDong] float NULL,
    [KetQuaHoiDong] tinyint NULL,
    [NhanXet] nvarchar(500) NULL,
    [FileNhanXetID] varchar(32) NULL,
    [FileNhanXetName] nvarchar(500) NULL,
    [ThoiGianBaoVe] varchar(10) NULL,
    [FileKiemPhieuID] varchar(32) NULL,
    [FileKiemPhieuName] nvarchar(500) NULL,
    [HoiDong_Status] tinyint NOT NULL,
    [Is_PublishDiem] tinyint NOT NULL,
    [Is_Xoa] bit NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[Process_Student2026_06_02_11_23_36] (
    [Process_Stu_ID] int NOT NULL,
    [Process_ID] int NULL,
    [Student_ID] varchar(20) NULL,
    [Expire_Date] date NULL,
    [Expire_Date_1] date NULL,
    [Expire_Date_2] date NULL,
    [Expire_Date_3] date NULL,
    [use_yn] bit NULL,
    [Task_Begin] int NULL,
    [Process_Student_Status] varchar(20) NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL,
    [STOP_BY_PROCESS_ID] int NULL
);
GO

CREATE TABLE [dbo].[StudentInfo2026_06_02_11_23_36] (
    [StudentID] varchar(9) NULL,
    [HoSV] nvarchar(50) NULL,
    [TenSV] nvarchar(30) NULL,
    [LopID] varchar(9) NULL,
    [KhoaID] varchar(3) NULL,
    [NganhID] varchar(10) NULL,
    [TenNganh] nvarchar(50) NULL,
    [HeDaoTaoID] int NULL,
    [HeDaoTao] nvarchar(20) NULL,
    [NienKhoa] varchar(9) NULL,
    [NgaySinh] varchar(10) NULL,
    [NoiSinh] nvarchar(200) NULL,
    [GioiTinh] nvarchar(5) NULL,
    [SoDienThoai] varchar(15) NULL,
    [Email] varchar(100) NULL,
    [DanToc] nvarchar(50) NULL,
    [QuocTich] nvarchar(150) NULL,
    [CCCD] varchar(12) NULL,
    [NgayCap_CCCD] date NULL,
    [Truong_DaiHoc] nvarchar(400) NULL,
    [Nganh_DaiHoc] nvarchar(150) NULL,
    [ThoiGianTotNghiep_DaiHoc] varchar(50) NULL,
    [XepLoai] nvarchar(120) NULL,
    [NgoaiNgu_DauVao] nvarchar(300) NULL,
    [BoSungKienThuc] nvarchar(50) NULL,
    [CongBoKhoaHoc] nvarchar(50) NULL,
    [Loai_NgoaiNgu_DauVao] nvarchar(50) NULL,
    [IsXuLyHocVu] bit NULL,
    [IsHoanThanhThacSi] bit NULL,
    [CreateUser] varchar(9) NULL,
    [CreateTime] datetime NULL,
    [UpdateUser] varchar(9) NULL,
    [UpdateTime] datetime NULL
);
GO

CREATE TABLE [dbo].[Task_Detail_2026_06_02_11_23_36] (
    [Task_Detail_ID] int NOT NULL,
    [Task_ID] int NULL,
    [Task_Detail_Seq] int NULL,
    [Task_Detail_Description] nvarchar(MAX) NULL,
    [Task_Detail_Type] nvarchar(500) NULL,
    [User_Input] nvarchar(MAX) NULL,
    [Task_Detail_Status] varchar(20) NULL,
    [Task_Detail_Display] tinyint NULL,
    [Task_Detail_StyleDisplay] nvarchar(500) NULL,
    [Data_Exp] nvarchar(MAX) NULL,
    [UI_Component] nvarchar(MAX) NULL,
    [FN_Check] nvarchar(MAX) NULL,
    [FieldName] varchar(50) NULL,
    [Task_Help] nvarchar(500) NULL,
    [AllowNull] char(1) NULL,
    [AllowFileType] varchar(50) NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL,
    [USE_YN] bit NULL
);
GO

CREATE TABLE [dbo].[Task_Task_2026_06_02_11_23_36] (
    [Task_Task_ID] int NOT NULL,
    [Task_Parent] int NULL,
    [Task_ID] int NULL,
    [Seq] int NULL,
    [Task_Require] tinyint NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[Tasks_2026_06_02_11_23_36] (
    [Task_ID] int NOT NULL,
    [Task_Code] varchar(20) NULL,
    [Task_Name] nvarchar(500) NULL,
    [Task_Description] nvarchar(MAX) NULL,
    [API_Name] nvarchar(MAX) NULL,
    [Task_Status] varchar(20) NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[Decision2026_05_26_10_38_17] (
    [Decision_ID] int NOT NULL,
    [Decision_SoQD] nvarchar(50) NULL,
    [Decision_NgayQD] varchar(2) NULL,
    [Decision_ThangQD] varchar(2) NULL,
    [Decision_NamQD] varchar(4) NULL,
    [Decision_TieuDe] nvarchar(500) NULL,
    [Decision_NganhID] int NULL,
    [Decision_Nganh] nvarchar(200) NULL,
    [Decision_NienKhoa] nvarchar(20) NULL,
    [Decision_Dot] nvarchar(10) NULL,
    [Decision_MaSo] nvarchar(50) NULL,
    [Decision_Type] nvarchar(20) NULL,
    [Decision_Description] nvarchar(MAX) NULL,
    [DecisionFile_ID] nvarchar(50) NULL,
    [DecisionFile_Url] nvarchar(500) NULL,
    [DecisionFile_Name] nvarchar(255) NULL,
    [Decision_TemplateID] tinyint NULL,
    [Decision_Status] tinyint NOT NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL,
    [HoiDong_ID] int NULL
);
GO

CREATE TABLE [dbo].[Flow_2026_05_26_10_38_17] (
    [Flow_ID] int NOT NULL,
    [Process_Student_ID] int NULL,
    [Process_ID] int NULL,
    [Student_ID] varchar(20) NULL,
    [Task_Parent] int NULL,
    [Task_ID] int NULL,
    [Seq] int NULL,
    [Task_Require] tinyint NULL,
    [use_yn] bit NULL,
    [Flow_Status] varchar(20) NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[Flow_Detail_2026_05_26_10_38_17] (
    [Flow_Detail_ID] int NOT NULL,
    [Flow_ID] int NULL,
    [Task_ID] int NULL,
    [Task_Detail_ID] int NULL,
    [File_URL] nvarchar(500) NULL,
    [Text_Content] nvarchar(MAX) NULL,
    [File_Name] nvarchar(255) NULL,
    [File_ID] varchar(50) NULL,
    [File_Type] nvarchar(50) NULL,
    [Flow_Detail_Status] varchar(20) NULL,
    [use_yn] bit NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[HoiDong2026_05_26_10_38_17] (
    [HoiDongID] int NOT NULL,
    [StudentID] varchar(9) NULL,
    [DeTai] nvarchar(500) NULL,
    [Decision_ID] int NULL,
    [LoaiHoiDong] tinyint NULL,
    [DiemHoiDong] float NULL,
    [KetQuaHoiDong] tinyint NULL,
    [NhanXet] nvarchar(500) NULL,
    [FileNhanXetID] varchar(32) NULL,
    [FileNhanXetName] nvarchar(500) NULL,
    [ThoiGianBaoVe] varchar(10) NULL,
    [FileKiemPhieuID] varchar(32) NULL,
    [FileKiemPhieuName] nvarchar(500) NULL,
    [HoiDong_Status] tinyint NOT NULL,
    [Is_PublishDiem] tinyint NOT NULL,
    [Is_Xoa] bit NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[Process_Student2026_05_26_10_38_17] (
    [Process_Stu_ID] int NOT NULL,
    [Process_ID] int NULL,
    [Student_ID] varchar(20) NULL,
    [Expire_Date] date NULL,
    [Expire_Date_1] date NULL,
    [Expire_Date_2] date NULL,
    [Expire_Date_3] date NULL,
    [use_yn] bit NULL,
    [Task_Begin] int NULL,
    [Process_Student_Status] varchar(20) NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL,
    [STOP_BY_PROCESS_ID] int NULL
);
GO

CREATE TABLE [dbo].[StudentInfo2026_05_26_10_38_17] (
    [StudentID] varchar(9) NULL,
    [HoSV] nvarchar(50) NULL,
    [TenSV] nvarchar(30) NULL,
    [LopID] varchar(9) NULL,
    [KhoaID] varchar(3) NULL,
    [NganhID] varchar(10) NULL,
    [TenNganh] nvarchar(50) NULL,
    [HeDaoTaoID] int NULL,
    [HeDaoTao] nvarchar(20) NULL,
    [NienKhoa] varchar(9) NULL,
    [NgaySinh] varchar(10) NULL,
    [NoiSinh] nvarchar(200) NULL,
    [GioiTinh] nvarchar(5) NULL,
    [SoDienThoai] varchar(15) NULL,
    [Email] varchar(100) NULL,
    [DanToc] nvarchar(50) NULL,
    [QuocTich] nvarchar(150) NULL,
    [CCCD] varchar(12) NULL,
    [NgayCap_CCCD] date NULL,
    [Truong_DaiHoc] nvarchar(400) NULL,
    [Nganh_DaiHoc] nvarchar(150) NULL,
    [ThoiGianTotNghiep_DaiHoc] varchar(50) NULL,
    [XepLoai] nvarchar(120) NULL,
    [NgoaiNgu_DauVao] nvarchar(300) NULL,
    [BoSungKienThuc] nvarchar(50) NULL,
    [CongBoKhoaHoc] nvarchar(50) NULL,
    [Loai_NgoaiNgu_DauVao] nvarchar(50) NULL,
    [IsXuLyHocVu] bit NULL,
    [IsHoanThanhThacSi] bit NULL,
    [CreateUser] varchar(9) NULL,
    [CreateTime] datetime NULL,
    [UpdateUser] varchar(9) NULL,
    [UpdateTime] datetime NULL
);
GO

CREATE TABLE [dbo].[Task_Detail_2026_05_26_10_38_17] (
    [Task_Detail_ID] int NOT NULL,
    [Task_ID] int NULL,
    [Task_Detail_Seq] int NULL,
    [Task_Detail_Description] nvarchar(MAX) NULL,
    [Task_Detail_Type] nvarchar(500) NULL,
    [User_Input] nvarchar(MAX) NULL,
    [Task_Detail_Status] varchar(20) NULL,
    [Task_Detail_Display] tinyint NULL,
    [Task_Detail_StyleDisplay] nvarchar(500) NULL,
    [Data_Exp] nvarchar(MAX) NULL,
    [UI_Component] nvarchar(MAX) NULL,
    [FN_Check] nvarchar(MAX) NULL,
    [FieldName] varchar(50) NULL,
    [Task_Help] nvarchar(500) NULL,
    [AllowNull] char(1) NULL,
    [AllowFileType] varchar(50) NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL,
    [USE_YN] bit NULL
);
GO

CREATE TABLE [dbo].[Task_Task_2026_05_26_10_38_17] (
    [Task_Task_ID] int NOT NULL,
    [Task_Parent] int NULL,
    [Task_ID] int NULL,
    [Seq] int NULL,
    [Task_Require] tinyint NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[Tasks_2026_05_26_10_38_17] (
    [Task_ID] int NOT NULL,
    [Task_Code] varchar(20) NULL,
    [Task_Name] nvarchar(500) NULL,
    [Task_Description] nvarchar(MAX) NULL,
    [API_Name] nvarchar(MAX) NULL,
    [Task_Status] varchar(20) NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[Flow_BK20240524] (
    [Flow_ID] int NOT NULL,
    [Process_Student_ID] int NULL,
    [Process_ID] int NULL,
    [Student_ID] varchar(20) NULL,
    [Task_Parent] int NULL,
    [Task_ID] int NULL,
    [Seq] int NULL,
    [Task_Require] tinyint NULL,
    [use_yn] bit NULL,
    [Flow_Status] varchar(20) NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[Flow_Detail_BK20240524] (
    [Flow_Detail_ID] int NOT NULL,
    [Flow_ID] int NULL,
    [Task_ID] int NULL,
    [Task_Detail_ID] int NULL,
    [File_URL] nvarchar(500) NULL,
    [Text_Content] nvarchar(MAX) NULL,
    [File_Name] nvarchar(255) NULL,
    [File_ID] varchar(50) NULL,
    [File_Type] nvarchar(50) NULL,
    [Flow_Detail_Status] varchar(20) NULL,
    [use_yn] bit NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[Task_Detail_BK] (
    [Task_Detail_ID] int NOT NULL,
    [Task_ID] int NULL,
    [Task_Detail_Seq] int NULL,
    [Task_Detail_Description] nvarchar(MAX) NULL,
    [Task_Detail_Type] nvarchar(500) NULL,
    [User_Input] nvarchar(MAX) NULL,
    [Task_Detail_Status] varchar(20) NULL,
    [Task_Detail_Display] tinyint NULL,
    [Task_Detail_StyleDisplay] nvarchar(500) NULL,
    [Data_Exp] nvarchar(MAX) NULL,
    [UI_Component] nvarchar(MAX) NULL,
    [FN_Check] nvarchar(MAX) NULL,
    [FieldName] varchar(50) NULL,
    [AllowNull] char(1) NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[Task_Task_BK] (
    [Task_Task_ID] int NOT NULL,
    [Task_Parent] int NULL,
    [Task_ID] int NULL,
    [Seq] int NULL,
    [Task_Require] tinyint NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO

CREATE TABLE [dbo].[Tasks_BK] (
    [Task_ID] int NOT NULL,
    [Task_Code] varchar(20) NULL,
    [Task_Name] nvarchar(500) NULL,
    [Task_Description] nvarchar(MAX) NULL,
    [API_Name] nvarchar(MAX) NULL,
    [Task_Status] varchar(20) NULL,
    [Created_By] varchar(20) NULL,
    [Created_At] datetime NULL,
    [Updated_By] varchar(20) NULL,
    [Updated_At] datetime NULL
);
GO
