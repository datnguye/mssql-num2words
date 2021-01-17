--======================================================
-- Usage:	Lib: MoneyToWords in Dutch (NL)
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://omniglot.com/language/numbers/dutch.htm
-- https://www.dutch-and-go.com/numbers-how-to-count-in-dutch/
-- History:
-- Date			Author		Description
-- 2021-01-17	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_NL
GO
CREATE FUNCTION dbo.MoneyToWords_NL(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'één'),(2,N'twee'),(3,N'drie'),(4,N'vier'),(5,N'vijf'),(6,N'zes'),(7,N'zeven'),(8,N'acht'),(9,N'negen'),
			(11,N'elf'),(12,N'twaalf'),(13,N'dertien'),(14,N'veertien'),(15,N'vijftien'),(16,N'zestien'),(17,N'zeventien'),(18,N'achttien'),(19,N'negentien'),
			--(21,N'eenentwintig'),(22,N'tweeëntwintig'),(23,N'drieëntwintig'),(24,N'vierentwintig'),(25,N'vijfentwintig'),(26,N'zesentwintig'),(27,N'zevenentwintig'),(28,N'achtentwintig'),(29,N'negenentwintig'),
			(10,N'tien'),(20,N'twintig'),(30,N'dertig'),(40,N'veertig'),(50,N'vijftig'),(60,N'zestig'),(70,N'zeventig'),(80,N'tachtig'),(90,N'negentig')
	
	DECLARE @ZeroWord			NVARCHAR(20) = N'nul'
	DECLARE @DotWord			NVARCHAR(20) = N'komma'
	DECLARE @AndWord			NVARCHAR(20) = N'en'
	DECLARE @HundredWord		NVARCHAR(20) = N'honderd'
	DECLARE @ThousandWord		NVARCHAR(20) = N'duizend'
	DECLARE @MillionWord		NVARCHAR(20) = N'miljoen'
	DECLARE @BilllionWord		NVARCHAR(20) = N'miljard'
	DECLARE @TrillionWord		NVARCHAR(20) = N'biljoen'
	DECLARE @QuadrillionWord	NVARCHAR(20) = N'biljard'
	DECLARE @QuintillionWord	NVARCHAR(20) = N'triljoen'

	-- decimal number	
	DECLARE @vDecimalNum INT = (@Number - FLOOR(@Number)) * 100
	DECLARE @vLoop SMALLINT = CONVERT(SMALLINT, SQL_VARIANT_PROPERTY(@Number, 'Scale'))
	DECLARE @vSubDecimalResult	NVARCHAR(MAX) = N''
	IF @vDecimalNum > 0
	BEGIN
		WHILE @vLoop > 0
		BEGIN
			IF @vDecimalNum % 10 = 0
				SET @vSubDecimalResult = FORMATMESSAGE('%s %s', @ZeroWord, @vSubDecimalResult)
			ELSE
				SELECT	@vSubDecimalResult = FORMATMESSAGE('%s %s', Nam, @vSubDecimalResult)
				FROM	@tDict
				WHERE	Num = @vDecimalNum%10

			SET @vDecimalNum = FLOOR(@vDecimalNum/10)
			SET @vLoop = @vLoop - 1
		END
	END
	
	-- main number
	SET @Number = FLOOR(@Number)
	IF @Number = 0
		SET @vResult = @ZeroWord
	ELSE
	BEGIN
		DECLARE @vSubResult	NVARCHAR(MAX) = ''
		DECLARE @v000Num DECIMAL(15,0) = 0
		DECLARE @v00Num DECIMAL(15,0) = 0
		DECLARE @v0Num DECIMAL(15,0) = 0
		DECLARE @vIndex SMALLINT = 0
		
		WHILE @Number > 0
		BEGIN
			-- from right to left: take first 000
			SET @v000Num = @Number % 1000
			SET @v00Num = @v000Num % 100
			SET @v0Num = @v00Num % 10
			IF @v000Num = 0
			BEGIN
				SET @vSubResult = ''
			END
			ELSE 
			BEGIN 
				--00
				IF @v00Num <= 20
				BEGIN
					-- less than or equal 20
                    SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than 20
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SELECT @vSubResult = FORMATMESSAGE('%s%s%s', @vSubResult, @AndWord, Nam) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10 
				END

				--000
				IF @v000Num > 99
				BEGIN
					SELECT	@vSubResult = FORMATMESSAGE('%s%s%s', (CASE WHEN Num > 1 THEN Nam ELSE N'' END), @HundredWord, @vSubResult) 
					FROM	@tDict
					WHERE	Num = FLOOR(@v000Num/100)
				END
			END
			
			--000 xxx
			IF @vSubResult <> '' 
			BEGIN
				SET @vSubResult = FORMATMESSAGE('%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN @ThousandWord
																		WHEN @vIndex=2 THEN N' '+@MillionWord+N' '
																		WHEN @vIndex=3 THEN N' '+@BilllionWord+N' '
																		WHEN @vIndex=4 THEN N' '+@TrillionWord+N' '
																		WHEN @vIndex=5 THEN N' '+@QuadrillionWord+N' '
																		WHEN @vIndex=6 THEN N' '+@QuintillionWord+N' '
																		ELSE N''
																	END)
																	
				SET @vResult = FORMATMESSAGE('%s%s', @vSubResult, @vResult)
			END

			-- next 000 (to left)
			SET @vIndex = @vIndex + 1
			SET @Number = FLOOR(@Number / 1000)
		END
	END

	SET @vResult = FORMATMESSAGE('%s %s', TRIM(@vResult), COALESCE(@DotWord + ' ' + NULLIF(@vSubDecimalResult,''), ''))
	
	-- result
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_NL(3201001.25)
	SELECT dbo.MoneyToWords_NL(123456789.56)
	SELECT dbo.MoneyToWords_NL(123000789.56)
	SELECT dbo.MoneyToWords_NL(123010789.56)
	SELECT dbo.MoneyToWords_NL(123004789.56)
	SELECT dbo.MoneyToWords_NL(123904789.56)
	SELECT dbo.MoneyToWords_NL(205.56)
	SELECT dbo.MoneyToWords_NL(45.1)
	SELECT dbo.MoneyToWords_NL(45.09)
	SELECT dbo.MoneyToWords_NL(0.09)
	SELECT dbo.MoneyToWords_NL(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_NL(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_NL(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_NL(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_NL(100000000000000)
*/