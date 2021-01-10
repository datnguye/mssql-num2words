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
	VALUES	(1,N'jedna'),(2,N'dva'),(3,N'tři'),(4,N'čtyři'),(5,N'pět'),(6,N'šest'),(7,N'sedm'),(8,N'osm'),(9,N'devět'),
			(11,N'jedenáct'),(12,N'dvanáct'),(13,N'třináct'),(14,N'čtrnáct'),(15,N'patnáct'),(16,N'šestnáct'),(17,N'sedmnáct'),(18,N'osmnáct'),(19,N'devatenáct'),
			(10,N'deset'),(20,N'dvacet'),(30,N'třicet'),(40,N'čtyřicet'),(50,N'padesát'),(60,N'šedesát'),(70,N'sedmdesát'),(80,N'osmdesát'),(90,N'devadesát'),
			(100,N'sto'),(200,N'dvě stě'),(300,N'tři sta'),(400,N'čtyři sta'),(500,N'pět set'),(600,N'šest set'),(700,N'sedm set'),(800,N'osm set'),(900,N'devět set')

	DECLARE @ZeroWord		NVARCHAR(20) = N''
	DECLARE @DotWord		NVARCHAR(20) = N''
	DECLARE @AndWord		NVARCHAR(20) = N''
	DECLARE @HundredWord	NVARCHAR(20) = N''
	DECLARE @HundredWords	NVARCHAR(20) = N''
	DECLARE @ThousandWord	NVARCHAR(20) = N''
	DECLARE @ThousandWords	NVARCHAR(20) = N''
	DECLARE @MillionWord	NVARCHAR(20) = N''
	DECLARE @MillionWords	NVARCHAR(20) = N''
	DECLARE @MillionWordss	NVARCHAR(20) = N''
	DECLARE @BillionWord	NVARCHAR(20) = N''
	DECLARE @BillionWords	NVARCHAR(20) = N''
	DECLARE @BillionWordss	NVARCHAR(20) = N''
	DECLARE @TrillionWord	NVARCHAR(20) = N''
	DECLARE @TrillionWords	NVARCHAR(20) = N''
	DECLARE @TrillionWordss	NVARCHAR(20) = N''

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_SL(@vDecimalNum)
	
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
					SELECT @vSubResult = RTRIM(FORMATMESSAGE('%s %s', Nam, @vSubResult)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s %s', Nam, @vSubResult))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100) * 100
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
																								+ CASE WHEN @v000Num%100 IN (2,3,4) THEN N'e' ELSE N'' END
																			WHEN @vIndex=2 THEN CASE 
																									WHEN @v000Num%100 IN (2,3,4) THEN @MillionWords
																									WHEN @v000Num%100 > 4 THEN @MillionWordss
																									ELSE @MillionWord 
																								END
																			WHEN @vIndex=3 THEN CASE 
																									WHEN @v000Num%100 IN (2,3,4) THEN @BillionWords
																									WHEN @v000Num%100 > 4 THEN @BillionWordss
																									ELSE @BillionWord 
																								END
																			WHEN @vIndex=4 THEN CASE 
																									WHEN @v000Num%100 IN (2,3,4) THEN @TrillionWords
																									WHEN @v000Num%100 > 4 THEN @TrillionWordss
																									ELSE @TrillionWord 
																								END
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