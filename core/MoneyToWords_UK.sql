--======================================================
-- Usage:	Lib: MoneyToWords in Ukrainian (UK) 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-ukrainian/en/ukr/
-- History:
-- Date			Author		Description
-- 2021-01-14	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_UK
GO
CREATE FUNCTION dbo.MoneyToWords_UK(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'один'),(2,N'два'),(3,N'три'),(4,N'чотири'),(5,N'п’ять'),(6,N'шість'),(7,N'сім'),(8,N'вісім'),(9,N'дев’ять'),
			(11,N'одинадцять'),(12,N'дванадцять'),(13,N'тринадцять'),(14,N'чотирнадцять'),(15,N'п’ятнадцять'),(16,N'шістнадцять'),(17,N'сімнадцять'),(18,N'вісімнадцять'),(19,N'дев’ятнадцять'),
			(10,N'десять'),(20,N'двадцять'),(30,N'тридцять'),(40,N'сорок'),(50,N'п’ятдесят'),(60,N'шістдесят'),(70,N'сімдесят'),(80,N'вісімдесят'),(90,N'дев’яносто'),
			(100,N'сто'),(200,N'двісті'),(300,N'триста'),(400,N'чотириста'),(500,N'п’ятсот'),(600,N'шістсот'),(700,N'сімсот'),(800,N'вісімсот'),(900,N'дев’ятсот')

	DECLARE @ZeroWord		NVARCHAR(20) = N'нуль'
	DECLARE @DotWord		NVARCHAR(20) = N'кома'
	DECLARE @AndWord		NVARCHAR(20) = N''
	DECLARE @TwoWordx		NVARCHAR(20) = N'дві'
	--DECLARE @HundredWord	NVARCHAR(20) = N'сто'
	--DECLARE @HundredWords	NVARCHAR(20) = N'сто'
	DECLARE @ThousandWord	NVARCHAR(20) = N'тисяча'
	DECLARE @ThousandWordx	NVARCHAR(20) = N'тисячі'--2,3,4
	DECLARE @ThousandWords	NVARCHAR(20) = N'тисяч'
	DECLARE @MillionWord	NVARCHAR(20) = N'мільйон'
	DECLARE @MillionWords	NVARCHAR(20) = N'мільйон'
	DECLARE @BillionWord	NVARCHAR(20) = N'мільярд'
	DECLARE @BillionWords	NVARCHAR(20) = N'мільярд'
	DECLARE @TrillionWord	NVARCHAR(20) = N'трильйон'
	DECLARE @TrillionWords	NVARCHAR(20) = N'трильйон'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_UK(@vDecimalNum)
	
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
                    SELECT @vSubResult = (CASE WHEN @vIndex>=1 AND Num=2 THEN @TwoWordx ELSE Nam END) FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than 20
					SELECT @vSubResult = (CASE WHEN @vIndex>=1 AND Num=2 THEN @TwoWordx ELSE Nam END) FROM @tDict WHERE Num = @v0Num 
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
				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num=1 THEN @ThousandWord WHEN @v000Num%10 IN (2,3,4) THEN @ThousandWordx ELSE @ThousandWords END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		ELSE N''
																	END)
				
				IF (@vIndex = 1 AND @vPrev000Number%1000 < 100 AND @vPrev000Number%1000 > 0) OR @vResult = N''
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
	SELECT dbo.MoneyToWords_UK(3201001.25)
	SELECT dbo.MoneyToWords_UK(123456789.56)
	SELECT dbo.MoneyToWords_UK(123000789.56)
	SELECT dbo.MoneyToWords_UK(123010789.56)
	SELECT dbo.MoneyToWords_UK(123004789.56)
	SELECT dbo.MoneyToWords_UK(123904789.56)
	SELECT dbo.MoneyToWords_UK(205.56)
	SELECT dbo.MoneyToWords_UK(45.1)
	SELECT dbo.MoneyToWords_UK(45.09)
	SELECT dbo.MoneyToWords_UK(0.09)
	SELECT dbo.MoneyToWords_UK(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_UK(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_UK(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_UK(999999999999999.99)--999 999 999 999 999.99
	SELECT dbo.MoneyToWords_UK(100000000000000)
*/