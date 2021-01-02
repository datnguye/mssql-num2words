--======================================================
-- Usage:	Lib: MoneyToWords in Turkish 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- 
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
	VALUES	(1,N'um'),(2,N'dois'),(3,N'três'),(4,N'quatro'),(5,N'cinco'),(6,N'seis'),(7,N'sete'),(8,N'oito'),(9,N'nove'),
			(10,N'dez'),(11,N'onze'),(12,N'doze'),(13,N'treze'),(14,N'catorze'),(15,N'quinze'),(16,N'dezesseis'),(17,N'dezessete'),(18,N'dezoito'),(19,N'dezenove'),
			(20,N'vinte'),(30,N'trinta'),(40,N'quarenta'),(50,N'cinqüenta'),(60,N'sessenta'),(70,N'setenta'),(80,N'oitenta'),(90,N'noventa'),
			(100,N'cento'),(200,N'duzentos'),(300,N'trezentos'),(400,N'quatrocentos'),(500,N'quinhentos'),(600,N'seiscentos'),(700,N'setecentos'),(800,N'oitocentos'),(900,N'novecentos')
	
	DECLARE @ZeroWord		NVARCHAR(20) = N'zero'
	DECLARE @DotWord		NVARCHAR(20) = N'vírgula'
	DECLARE @AndWord		NVARCHAR(20) = N'e'
	DECLARE @HundredWord	NVARCHAR(20) = N'cem'
	DECLARE @ThousandWord	NVARCHAR(20) = N'mil'
	DECLARE @ThousandWords	NVARCHAR(20) = N'mil'
	DECLARE @MillionWord	NVARCHAR(20) = N'milhão'
	DECLARE @MillionWords	NVARCHAR(20) = N'milhões'
	DECLARE @BillionWord	NVARCHAR(20) = N'mil milhões'
	DECLARE @BillionWords	NVARCHAR(20) = N'mil milhões'
	DECLARE @TrillionWord	NVARCHAR(20) = N'bilião'
	DECLARE @TrillionWords	NVARCHAR(20) = N'biliões'

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
		DECLARE @vPrev000Number DECIMAL(17,2) = 0
		
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
					SELECT @vSubResult = FORMATMESSAGE('%s %s %s', Nam, @AndWord, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10 
				END

				--000
				IF @v000Num = 100
					SET @vSubResult = @HundredWord
				ELSE IF @v00Num = 0
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100)*100
				ELSE IF @v000Num > 100
					SELECT @vSubResult = FORMATMESSAGE('%s %s %s', Nam, @AndWord, @vSubResult) FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100)*100
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN (CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END) + ' ' + TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		ELSE ''
																	END)

				IF @vResult <> '' AND @vIndex >=1 AND (@vPrev000Number % 100 = 0 OR @vPrev000Number < 10)
					SET @vResult = FORMATMESSAGE('%s %s %s', @vSubResult, @AndWord, @vResult)
				ELSE
					SET @vResult = FORMATMESSAGE('%s %s', @vSubResult, @vResult)
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