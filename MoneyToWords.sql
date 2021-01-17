--======================================================
-- Usage:	MAIN FUNCTION: MoneyToWords with input money and language
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- History:
-- Date			Author		Description
-- 2020-09-05	DN			Intial
-- 2021-01-17	DN			Finished 30 languages
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords
GO
CREATE FUNCTION MoneyToWords(@Number DECIMAL(17,2), @Lang char(2) = 'en')
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	RETURN CASE 
		WHEN LOWER(@Lang)='ar' THEN dbo.MoneyToWords_AR(@Number)
		WHEN LOWER(@Lang)='cz' THEN dbo.MoneyToWords_CZ(@Number)
		WHEN LOWER(@Lang)='de' THEN dbo.MoneyToWords_DE(@Number)
		WHEN LOWER(@Lang)='dk' THEN dbo.MoneyToWords_DK(@Number)
		WHEN LOWER(@Lang)='es' THEN dbo.MoneyToWords_ES(@Number)
		WHEN LOWER(@Lang)='fi' THEN dbo.MoneyToWords_FI(@Number)
		WHEN LOWER(@Lang)='fr' THEN dbo.MoneyToWords_FR(@Number)
		WHEN LOWER(@Lang)='ga' THEN dbo.MoneyToWords_GA(@Number)
		WHEN LOWER(@Lang)='he' THEN dbo.MoneyToWords_HE(@Number)
		WHEN LOWER(@Lang)='hi' THEN dbo.MoneyToWords_HI(@Number)
		WHEN LOWER(@Lang)='id' THEN dbo.MoneyToWords_ID(@Number)
		WHEN LOWER(@Lang)='th' THEN dbo.MoneyToWords_TH(@Number)
		WHEN LOWER(@Lang)='it' THEN dbo.MoneyToWords_IT(@Number)
		WHEN LOWER(@Lang)='ja' THEN dbo.MoneyToWords_JA(@Number)
		WHEN LOWER(@Lang)='ko' THEN dbo.MoneyToWords_KO(@Number)
		WHEN LOWER(@Lang)='kz' THEN dbo.MoneyToWords_KZ(@Number)
		WHEN LOWER(@Lang)='lt' THEN dbo.MoneyToWords_LT(@Number)
		WHEN LOWER(@Lang)='lv' THEN dbo.MoneyToWords_LV(@Number)
		WHEN LOWER(@Lang)='nl' THEN dbo.MoneyToWords_NL(@Number)
		WHEN LOWER(@Lang)='no' THEN dbo.MoneyToWords_NO(@Number)
		WHEN LOWER(@Lang)='pl' THEN dbo.MoneyToWords_PL(@Number)
		WHEN LOWER(@Lang)='pt' THEN dbo.MoneyToWords_PT(@Number)
		WHEN LOWER(@Lang)='ru' THEN dbo.MoneyToWords_RU(@Number)
		WHEN LOWER(@Lang)='sl' THEN dbo.MoneyToWords_SL(@Number)
		WHEN LOWER(@Lang)='sr' THEN dbo.MoneyToWords_SR(@Number)
		WHEN LOWER(@Lang)='te' THEN dbo.MoneyToWords_TE(@Number)
		WHEN LOWER(@Lang)='tr' THEN dbo.MoneyToWords_TR(@Number)
		WHEN LOWER(@Lang)='uk' THEN dbo.MoneyToWords_UK(@Number)
		WHEN LOWER(@Lang)='vi' THEN dbo.MoneyToWords_VI(@Number)
		ELSE dbo.MoneyToWords_EN(@Number)
	END		
END