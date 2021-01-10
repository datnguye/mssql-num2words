--======================================================
-- Usage:	Lib: MoneyToWords in Kazakh (KZ) 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-kazakh/en/kaz/
-- History:
-- Date			Author		Description
-- 2021-01-10	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_KZ
GO
CREATE FUNCTION dbo.MoneyToWords_KZ(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'бір'),(2,N'екі'),(3,N'үш'),(4,N'төрт'),(5,N'бес'),(6,N'алты'),(7,N'жеті'),(8,N'сегіз'),(9,N'тоғыз'),
			(11,N'он бір'),(12,N'он екі'),(13,N'он үш'),(14,N'он төрт'),(15,N'он бес'),(16,N'он алты'),(17,N'он жеті'),(18,N'он сегіз'),(19,N'он тоғыз'),
			(10,N'он'),(20,N'жиырма'),(30,N'отыз'),(40,N'қырық'),(50,N'елу'),(60,N'алпыс'),(70,N'жетпіс'),(80,N'сексен'),(90,N'тоқсан')

	DECLARE @ZeroWord		NVARCHAR(20) = N'нөл'
	DECLARE @DotWord		NVARCHAR(20) = N'балл'
	DECLARE @AndWord		NVARCHAR(20) = N''
	DECLARE @HundredWord	NVARCHAR(20) = N'жүз'
	DECLARE @ThousandWord	NVARCHAR(20) = N'мың'
	DECLARE @MillionWord	NVARCHAR(20) = N'миллион'
	DECLARE @BillionWord	NVARCHAR(20) = N'миллиард'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_KZ(@vDecimalNum)
	
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
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s %s %s', CASE WHEN Num > 1 THEN Nam ELSE N'' END, @HundredWord, @vSubResult))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @vIndex >= 1 AND @v000Num = 1 
					SET @vSubResult = N''

				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN @ThousandWord
																		WHEN @vIndex=2 THEN @MillionWord
																		WHEN @vIndex=3 THEN @BillionWord
																		WHEN @vIndex=4 THEN @ThousandWord + N' ' + @BillionWord
																		WHEN @vIndex=5 THEN @MillionWord + N' ' + @BillionWord
																		ELSE N''
																	END)
				
				SET @vResult = FORMATMESSAGE('%s %s', LTRIM(@vSubResult), @vResult)
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
	SELECT dbo.MoneyToWords_KZ(3201001.25)
	SELECT dbo.MoneyToWords_KZ(123456789.56)
	SELECT dbo.MoneyToWords_KZ(123000789.56)
	SELECT dbo.MoneyToWords_KZ(123010789.56)
	SELECT dbo.MoneyToWords_KZ(123004789.56)
	SELECT dbo.MoneyToWords_KZ(123904789.56)
	SELECT dbo.MoneyToWords_KZ(205.56)
	SELECT dbo.MoneyToWords_KZ(45.1)
	SELECT dbo.MoneyToWords_KZ(45.09)
	SELECT dbo.MoneyToWords_KZ(0.09)
	SELECT dbo.MoneyToWords_KZ(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_KZ(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_KZ(123234567896789.02)--123 234 567 896 789.02	
	SELECT dbo.MoneyToWords_KZ(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_KZ(100000000000000)
*/