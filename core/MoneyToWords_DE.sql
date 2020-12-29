--======================================================
-- Usage:	Lib: MoneyToWords in German
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.fluentin3months.com/german-numbers/
-- History:
-- Date			Author		Description
-- 2020-12-07	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_DE
GO
CREATE FUNCTION dbo.MoneyToWords_DE(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'ein'),(2,N'zwei'),(3,N'drei'),(4,N'vier'),(5,N'fünf'),(6,N'sechs'),(7,N'sieben'),(8,N'acht'),(9,N'neun'),
			(10,N'zehn'),(11,N'elf'),(12,N'zwölf'),(13,N'dreizehn'),(14,N'vierzehn'),(15,N'fünfzehn'),(16,N'sechzehn'),(17,N'siebzehn'),(18,N'achtzehn'),(19,N'neunzehn'),
			(20,N'zwanzig'),(30,N'dreiβig'),(40,N'vierzig'),(50,N'fünfzig'),(60,N'sechzig'),(70,N'siebzig'),(80,N'achtzig'),(90,N'neunzig')
	
	DECLARE @ZeroWord		NVARCHAR(10) = N'null'
	DECLARE @DotWord		NVARCHAR(10) = N'Komma'
	DECLARE @AndWord		NVARCHAR(10) = N'und'
	DECLARE @HundredWord	NVARCHAR(10) = N'hundert'
	DECLARE @ThousandWord	NVARCHAR(10) = N'tausend'
	DECLARE @MillionWord	NVARCHAR(10) = N'Million'
	DECLARE @BillionWord	NVARCHAR(10) = N'Milliarde'
	DECLARE @TrillionWord	NVARCHAR(10) = N'Billion'

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
				IF @v00Num < 20
				BEGIN
					-- less than 20
                    IF @v000Num = 1 AND @vIndex > 1 
                        SET @vSubResult = N'eine'--Adding 'e' to 1 in case of million+
                    ELSE
					    SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than or equal 20
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SET @v00Num = FLOOR(@v00Num/10)*10
					SELECT @vSubResult = FORMATMESSAGE('%s%s%s', @vSubResult, @AndWord, Nam) FROM @tDict WHERE Num = @v00Num 
				END

				--000
				IF @v000Num > 99
					SELECT @vSubResult = FORMATMESSAGE('%s%s%s', Nam, @HundredWord, @vSubResult) FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				SET @vSubResult = FORMATMESSAGE('%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN @ThousandWord
																		WHEN @vIndex=2 THEN ' '+ @MillionWord + CASE WHEN @v000Num > 1 THEN N'en' ELSE '' END
																		WHEN @vIndex=3 THEN ' '+ @BillionWord + CASE WHEN @v000Num > 1 THEN N'n' ELSE '' END
																		WHEN @vIndex=4 THEN ' '+ @TrillionWord + CASE WHEN @v000Num > 1 THEN N'en' ELSE '' END
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN ' '+ (@MillionWord + CASE WHEN @v000Num > 1 THEN N'en' ELSE '' END) + ' ' + TRIM(REPLICATE(@BillionWord + CASE WHEN @v000Num > 1 THEN N'n' ELSE '' END + ' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN ' '+ TRIM(REPLICATE(@BillionWord + CASE WHEN @v000Num > 1 THEN N'n' ELSE '' END + ' ',@vIndex%3))
																		ELSE ''
																	END)
																	
				IF @vIndex <= 1 AND FLOOR(@Number / 1000) > 0
					SET @vResult = FORMATMESSAGE('%s%s', @vSubResult, @vResult)
				ELSE
					SET @vResult = FORMATMESSAGE('%s %s', @vSubResult, @vResult)
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
	SELECT dbo.MoneyToWords_DE(3201001.25)
	SELECT dbo.MoneyToWords_DE(123456789.56)
	SELECT dbo.MoneyToWords_DE(123000789.56)
	SELECT dbo.MoneyToWords_DE(123010789.56)
	SELECT dbo.MoneyToWords_DE(123004789.56)
	SELECT dbo.MoneyToWords_DE(123904789.56)
	SELECT dbo.MoneyToWords_DE(205.56)
	SELECT dbo.MoneyToWords_DE(45.1)
	SELECT dbo.MoneyToWords_DE(45.09)
	SELECT dbo.MoneyToWords_DE(0.09)
	SELECT dbo.MoneyToWords_DE(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_DE(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_DE(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_DE(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_DE(100000000000000)
*/