	   CREATE FUNCTION dbo.fnGetTuanHoc_HienThi
(
    @Tuan INT,
    @ThangHoc INT,
    @NgayBatDau DATE,
    @NgayKetThuc DATE
)
RETURNS NVARCHAR(100)
AS
BEGIN
    RETURN 
        N'Tuần ' + CAST(@Tuan AS VARCHAR(2))
        + N' - Tháng ' + CAST(@ThangHoc AS VARCHAR(2))
        + N' - (' 
        + RIGHT('00' + CAST(DAY(@NgayBatDau) AS VARCHAR(2)), 2) + '/'
        + RIGHT('00' + CAST(MONTH(@NgayBatDau) AS VARCHAR(2)), 2) + '/'
        + CAST(YEAR(@NgayBatDau) AS VARCHAR(4))
        + N' - '
        + RIGHT('00' + CAST(DAY(@NgayKetThuc) AS VARCHAR(2)), 2) + '/'
        + RIGHT('00' + CAST(MONTH(@NgayKetThuc) AS VARCHAR(2)), 2) + '/'
        + CAST(YEAR(@NgayKetThuc) AS VARCHAR(4))
        + N')';
END;
