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
		WHEN LOWER(@Lang)='de' THEN dbo.MoneyToWords_DE(@Number)
		WHEN LOWER(@Lang)='es' THEN dbo.MoneyToWords_ES(@Number)
		WHEN LOWER(@Lang)='fr' THEN dbo.MoneyToWords_FR(@Number)
		--WHEN LOWER(@Lang)='th' THEN dbo.MoneyToWords_TH(@Number)
		WHEN LOWER(@Lang)='it' THEN dbo.MoneyToWords_IT(@Number)
		WHEN LOWER(@Lang)='vi' THEN dbo.MoneyToWords_VI(@Number)
		ELSE dbo.MoneyToWords_EN(@Number)
	END		
END