--======================================================
-- Usage:	Lib: MoneyToWords in Czech 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-czech/en/ces/
-- History:
-- Date			Author		Description
-- 2021-01-03	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_CZ
GO
CREATE FUNCTION dbo.MoneyToWords_CZ(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'один'),(2,N'две'),(3,N'три'),(4,N'четыре'),(5,N'пять'),(6,N'шесть'),(7,N'семь'),(8,N'восемь'),(9,N'девять'),
			(11,N'одиннадцать'),(12,N'двенадцать'),(13,N'тринадцать'),(14,N'четырнадцать'),(15,N'пятнадцать'),(16,N'шестнадцать'),(17,N'семнадцать'),(18,N'восемнадцать'),(19,N'девятнадцать'),
			(10,N'десять'),(20,N'двадцать'),(30,N'тридцать'),(40,N'сорок'),(50,N'пятьдесят'),(60,N'шестьдесят'),(70,N'семьдесят'),(80,N'восемьдесят'),(90,N'девяносто'),
			(100,N'сто'),(200,N'двести'),(300,N'триста'),(400,N'четыреста'),(500,N'пятьсот'),(600,N'шестьсот'),(700,N'семьсот'),(800,N'восемьсот'),(900,N'девятьсот'),
			(1000,N'тысяча'),(2000,N'две тысячи'),(3000,N'три тысячи'),(4000,N'четыре тысячи')

	DECLARE @ZeroWord		NVARCHAR(20) = N'ноль'
	DECLARE @DotWord		NVARCHAR(20) = N'запятая'
	DECLARE @AndWord		NVARCHAR(20) = N'и'
	DECLARE @HundredWord	NVARCHAR(20) = N'сто'
	DECLARE @HundredWords	NVARCHAR(20) = N'сто'
	DECLARE @ThousandWord	NVARCHAR(20) = N'тысяч'
	DECLARE @ThousandWords	NVARCHAR(20) = N'тысяч'
	DECLARE @MillionWord	NVARCHAR(20) = N'миллион'
	DECLARE @MillionWords	NVARCHAR(20) = N'миллион'
	DECLARE @BillionWord	NVARCHAR(20) = N'миллиард'
	DECLARE @BillionWords	NVARCHAR(20) = N'миллиард'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_CZ(@vDecimalNum)
	
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
		DECLARE @vPrev000Number DECIMAL(17,2) = 0
		
		WHILE @Number > 0
		BEGIN
			-- from right to left: take first 000
			SET @v000Num = @Number % 1000
			SET @v00Num = @v000Num % 100
			SET @v0Num = @v00Num % 10
			SET @vSubResult = ''
			IF @v000Num > 0
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
					SELECT @vSubResult = RTRIM(FORMATMESSAGE('%s %s', Nam, @vSubResult)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s %s', Nam, @vSubResult))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100) * 100
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @vIndex%3=1 AND @v000Num%1000 = 1
					SELECT	@vSubResult = Nam
					FROM	@tDict
					WHERE	Num = @v000Num%1000 * 1000
				ELSE IF @vIndex%3=1 AND @v000Num%10 IN (2,3,4)
					SET @vSubResult = LTRIM(FORMATMESSAGE('%s%s%s',
														COALESCE((SELECT Nam+N' ' FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100) * 100),N''),
														COALESCE((SELECT Nam+N' ' FROM @tDict WHERE Num = CONVERT(INT,@v00Num / 10) * 10),N''),
														(SELECT Nam FROM @tDict WHERE Num = @v000Num%10*1000)))
				ELSE
					SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																			WHEN @vIndex=0 THEN N''
																			WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																			WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																			WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																			WHEN @vIndex>3 AND @vIndex%3=2 THEN (CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END) + ' ' + TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																			WHEN @vIndex>3 AND @vIndex%3=0 THEN TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																			ELSE @ThousandWords
																		END)
				
				IF @vIndex = 0 OR (@vIndex = 1 AND @vPrev000Number%1000 < 100 AND @vPrev000Number%1000 > 0) OR @vResult = ''
					SET @vResult = FORMATMESSAGE('%s %s', LTRIM(@vSubResult), @vResult)
				ELSE
					SET @vResult = FORMATMESSAGE('%s, %s', LTRIM(@vSubResult), @vResult)
			END

			-- next 000 (to left)
			SET @vIndex = @vIndex + 1
			SET @vPrev000Number = @Number
			SET @Number = FLOOR(@Number / 1000)
		END
	END

	SET @vResult = FORMATMESSAGE('%s %s', TRIM(@vResult), COALESCE(@DotWord + ' ' + NULLIF(@vSubDecimalResult,''), ''))
	
	-- result
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_CZ(3201001.25)
	SELECT dbo.MoneyToWords_CZ(123456789.56)
	SELECT dbo.MoneyToWords_CZ(123000789.56)
	SELECT dbo.MoneyToWords_CZ(123010789.56)
	SELECT dbo.MoneyToWords_CZ(123004789.56)
	SELECT dbo.MoneyToWords_CZ(123904789.56)
	SELECT dbo.MoneyToWords_CZ(205.56)
	SELECT dbo.MoneyToWords_CZ(45.1)
	SELECT dbo.MoneyToWords_CZ(45.09)
	SELECT dbo.MoneyToWords_CZ(0.09)
	SELECT dbo.MoneyToWords_CZ(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_CZ(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_CZ(123234567896789.02)--123 234 567 896 789.02	
	SELECT dbo.MoneyToWords_CZ(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_CZ(100000000000000)
*/