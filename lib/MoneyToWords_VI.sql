--======================================================
-- Usage:	Lib: MoneyToWords in Vietnamese
-- Notes:	
-- History:
-- Date			Author		Description
-- 2020-08-31	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_VI
GO
CREATE FUNCTION MoneyToWords_VI(@BaseNumber DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	DECLARE @Result NVARCHAR(MAX) = N''
    RETURN @Result
END
/*
	SELECT dbo.MoneyToWords_VI(255)
*/