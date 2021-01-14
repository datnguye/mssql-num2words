--======================================================
-- Usage:	Lib: MoneyToWords in Serbian (SR) 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-serbian/en/srp/
-- History:
-- Date			Author		Description
-- 2021-01-12	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_SR
GO
CREATE FUNCTION dbo.MoneyToWords_SR(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'један'),(2,N'два'),(3,N'три'),(4,N'четири'),(5,N'пет'),(6,N'шест'),(7,N'седам'),(8,N'осам'),(9,N'девет'),
			(11,N'једанаест'),(12,N'дванаест'),(13,N'тринаест'),(14,N'четрнаест'),(15,N'петнаест'),(16,N'шеснаест'),(17,N'седамнаест'),(18,N'осамнаест'),(19,N'деветнаест'),
			(10,N'десет'),(20,N'двадесет'),(30,N'тридесет'),(40,N'четрдесет'),(50,N'педесет'),(60,N'шездесет'),(70,N'седамдесет'),(80,N'осамдесет'),(90,N'деведесет')

	DECLARE @ZeroWord		NVARCHAR(20) = N'нула'
	DECLARE @DotWord		NVARCHAR(20) = N'поен'
	DECLARE @AndWord		NVARCHAR(20) = N'и'
	DECLARE @HundredWord	NVARCHAR(20) = N'сто'
	DECLARE @HundredWordx	NVARCHAR(20) = N'ста'--2,3
	DECLARE @HundredWords	NVARCHAR(20) = N'сто'
	DECLARE @ThousandWord	NVARCHAR(20) = N'хиљада'
	DECLARE @ThousandWordx	NVARCHAR(20) = N'хиљаде'--2,3,4
	DECLARE @ThousandWords	NVARCHAR(20) = N'хиљада'
	DECLARE @MillionWord	NVARCHAR(20) = N'милион'
	DECLARE @MillionWords	NVARCHAR(20) = N'милиона'
	DECLARE @BillionWord	NVARCHAR(20) = N'милијарда'
	DECLARE @BillionWordx	NVARCHAR(20) = N'милијарде'--2,3,4
	DECLARE @BillionWords	NVARCHAR(20) = N'милијарди'
	DECLARE @TrillionWord	NVARCHAR(20) = N'билион'
	DECLARE @TrillionWords	NVARCHAR(20) = N'билиона'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_SR(@vDecimalNum)
	
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
					SELECT @vSubResult = RTRIM(FORMATMESSAGE('%s %s %s', Nam, @AndWord, @vSubResult)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s%s %s', 
														CASE WHEN Num>1 THEN Nam ELSE N'' END,
														CASE WHEN Num=1 THEN @HundredWord WHEN Num IN (2) THEN N' '+@HundredWord WHEN Num IN (3) THEN @HundredWordx ELSE @HundredWords END,
														@vSubResult))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @vIndex=1 AND @v000Num=1
					SET @vSubResult = N''

				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num=1 THEN @ThousandWord WHEN @v000Num IN (2,3,4) THEN @ThousandWordx ELSE @ThousandWords END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num=1 THEN @BillionWord WHEN @v000Num IN (2,3,4) THEN @BillionWordx ELSE @BillionWords END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		ELSE N''
																	END)
				
				IF (@vIndex = 1 AND @vPrev000Number%1000 < 100) OR @vResult = ''
					SET @vResult = RTRIM(FORMATMESSAGE('%s %s', @vSubResult, @vResult))
				ELSE 
					SET @vResult = FORMATMESSAGE('%s, %s', @vSubResult, @vResult)
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
	SELECT dbo.MoneyToWords_SR(3201001.25)
	SELECT dbo.MoneyToWords_SR(123456789.56)
	SELECT dbo.MoneyToWords_SR(123000789.56)
	SELECT dbo.MoneyToWords_SR(123010789.56)
	SELECT dbo.MoneyToWords_SR(123004789.56)
	SELECT dbo.MoneyToWords_SR(123904789.56)
	SELECT dbo.MoneyToWords_SR(205.56)
	SELECT dbo.MoneyToWords_SR(45.1)
	SELECT dbo.MoneyToWords_SR(45.09)
	SELECT dbo.MoneyToWords_SR(0.09)
	SELECT dbo.MoneyToWords_SR(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_SR(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_SR(123234567896789.02)--123 234 567 896 789.02	
	SELECT dbo.MoneyToWords_SR(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_SR(100000000000000)
*/