--======================================================
-- Usage:	Lib: MoneyToWords in Lithuanian (LT) 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-lithuanian/en/lit/
-- History:
-- Date			Author		Description
-- 2021-01-10	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_LT
GO
CREATE FUNCTION dbo.MoneyToWords_LT(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'vienas'),(2,N'du'),(3,N'trys'),(4,N'keturi'),(5,N'penki'),(6,N'šeši'),(7,N'septyni'),(8,N'aštuoni'),(9,N'devyni'),
			(11,N'vienuolika'),(12,N'dvylika'),(13,N'trylika'),(14,N'keturiolika'),(15,N'penkiolika'),(16,N'šešiolika'),(17,N'septyniolika'),(18,N'aštuoniolika'),(19,N'devyniolika'),
			(10,N'dešimt'),(20,N'dvidešimt'),(30,N'trisdešimt'),(40,N'keturiasdešimt'),(50,N'penkiasdešimt'),(60,N'šešiasdešimt'),(70,N'septyniasdešimt'),(80,N'aštuoniasdešimt'),(90,N'devyniasdešimt')

	DECLARE @ZeroWord			NVARCHAR(20) = N'nulis'
	DECLARE @DotWord			NVARCHAR(20) = N'kablelis'
	DECLARE @AndWord			NVARCHAR(20) = N''
	DECLARE @HundredWord		NVARCHAR(20) = N'šimtas'
	DECLARE @HundredWords		NVARCHAR(20) = N'šimtai'
	DECLARE @ThousandWord		NVARCHAR(20) = N'tūkstantis'
	DECLARE @ThousandWords		NVARCHAR(20) = N'tūkstančiai'
	DECLARE @MillionWord		NVARCHAR(20) = N'milijonas'
	DECLARE @MillionWords		NVARCHAR(20) = N'milijonai'
	DECLARE @BillionWord		NVARCHAR(20) = N'milijardas'
	DECLARE @BillionWords		NVARCHAR(20) = N'milijardai'
	DECLARE @TrillionWord		NVARCHAR(20) = N'trilijonas'
	DECLARE @TrillionWords		NVARCHAR(20) = N'trilijonai'
	DECLARE @QuadrillionWord	NVARCHAR(20) = N'kvadrilijonas'
	DECLARE @QuadrillionWords	NVARCHAR(20) = N'kvadrilijonai'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_LT(@vDecimalNum)
	
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
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s %s %s', 
																CASE WHEN Num > 1 THEN Nam ELSE N'' END,
																CASE WHEN Num > 1 THEN @HundredWords ELSE @HundredWord END,
																@vSubResult))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @vIndex >= 1 AND @v000Num = 1
					SET @vSubResult = N''

				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex=5 THEN CASE WHEN @v000Num > 1 THEN @QuadrillionWords ELSE @QuadrillionWord END
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
	SELECT dbo.MoneyToWords_LT(3201001.25)
	SELECT dbo.MoneyToWords_LT(123456789.56)
	SELECT dbo.MoneyToWords_LT(123000789.56)
	SELECT dbo.MoneyToWords_LT(123010789.56)
	SELECT dbo.MoneyToWords_LT(123004789.56)
	SELECT dbo.MoneyToWords_LT(123904789.56)
	SELECT dbo.MoneyToWords_LT(205.56)
	SELECT dbo.MoneyToWords_LT(45.1)
	SELECT dbo.MoneyToWords_LT(45.09)
	SELECT dbo.MoneyToWords_LT(0.09)
	SELECT dbo.MoneyToWords_LT(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_LT(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_LT(123234567896789.02)--123 234 567 896 789.02	
	SELECT dbo.MoneyToWords_LT(999999999999999.99)--999 999 999 999 999.99
	SELECT dbo.MoneyToWords_LT(100000000000000)
*/