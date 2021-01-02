--======================================================
-- Usage:	Lib: MoneyToWords in Polish  
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-polish/en/pol/
-- History:
-- Date			Author		Description
-- 2021-01-01	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_PL
GO
CREATE FUNCTION dbo.MoneyToWords_PL(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'jeden'),(2,N'dwa'),(3,N'trzy'),(4,N'cztery'),(5,N'pięć'),(6,N'sześć'),(7,N'siedem'),(8,N'osiem'),(9,N'dziewięć'),
			(10,N'dziesięć'),(11,N'jedenaście'),(12,N'dwanaście'),(13,N'trzynaście'),(14,N'czternaście'),(15,N'piętnaście'),(16,N'szesnaście'),(17,N'siedemnaście'),(18,N'osiemnaście'),(19,N'dziewiętnaście'),
			(20,N'dwadzieścia'),(30,N'trzydzieści'),(40,N'czterdzieści'),(50,N'pięćdziesiąt'),(60,N'sześćdziesiąt'),(70,N'siedemdziesiąt'),(80,N'osiemdziesiąt'),(90,N'dziewięćdziesiąt'),
			(100,N'sto'),(200,N'dwieście'),(300,N'trzysta'),(400,N'czterysta'),(500,N'pięćset'),(600,N'sześćset'),(700,N'siedemset'),(800,N'osiemset'),(900,N'dziewięćset')
	
	DECLARE @ZeroWord		NVARCHAR(20) = N'zero'
	DECLARE @DotWord		NVARCHAR(20) = N'przecinek'
	DECLARE @AndWord		NVARCHAR(20) = N'e'
	DECLARE @HundredWord	NVARCHAR(20) = N'sto'
	DECLARE @ThousandWord	NVARCHAR(20) = N'tysięcy'
	DECLARE @ThousandWords	NVARCHAR(20) = N'tysięcy'
	DECLARE @MillionWord	NVARCHAR(20) = N'milion'
	DECLARE @MillionWords	NVARCHAR(20) = N'miliony'
	DECLARE @BillionWord	NVARCHAR(20) = N'miliard'
	DECLARE @BillionWords	NVARCHAR(20) = N'miliardy'--milionów
	DECLARE @TrillionWord	NVARCHAR(20) = N'bilion'
	DECLARE @TrillionWords	NVARCHAR(20) = N'biliony'--bilionów

	-- decimal number	
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_PL(@vDecimalNum)
	
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
					SELECT @vSubResult = FORMATMESSAGE('%s %s', Nam, @vSubResult) FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100) * 100
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 AND @v000Num = 1 THEN N'tysiąc' --only 001000
																		WHEN @vIndex=1 AND @v000Num%10 IN (2,3,4) THEN N'tysiące' --xx2000 / xx3000/ xx4000
																		WHEN @vIndex=1 THEN @ThousandWord
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN (CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END) + ' ' + TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		ELSE ''
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
	SELECT dbo.MoneyToWords_PL(3201001.25)
	SELECT dbo.MoneyToWords_PL(123456789.56)
	SELECT dbo.MoneyToWords_PL(123000789.56)
	SELECT dbo.MoneyToWords_PL(123010789.56)
	SELECT dbo.MoneyToWords_PL(123004789.56)
	SELECT dbo.MoneyToWords_PL(123904789.56)
	SELECT dbo.MoneyToWords_PL(205.56)
	SELECT dbo.MoneyToWords_PL(45.1)
	SELECT dbo.MoneyToWords_PL(45.09)
	SELECT dbo.MoneyToWords_PL(0.09)
	SELECT dbo.MoneyToWords_PL(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_PL(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_PL(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_PL(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_PL(100000000000000)
*/