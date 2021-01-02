--======================================================
-- Usage:	Lib: MoneyToWords in Turkish 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-turkish/en/tur/
-- History:
-- Date			Author		Description
-- 2021-01-01	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_TR
GO
CREATE FUNCTION dbo.MoneyToWords_TR(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'bir'),(2,N'iki'),(3,N'üç'),(4,N'dört'),(5,N'beş'),(6,N'altı'),(7,N'yedi'),(8,N'sekiz'),(9,N'dokuz'),
			(10,N'on'),(20,N'yirmi'),(30,N'otuz'),(40,N'kırk'),(50,N'elli'),(60,N'altmış'),(70,N'yetmiş'),(80,N'seksen'),(90,N'doksan')

	DECLARE @ZeroWord		NVARCHAR(20) = N'sıfır'
	DECLARE @DotWord		NVARCHAR(20) = N'virgül'
	DECLARE @AndWord		NVARCHAR(20) = N'e'
	DECLARE @HundredWord	NVARCHAR(20) = N'yüz'
	DECLARE @ThousandWord	NVARCHAR(20) = N'bin'
	DECLARE @ThousandWords	NVARCHAR(20) = N'bin'
	DECLARE @MillionWord	NVARCHAR(20) = N'milyon'
	DECLARE @MillionWords	NVARCHAR(20) = N'milyon'
	DECLARE @BillionWord	NVARCHAR(20) = N'milyar'
	DECLARE @BillionWords	NVARCHAR(20) = N'milyar'
	DECLARE @TrillionWord	NVARCHAR(20) = N'trilyon'
	DECLARE @TrillionWords	NVARCHAR(20) = N'trilyon'

	-- decimal number	
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_TR(@vDecimalNum)
	
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
				IF @v00Num < 10
				BEGIN
					-- less than 10
                    SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than or equal 10
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SELECT @vSubResult = RTRIM(FORMATMESSAGE('%s %s', Nam, @vSubResult)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					SELECT @vSubResult = FORMATMESSAGE('%s %s %s', CASE WHEN Num > 1 THEN Nam ELSE '' END, @HundredWord, @vSubResult) FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @v000Num = 1 AND @vIndex = 1
					SET @vSubResult = ''

				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN (CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END) + ' ' + TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		ELSE ''
																	END)

				SET @vResult = FORMATMESSAGE('%s %s', LTRIM(@vSubResult), @vResult)
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
	SELECT dbo.MoneyToWords_TR(3201001.25)
	SELECT dbo.MoneyToWords_TR(123456789.56)
	SELECT dbo.MoneyToWords_TR(123000789.56)
	SELECT dbo.MoneyToWords_TR(123010789.56)
	SELECT dbo.MoneyToWords_TR(123004789.56)
	SELECT dbo.MoneyToWords_TR(123904789.56)
	SELECT dbo.MoneyToWords_TR(205.56)
	SELECT dbo.MoneyToWords_TR(45.1)
	SELECT dbo.MoneyToWords_TR(45.09)
	SELECT dbo.MoneyToWords_TR(0.09)
	SELECT dbo.MoneyToWords_TR(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_TR(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_TR(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_TR(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_TR(100000000000000)
*/