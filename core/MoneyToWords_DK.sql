--======================================================
-- Usage:	Lib: MoneyToWords in Denish 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-danish/en/dan/
-- History:
-- Date			Author		Description
-- 2021-01-02	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_DK
GO
CREATE FUNCTION dbo.MoneyToWords_DK(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'en'),(2,N'to'),(3,N'tre'),(4,N'fire'),(5,N'fem'),(6,N'seks'),(7,N'syv'),(8,N'otte'),(9,N'ni'),
			(11,N'elleve'),(12,N'tolv'),(13,N'tretten'),(14,N'fjorten'),(15,N'femten'),(16,N'seksten'),(17,N'sytten'),(18,N'atten'),(19,N'nitten'),
			(10,N'ti'),(20,N'tyve'),(30,N'tredive'),(40,N'fyrre'),(50,N'halvtreds'),(60,N'tres'),(70,N'halvfjerds'),(80,N'firs'),(90,N'halvfems')

	DECLARE @ZeroWord		NVARCHAR(20) = N'nul'
	DECLARE @DotWord		NVARCHAR(20) = N'komma'
	DECLARE @AndWord		NVARCHAR(20) = N'og'
	DECLARE @HundredWord	NVARCHAR(20) = N'hundred'
	DECLARE @HundredWords	NVARCHAR(20) = N'hundrede'
	DECLARE @ThousandWord	NVARCHAR(20) = N'tusind'
	DECLARE @ThousandWords	NVARCHAR(20) = N'tusinde'
	DECLARE @MillionWord	NVARCHAR(20) = N'million'
	DECLARE @MillionWords	NVARCHAR(20) = N'millioner'
	DECLARE @BillionWord	NVARCHAR(20) = N'milliard'
	DECLARE @BillionWords	NVARCHAR(20) = N'milliard'
	DECLARE @TrillionWord	NVARCHAR(20) = N'billion'
	DECLARE @TrillionWords	NVARCHAR(20) = N'billion'

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
					SELECT @vSubResult = RTRIM(FORMATMESSAGE('%s%s%s', @vSubResult, @AndWord, Nam)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					IF @v000Num = 100 AND @vIndex = 0
						SET @vSubResult = @HundredWord
					ELSE
						SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s %s %s', Nam, 
																		CASE WHEN Num > 1 THEN @HundredWords ELSE @HundredWord END, 
																		CASE WHEN @v00Num > 0 THEN @AndWord + N' ' + @vSubResult ELSE N'' END))
						FROM	@tDict
						WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @v000Num = 1 AND @vIndex = 1 AND @vPrev000Number % 1000 = 0
					SET @vSubResult = 'et'

				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN (CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END) + ' ' + TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		ELSE ''
																	END)
				
				IF @vIndex = 1 AND @vPrev000Number % 1000 > 0 AND @vPrev000Number % 1000 < 10
					SET @vResult = FORMATMESSAGE('%s %s %s', LTRIM(@vSubResult), @AndWord, @vResult)
				ELSE
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
	SELECT dbo.MoneyToWords_DK(3201001.25)
	SELECT dbo.MoneyToWords_DK(123456789.56)
	SELECT dbo.MoneyToWords_DK(123000789.56)
	SELECT dbo.MoneyToWords_DK(123010789.56)
	SELECT dbo.MoneyToWords_DK(123004789.56)
	SELECT dbo.MoneyToWords_DK(123904789.56)
	SELECT dbo.MoneyToWords_DK(205.56)
	SELECT dbo.MoneyToWords_DK(45.1)
	SELECT dbo.MoneyToWords_DK(45.09)
	SELECT dbo.MoneyToWords_DK(0.09)
	SELECT dbo.MoneyToWords_DK(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_DK(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_DK(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_DK(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_DK(100000000000000)
*/