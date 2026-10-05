CREATE PROC [dbo].[spCalculate_APIndex]
@AnPhamID INT
AS
BEGIN
	DECLARE @tmp AS TABLE (STT INT, AnPhamTacGiaID INT)
	INSERT INTO @tmp(STT, AnPhamTacGiaID)
	SELECT ROW_NUMBER() OVER (ORDER BY B.[AnPhamTacGiaID]) AS 'STT',
			B.[AnPhamTacGiaID]
	FROM AnPham_TacGia B 
	WHERE B.AnPhamID = @AnPhamID AND B.Is_Xoa = 0 

	UPDATE AnPham_TacGia
		SET AP_Index = CASE WHEN A.STT = 1 OR B.Is_TacGiaChinh = 1 THEN 1 
							 WHEN A.STT = 2 THEN 0.9
							WHEN A.STT = 3 THEN 0.7
							WHEN A.STT = 4 THEN 0.5
							ELSE 0.3 END 
		FROM @tmp A INNER JOIN AnPham_TacGia B ON A.AnPhamTacGiaID = B.AnPhamTacGiaID
		WHERE B.AnPhamID = @AnPhamID
END

