--======================================================
-- Usage:	MAIN FUNCTION: MoneyToWords with input money and language
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- History:
-- Date			Author		Description
-- 2020-09-05	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords
GO
CREATE FUNCTION MoneyToWords(@Number DECIMAL(17,2), @Lang char(2) = 'en')
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	RETURN CASE 
		--WHEN LOWER(@Lang)='de' THEN dbo.MoneyToWords_DE(@Number)
		WHEN LOWER(@Lang)='fr' THEN dbo.MoneyToWords_FR(@Number)
		--WHEN LOWER(@Lang)='th' THEN dbo.MoneyToWords_TH(@Number)
		WHEN LOWER(@Lang)='vi' THEN dbo.MoneyToWords_VI(@Number)
		ELSE N'In development...'
	END		
END
/*	
	DECLARE @Lang char(2) = 'fr'

	SELECT dbo.MoneyToWords(255.56, @Lang)
	SELECT dbo.MoneyToWords(123456789.56, @Lang)
	SELECT dbo.MoneyToWords(205.56, @Lang)
	SELECT dbo.MoneyToWords(0.29, @Lang)
	SELECT dbo.MoneyToWords(0.0, @Lang)
	SELECT dbo.MoneyToWords(1234567896789.02, @Lang)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords(1234567896789.52, @Lang)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords(123234567896789.02, @Lang)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords(999999999999999.99, @Lang)--999 999 999 999 999.99
*/