--======================================================
-- Usage:	Lib: MoneyToWords in Indonesian (ID)
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-indonesian/en/ind/
-- History:
-- Date			Author		Description
-- 2021-01-10	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_ID
GO
CREATE FUNCTION dbo.MoneyToWords_ID(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'satu'),(2,N'dua'),(3,N'tiga'),(4,N'empat'),(5,N'lima'),(6,N'enam'),(7,N'tujuh'),(8,N'delapan'),(9,N'sembilan'),
			(11,N'sebelas'),(12,N'dua belas'),(13,N'tiga belas'),(14,N'empat belas'),(15,N'lima belas'),(16,N'enam belas'),(17,N'tujuh belas'),(18,N'delapan belas'),(19,N'sembilan belas'),
			(10,N'sepuluh'),(20,N'dua puluh'),(30,N'tiga puluh'),(40,N'empat puluh'),(50,N'lima puluh'),(60,N'enam puluh'),(70,N'tujuh puluh'),(80,N'delapan puluh'),(90,N'sembilan puluh')
	
	DECLARE @ZeroWord			NVARCHAR(20) = N'nol'
	DECLARE @DotWord			NVARCHAR(20) = N'koma'
	DECLARE @AndWord			NVARCHAR(20) = N''
	DECLARE @1HundredPrefix		NVARCHAR(20) = N'se'
	DECLARE @HundredWord		NVARCHAR(20) = N'ratus'
	DECLARE @ThousandWord		NVARCHAR(20) = N'ribu'
	DECLARE @MillionWord		NVARCHAR(20) = N'juta'
	DECLARE @BillionWord		NVARCHAR(20) = N'milyar'
	DECLARE @TrillionWord		NVARCHAR(20) = N'seribu milyar'

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
					SELECT @vSubResult = FORMATMESSAGE('%s %s', Nam, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10 
				END

				--000
				IF @v000Num > 99
					SELECT	@vSubResult = FORMATMESSAGE('%s%s %s', (CASE WHEN Num > 1 THEN Nam+N' ' ELSE N'se' END), @HundredWord, @vSubResult) 
					FROM	@tDict
					WHERE	Num = FLOOR(@v000Num/100)
			END
			
			--000 xxx
			IF @vSubResult <> '' 
			BEGIN
				IF @vIndex >= 3 AND @v000Num = 1
					SET @vSubResult = N''

				SET @vSubResult = FORMATMESSAGE('%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num = 1 THEN N'se' ELSE N' ' END+@ThousandWord
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num = 1 THEN N'se' ELSE N' ' END+@MillionWord
																		WHEN @vIndex=3 THEN N' '+@BillionWord
																		WHEN @vIndex=4 THEN N' '+@TrillionWord
																		ELSE N''
																	END)
																	
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
	SELECT dbo.MoneyToWords_ID(3201001.25)
	SELECT dbo.MoneyToWords_ID(123456789.56)
	SELECT dbo.MoneyToWords_ID(123000789.56)
	SELECT dbo.MoneyToWords_ID(123010789.56)
	SELECT dbo.MoneyToWords_ID(123004789.56)
	SELECT dbo.MoneyToWords_ID(123904789.56)
	SELECT dbo.MoneyToWords_ID(205.56)
	SELECT dbo.MoneyToWords_ID(45.1)
	SELECT dbo.MoneyToWords_ID(45.09)
	SELECT dbo.MoneyToWords_ID(0.09)
	SELECT dbo.MoneyToWords_ID(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_ID(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_ID(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_ID(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_ID(100000000000000)
*/