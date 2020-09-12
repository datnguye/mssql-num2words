--======================================================
-- Usage:	Lib: MoneyToWords in French
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- History:
-- Date			Author		Description
-- 2020-09-12	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_FR
GO
CREATE FUNCTION MoneyToWords_FR(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = N''
	
	DECLARE @ZeroWord		NVARCHAR(10) = N'zéro'
	DECLARE @DotWord		NVARCHAR(10) = N'virgule'
	DECLARE @HundredWord	NVARCHAR(10) = N'cent'
	DECLARE @ThousandWord	NVARCHAR(10) = N'mille'
	DECLARE @MillionWord	NVARCHAR(10) = N'million'
	DECLARE @BillionWord	NVARCHAR(10) = N'billion'

	IF @Number = 0
		SET @vResult = @ZeroWord
	ELSE
	BEGIN		
		SET @vResult = ''
	END

	-- result
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_VI(255.56)
	SELECT dbo.MoneyToWords_VI(123456789.56)
	SELECT dbo.MoneyToWords_VI(123000789.56)
	SELECT dbo.MoneyToWords_VI(123010789.56)
	SELECT dbo.MoneyToWords_VI(123004789.56)
	SELECT dbo.MoneyToWords_VI(123904789.56)
	SELECT dbo.MoneyToWords_VI(205.56)
	SELECT dbo.MoneyToWords_VI(0.29)
	SELECT dbo.MoneyToWords_VI(0.0)
	SELECT dbo.MoneyToWords_VI(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_VI(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_VI(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_VI(999999999999999.99)--999 999 999 999 999.99	
*/