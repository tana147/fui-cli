CREATE TABLE ___GiaiThuong_File (GiaiThuongFileID int(4) NOT NULL PRIMARY KEY IDENTITY,GiaiThuongID int(4) NULL,FileIDList varchar(500) NULL,MoTa nvarchar(500) NULL,NhanVienCapNhat char(9) NOT NULL,ThoiGianCapNhat datetime(8) NOT NULL,Is_Xoa bit(1) NOT NULL);

CREATE TABLE AnPham_2024_2025 (AnPhamID int(4) NULL,TenAnPham nvarchar(max) NULL,NamDangHienTai int(4) NULL,NamDangChuan int(4) NULL);

CREATE TABLE AnPham_Loai_BK (LoaiAnPhamID int(4) NOT NULL IDENTITY,TenLoaiAnPham nvarchar(200) NULL,Sort int(4) NULL,MoTa nvarchar(50) NULL,TrangThai tinyint(1) NULL,NhanVienCapNhat char(9) NULL,ThoiGianCapNhat datetime(8) NULL,Is_Xoa bit(1) NOT NULL);