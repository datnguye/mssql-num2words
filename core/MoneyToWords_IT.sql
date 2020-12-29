--======================================================
-- Usage:	Lib: MoneyToWords in Italian
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.italianpod101.com/blog/2019/10/24/italian-numbers/
-- History:
-- Date			Author		Description
-- 2020-12-07	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_IT
GO
CREATE FUNCTION dbo.MoneyToWords_IT(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'uno'),(2,N'due'),(3,N'tre'),(4,N'quattro'),(5,N'cinque'),(6,N'sei'),(7,N'sette'),(8,N'otto'),(9,N'nove'),
			(10,N'dieci'),(11,N'undici'),(12,N'dodici'),(13,N'tredici'),(14,N'quattordici'),(15,N'quindici'),(16,N'sedici'),(17,N'diciassette'),(18,N'diciotto'),(19,N'diciannove'),
			(20,N'venti'),(30,N'trenta'),(40,N'quaranta'),(50,N'cinquanta'),(60,N'sessanta'),(70,N'settanta'),(80,N'ottanta'),(90,N'novanta')
	
	DECLARE @ZeroWord		NVARCHAR(10) = N'zero'
	DECLARE @DotWord		NVARCHAR(10) = N'virgola'
	DECLARE @AndWord		NVARCHAR(10) = N'e'
	DECLARE @HundredWord	NVARCHAR(10) = N'cento'
	DECLARE @ThousandWord	NVARCHAR(10) = N'mille'
	DECLARE @ThousandWords	NVARCHAR(10) = N'mila'--plural
	DECLARE @MillionWord	NVARCHAR(10) = N'milione'
	DECLARE @MillionWords	NVARCHAR(10) = N'milioni'--plural
	DECLARE @BillionWord	NVARCHAR(10) = N'miliardo'
	DECLARE @BillionWords	NVARCHAR(10) = N'miliardi'--plural
	DECLARE @TrillionWord	NVARCHAR(10) = N'bilione'
	DECLARE @TrillionWords	NVARCHAR(10) = N'bilioni'--plural

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
                    SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than or equal 20
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SET @v00Num = FLOOR(@v00Num/10)*10
					SELECT @vSubResult = FORMATMESSAGE('%s%s', Nam, @vSubResult) FROM @tDict WHERE Num = @v00Num 
				END

				--000
				IF @v000Num > 99
				BEGIN
					IF @v000Num < 199
						SET @vSubResult = FORMATMESSAGE('%s%s', @HundredWord, @vSubResult)
					ELSE
						SELECT @vSubResult = FORMATMESSAGE('%s%s%s', Nam, @HundredWord, @vSubResult) FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100)
				END
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @v000Num = 1 AND @vIndex > 0 AND @vIndex < 2
					SET @vSubResult = ''
				IF @v000Num = 1 AND @vIndex >= 2
					SET @vSubResult = 'un'

				SET @vSubResult = FORMATMESSAGE('%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN ' '+ CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END + ' ' + @AndWord
																		WHEN @vIndex=3 THEN ' '+ CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN ' '+ CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN ' '+ (CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END) + ' ' + TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN ' '+ TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		ELSE ''
																	END)
																	
				IF @vIndex <= 1
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
	SELECT dbo.MoneyToWords_IT(3201001.25)
	SELECT dbo.MoneyToWords_IT(123456789.56)
	SELECT dbo.MoneyToWords_IT(1201001.02)
	SELECT dbo.MoneyToWords_IT(1001.22)
	SELECT dbo.MoneyToWords_IT(205.56)
	SELECT dbo.MoneyToWords_IT(45.1)
	SELECT dbo.MoneyToWords_IT(45.09)
	SELECT dbo.MoneyToWords_IT(0.09)
	SELECT dbo.MoneyToWords_IT(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_IT(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_IT(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_IT(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_IT(100000000000000)
*/