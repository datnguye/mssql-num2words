--======================================================
-- Usage:	Lib: MoneyToWords in Japanese (in Kanji)
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- History:
-- References:
-- https://www.fluentin3months.com/japanese-numbers/
-- Date			Author		Description
-- 2020-12-31	NV			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_JA
GO
CREATE FUNCTION dbo.MoneyToWords_JA(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'一'),(2,N'二'),(3,N'三'),(4,N'四'),(5,N'五'),(6,N'六'),(7,N'七'),(8,N'八'),(9,N'九'),(10,N'十'),
			(0,N'')
	
	DECLARE @ZeroWord				NVARCHAR(10) = N'零'
	DECLARE @DotWord				NVARCHAR(10) = N'点'
	DECLARE @AndWord				NVARCHAR(10) = N''
	DECLARE @TenWord				NVARCHAR(10) = N'十'
	DECLARE @HundredWord			NVARCHAR(10) = N'百'
	DECLARE @ThousandWord			NVARCHAR(10) = N'千'
	DECLARE @ManWord				NVARCHAR(10) = N'万'--man (1 0000)
	DECLARE @DoubleManWord			NVARCHAR(10) = N'億'--ichioku (1 0000 0000)
	DECLARE @ChoWord				NVARCHAR(10) = N'兆'--icchou (1 0000 0000 0000)

	-- decimal number	
	DECLARE @vDecimalNum INT = (@Number - FLOOR(@Number)) * 100
	DECLARE @vLoop SMALLINT = CONVERT(SMALLINT, SQL_VARIANT_PROPERTY(@Number, 'Scale'))
	DECLARE @vSubDecimalResult	NVARCHAR(MAX) = N''
	IF @vDecimalNum > 0
	BEGIN
		WHILE @vLoop > 0
		BEGIN
			IF @vDecimalNum % 10 = 0
				SET @vSubDecimalResult = FORMATMESSAGE(N'%s%s', @ZeroWord, @vSubDecimalResult)
			ELSE
				SELECT	@vSubDecimalResult = FORMATMESSAGE(N'%s%s', Nam, @vSubDecimalResult)
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
		DECLARE @v0000Num DECIMAL(15,0) = 0
		DECLARE @v000Num DECIMAL(15,0) = 0
		DECLARE @v00Num DECIMAL(15,0) = 0
		DECLARE @v0Num DECIMAL(15,0) = 0
		DECLARE @vIndex SMALLINT = 0
		
		WHILE @Number > 0
		BEGIN
			-- from right to left: take first 0000
			SET @v0000Num = @Number % 10000
			SET @v000Num = @v0000Num % 1000
			SET @v00Num = @v000Num % 100
			SET @v0Num = @v00Num % 10
			IF @v0000Num = 0
			BEGIN
				SET @vSubResult = N''
			END
			ELSE 
			BEGIN 
				--00
				IF @v00Num <= 10
				BEGIN
					-- less than or equal 10
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than 10
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SELECT @vSubResult = FORMATMESSAGE(N'%s%s%s', Nam, @TenWord, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v00Num/10)
				END

				--000
				IF @v000Num = 100
					SET @vSubResult = @HundredWord
				ELSE IF @v000Num > 100
					SELECT @vSubResult = FORMATMESSAGE(N'%s%s%s', CASE WHEN Num > 1 THEN Nam ELSE '' END, @HundredWord, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v000Num/100)

				--0000
				IF @v0000Num = 1000
					SET @vSubResult = @ThousandWord
				ELSE IF @v0000Num > 1000
					SELECT @vSubResult = FORMATMESSAGE(N'%s%s%s', CASE WHEN Num > 1 THEN Nam ELSE '' END, @ThousandWord, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v0000Num/1000)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN

				SET @vSubResult = FORMATMESSAGE(N'%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN @ManWord
																		WHEN @vIndex=2 THEN @DoubleManWord
																		WHEN @vIndex=3 THEN @ChoWord
																		ELSE ''
																	END)

				SET @vResult = FORMATMESSAGE(N'%s%s', @vSubResult, @vResult)
			END

			-- next 000 (to left)
			SET @vIndex = @vIndex + 1
			SET @Number = FLOOR(@Number / 10000)
		END
	END

	SET @vResult = FORMATMESSAGE(N'%s%s', TRIM(@vResult), COALESCE(@DotWord + NULLIF(@vSubDecimalResult,N''), N''))
	
	-- result
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_JA(3201001.25)
	SELECT dbo.MoneyToWords_JA(123456789.56)
	SELECT dbo.MoneyToWords_JA(123000789.56)
	SELECT dbo.MoneyToWords_JA(123010789.56)
	SELECT dbo.MoneyToWords_JA(123004789.56)
	SELECT dbo.MoneyToWords_JA(123904789.56)
	SELECT dbo.MoneyToWords_JA(205.56)
	SELECT dbo.MoneyToWords_JA(45.1)
	SELECT dbo.MoneyToWords_JA(45.09)
	SELECT dbo.MoneyToWords_JA(0.09)
	SELECT dbo.MoneyToWords_JA(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_JA(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_JA(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_JA(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_JA(100000000000000)
*/