--======================================================
-- Usage:	Lib: MoneyToWords in Slovene (SL)
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-slovene/en/slv/
-- History:
-- Date			Author		Description
-- 2021-01-10	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_SL
GO
CREATE FUNCTION dbo.MoneyToWords_SL(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'ena'),(2,N'dve'),(3,N'tri'),(4,N'štiri'),(5,N'pet'),(6,N'šest'),(7,N'sedem'),(8,N'osem'),(9,N'devet'),
			(11,N'enajst'),(12,N'dvanajst'),(13,N'trinajst'),(14,N'štirinajst'),(15,N'petnajst'),(16,N'šestnajst'),(17,N'sedemnajst'),(18,N'osemnajst'),(19,N'devetnajst'),
			(10,N'deset'),(20,N'dvajset'),(30,N'trideset'),(40,N'štirideset'),(50,N'petdeset'),(60,N'šestdeset'),(70,N'sedemdeset'),(80,N'osemdeset'),(90,N'devetdeset')

	DECLARE @ZeroWord		NVARCHAR(20) = N'nič'
	DECLARE @DotWord		NVARCHAR(20) = N'celih'
	DECLARE @AndWord		NVARCHAR(20) = N'in'
	DECLARE @HundredWord	NVARCHAR(20) = N'sto'
	DECLARE @HundredWords	NVARCHAR(20) = N'sto'
	DECLARE @ThousandWord	NVARCHAR(20) = N'tisoč'
	DECLARE @ThousandWords	NVARCHAR(20) = N'tisoč'
	DECLARE @MillionWord	NVARCHAR(20) = N'milijon'
	DECLARE @MillionWords	NVARCHAR(20) = N'milijona'
	DECLARE @MillionWordss	NVARCHAR(20) = N'milijonov'
	DECLARE @BillionWord	NVARCHAR(20) = N'milijarda'
	DECLARE @BillionWords	NVARCHAR(20) = N'milijardi'
	DECLARE @TrillionWord	NVARCHAR(20) = N'bilijon'
	DECLARE @TrillionWords	NVARCHAR(20) = N'bilijoni'

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
					SELECT @vSubResult = LTRIM(FORMATMESSAGE('%s%s%s', @vSubResult, @AndWord, Nam)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s%s %s', CASE WHEN Num>1 THEN Nam ELSE N'' END, CASE WHEN Num>1 THEN @HundredWords ELSE @HundredWord END, @vSubResult))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @vIndex = 1 AND @v000Num = 1
					SET @vSubResult = @ThousandWord
				ELSE IF @vIndex = 2 AND @v000Num = 1
					SET @vSubResult = @MillionWord
				ELSE IF @vIndex = 3 AND @v000Num = 1
					SET @vSubResult = @BillionWord
				ELSE IF @vIndex = 4 AND @v000Num = 1
					SET @vSubResult = @TrillionWord
				ELSE
					SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																			WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																			WHEN @vIndex=2 THEN CASE WHEN @v000Num = 2 THEN @MillionWords WHEN @v000Num > 2 THEN @MillionWordss ELSE @MillionWord END
																			WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																			WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																			ELSE N''
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
	SELECT dbo.MoneyToWords_SL(3201001.25)
	SELECT dbo.MoneyToWords_SL(123456789.56)
	SELECT dbo.MoneyToWords_SL(123000789.56)
	SELECT dbo.MoneyToWords_SL(123010789.56)
	SELECT dbo.MoneyToWords_SL(123004789.56)
	SELECT dbo.MoneyToWords_SL(123904789.56)
	SELECT dbo.MoneyToWords_SL(205.56)
	SELECT dbo.MoneyToWords_SL(45.1)
	SELECT dbo.MoneyToWords_SL(45.09)
	SELECT dbo.MoneyToWords_SL(0.09)
	SELECT dbo.MoneyToWords_SL(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_SL(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_SL(123234567896789.02)--123 234 567 896 789.02	
	SELECT dbo.MoneyToWords_SL(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_SL(100000000000000)
*/