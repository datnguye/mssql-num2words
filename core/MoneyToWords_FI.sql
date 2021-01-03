--======================================================
-- Usage:	Lib: MoneyToWords in Finish 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-finnish/en/fin/
-- History:
-- Date			Author		Description
-- 2021-01-02	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_FI
GO
CREATE FUNCTION dbo.MoneyToWords_FI(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'yksi'),(2,N'kaksi'),(3,N'kolme'),(4,N'neljä'),(5,N'viisi'),(6,N'kuusi'),(7,N'seitsemän'),(8,N'kahdeksan'),(9,N'yhdeksän'),
			(11,N'yksitoista'),(12,N'kaksitoista'),(13,N'kolmetoista'),(14,N'neljätoista'),(15,N'viisitoista'),(16,N'kuusitoista'),(17,N'seitsemäntoista'),(18,N'kahdeksantoista'),(19,N'yhdeksäntoista'),
			(10,N'kymmenen'),(20,N'kaksikymmentä'),(30,N'kolmekymmentä'),(40,N'neljäkymmentä'),(50,N'viisikymmentä'),(60,N'kuusikymmentä'),(70,N'seitsemänkymmentä'),(80,N'kahdeksankymmentä'),(90,N'yhdeksänkymmentä')

	DECLARE @ZeroWord		NVARCHAR(20) = N'nolla'
	DECLARE @DotWord		NVARCHAR(20) = N'pilkku'
	DECLARE @AndWord		NVARCHAR(20) = N''
	DECLARE @HundredWord	NVARCHAR(20) = N'sata'
	DECLARE @HundredWords	NVARCHAR(20) = N'sataa'
	DECLARE @ThousandWord	NVARCHAR(20) = N'tuhat'
	DECLARE @ThousandWords	NVARCHAR(20) = N'tuhatta'
	DECLARE @MillionWord	NVARCHAR(20) = N'miljoona'
	DECLARE @MillionWords	NVARCHAR(20) = N'miljoonaa'
	DECLARE @BillionWord	NVARCHAR(20) = N'miljardi'
	DECLARE @BillionWords	NVARCHAR(20) = N'miljardia'
	DECLARE @TrillionWord	NVARCHAR(20) = N'biljoona'
	DECLARE @TrillionWords	NVARCHAR(20) = N'biljoonaa'

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
					SELECT @vSubResult = RTRIM(FORMATMESSAGE('%s%s', Nam, @vSubResult)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					IF @v000Num < 200
						SET @vSubResult = FORMATMESSAGE('%s%s', @HundredWord, @vSubResult)
					ELSE
						SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s%s%s', Nam, @HundredWords, @vSubResult))
						FROM	@tDict
						WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @v000Num = 1 AND @vIndex = 1 AND @vPrev000Number % 1000 = 0
					SET @vSubResult = N''

				SET @vSubResult = FORMATMESSAGE('%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN (CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END) + ' ' + TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		ELSE ''
																	END)
				
				SET @vResult = FORMATMESSAGE('%s%s', LTRIM(@vSubResult), @vResult)
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
	SELECT dbo.MoneyToWords_FI(3201001.25)
	SELECT dbo.MoneyToWords_FI(123456789.56)
	SELECT dbo.MoneyToWords_FI(123000789.56)
	SELECT dbo.MoneyToWords_FI(123010789.56)
	SELECT dbo.MoneyToWords_FI(123004789.56)
	SELECT dbo.MoneyToWords_FI(123904789.56)
	SELECT dbo.MoneyToWords_FI(205.56)
	SELECT dbo.MoneyToWords_FI(45.1)
	SELECT dbo.MoneyToWords_FI(45.09)
	SELECT dbo.MoneyToWords_FI(0.09)
	SELECT dbo.MoneyToWords_FI(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_FI(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_FI(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_FI(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_FI(100000000000000)
*/