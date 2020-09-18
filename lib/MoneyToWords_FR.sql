--======================================================
-- Usage:	Lib: MoneyToWords in French
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.woodwardfrench.com/lesson/numbers-from-1-to-100-in-french/
-- https://www.lawlessfrench.com/vocabulary/numbers-and-counting-3/
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
	--Return result when zero
	SET @Number = ABS(@Number)
	IF @Number = 0
		RETURN N'zéro'

	--Calculation if non-zero
	DECLARE @vResult NVARCHAR(MAX) = N''

	DECLARE @tTo19		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tTo19 (Num, Nam)
	VALUES	(0,N'zéro'), (1,N'un'),(2,N'deux'),(3,N'trois'),(4,N'quatre'),(5,N'cinq'),(6,N'six'),(7,N'sept'),(8,N'huit'),(9,N'neuf'),
			(10,N'dix'),(11,N'onze'),(12,N'douze'),(13,N'treize'),(14,N'quatorze'),(15,N'quinze'),(16,N'seize'),(17,N'dix-sept'),(18,N'dix-huit'),(19,N'dix-neuf')

	DECLARE @tTen		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tTen (Num, Nam)
	VALUES	(20,N'vingt'),(30,N'trente'),(40,N'quarante'),(50,N'cinquante'),(60,N'soixante'),(70,N'soixante'),(80,N'quatre-vingts'),(90,N'quatre-vingt')
	--NOTE: 80 has 's' in 'vingt' but 81+ does not has 's'

	DECLARE @tTenOddOne	TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tTenOddOne (Num, Nam)
	VALUES	(21,N'vingt-et-un'),(31,N'trente-et-un'),(41,N'quarante-et-un'),(51,N'cinquante-et-un'),(61,N'soixante-et-un'),(71,N'soixante-et-onze'),(81,N'quatre-vingt-un'),(91,N'quatre-vingt-onze')
	
	DECLARE @DotWord		NVARCHAR(10) = N'virgule'
	DECLARE @HundredWord	NVARCHAR(10) = N'cent'
	DECLARE @ThousandWord	NVARCHAR(10) = N'mille'
	DECLARE @MillionWord	NVARCHAR(10) = N'million'
	DECLARE @BillionWord	NVARCHAR(10) = N'milliard'
	DECLARE @TrillionWord	NVARCHAR(10) = N'billion'
	--NOTE: For 'mille' - it is invariable, it doesn’t become 'milles'
	--		Cent, Million, Milliard and Billion take on an s when plural
	--		When cents is followed by another number, it loses the s: deux cents but deux cent un
	
	--Decimal numbers
	DECLARE @vDecimalNum INT = (@Number - FLOOR(@Number)) * 100
	DECLARE @vLoop SMALLINT = CONVERT(SMALLINT, SQL_VARIANT_PROPERTY(@Number, 'Scale'))
	DECLARE @vSubDecimalResult	NVARCHAR(MAX) = N''
	IF @vDecimalNum > 0
	BEGIN
		WHILE @vLoop > 0
		BEGIN
			SELECT	@vSubDecimalResult = FORMATMESSAGE('%s %s', Nam, @vSubDecimalResult)
			FROM	@tTo19
			WHERE	Num = @vDecimalNum%10

			SET @vDecimalNum = FLOOR(@vDecimalNum/10)
			SET @vLoop = @vLoop - 1
		END
	END

	--Main numbers
	DECLARE @vSubResult	NVARCHAR(MAX) = N''
	DECLARE @v000Num DECIMAL(15,0) = 0
	DECLARE @v00Num DECIMAL(15,0) = 0
	DECLARE @vIndex SMALLINT = 0
	SET @Number = FLOOR(@Number)
	WHILE 1 = 1
	BEGIN
		-- from right to left: take first 000
		SET @v000Num = @Number % 1000	--hundreds
		SET @v00Num = @v000Num % 100	--tens
		
		IF @v000Num = 0 AND @vIndex > 0
		BEGIN
			SET @vSubResult = ''
		END
		ELSE
		BEGIN
			--zero
			IF @v00Num = 0 AND FLOOR(@v000Num/100) > 0
			BEGIN
				SET @vSubResult =''
			END
			--less than 20
			ELSE IF @v00Num < 20
			BEGIN
				SELECT @vSubResult = Nam FROM @tTo19 WHERE Num = @v00Num
			END
			--greater than or equal 20
			ELSE IF @v00Num % 10 = 1 --but odd
			BEGIN
				SELECT @vSubResult = Nam FROM @tTenOddOne WHERE Num = @v00Num
			END
			--others
			ELSE
			BEGIN
				SELECT	@vSubResult = CASE WHEN Num = 80 THEN REPLACE(Nam,'s','') ELSE Nam END FROM @tTen WHERE Num = FLOOR(@v00Num/10)*10
				SELECT	@vSubResult = FORMATMESSAGE('%s-%s', @vSubResult, Nam) 
				FROM	@tTo19
				WHERE	Num = CASE
								WHEN FLOOR(@v00Num/10) = 7 THEN @v00Num-60--7x = 60+1x
								WHEN FLOOR(@v00Num/10) = 9 THEN @v00Num-80--9x = (4*20)+1x
								ELSE @v00Num % 10
							END
			END

			--hundreds wording
			IF FLOOR(@v000Num/100) > 0
			BEGIN
				SELECT	@vSubResult = TRIM(FORMATMESSAGE('%s %s%s %s', 
															(CASE WHEN Num > 1 THEN Nam ELSE '' END), 
															@HundredWord, 
															(CASE WHEN Num > 1 AND @v00Num = 0 THEN 's' ELSE '' END),
															@vSubResult))
				FROM	@tTo19 
				WHERE	Num = FLOOR(@v000Num/100)
			END
		END

		--
		IF @vSubResult <> ''
		BEGIN
			--thousands+ wording
			SET @vSubResult = FORMATMESSAGE('%s %s%s', @vSubResult,
														CASE 
															WHEN @vIndex=1 THEN @ThousandWord
															WHEN @vIndex=2 THEN @MillionWord
															WHEN @vIndex=3 THEN @BillionWord
															WHEN @vIndex=4 THEN @TrillionWord
															WHEN @vIndex>4 THEN '***'
															ELSE ''
														END,
														CASE 
															WHEN @v000Num > 1 AND @vIndex > 1 THEN 's'
															ELSE ''
														END)
			SET @vResult = TRIM(FORMATMESSAGE('%s %s',TRIM(@vSubResult), @vResult))
		END
		
		-- next 000 (to left)
		SET @vIndex = @vIndex + 1
		SET @Number = FLOOR(@Number / 1000)
		IF @Number = 0 BREAK
	END

	SET @vResult = FORMATMESSAGE('%s %s', @vResult, COALESCE(@DotWord + ' ' + NULLIF(@vSubDecimalResult,''), ''))

	-- result
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_FR(255.56)
	SELECT dbo.MoneyToWords_FR(123456789.56) --123 456 789.56
	SELECT dbo.MoneyToWords_FR(123000789.23) --123 000 789.23
	SELECT dbo.MoneyToWords_FR(323010789.06) --323 010 789.06
	SELECT dbo.MoneyToWords_FR(123004789.13) --123 004 789.13
	SELECT dbo.MoneyToWords_FR(923904789.49) --923 904 789.49
	SELECT dbo.MoneyToWords_FR(171.99)
	SELECT dbo.MoneyToWords_FR(181.01)
	SELECT dbo.MoneyToWords_FR(285.56)
	SELECT dbo.MoneyToWords_FR(205.28)
	SELECT dbo.MoneyToWords_FR(45.00)
	SELECT dbo.MoneyToWords_FR(0.29)
	SELECT dbo.MoneyToWords_FR(0.0)
	SELECT dbo.MoneyToWords_FR(1200567896789.02)--1 200 567 896 789.02
	SELECT dbo.MoneyToWords_FR(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_FR(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_FR(823234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_FR(999999999999999.99)--999 999 999 999 999.99	
*/