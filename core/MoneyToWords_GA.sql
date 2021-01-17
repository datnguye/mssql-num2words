--======================================================
-- Usage:	Lib: MoneyToWords in Irish (ga)
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-irish/en/gle/
-- History:
-- Date			Author		Description
-- 2021-01-17	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_GA
GO
CREATE FUNCTION dbo.MoneyToWords_GA(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'aon'),(2,N'dó'),(3,N'trí'),(4,N'ceathair'),(5,N'cúig'),(6,N'sé'),(7,N'seacht'),(8,N'ocht'),(9,N'naoi'),
			(11,N'aon déag'),(12,N'dó dhéag'),(13,N'trí déag'),(14,N'ceathair déag'),(15,N'cúig déag'),(16,N'sé déag'),(17,N'seacht déag'),(18,N'ocht déag'),(19,N'naoi déag'),
			(10,N'deich'),(20,N'fiche'),(30,N'tríocha'),(40,N'ceathracha'),(50,N'caoga'),(60,N'seasca'),(70,N'seachtó'),(80,N'ochtó'),(90,N'nócha')
	
	DECLARE @ZeroWord			NVARCHAR(20) = N'náid'
	DECLARE @DotWord			NVARCHAR(20) = N'pointe'
	DECLARE @AndWord			NVARCHAR(20) = N'a'
	DECLARE @HundredWord		NVARCHAR(20) = N'céad'
	DECLARE @HundredWords		NVARCHAR(20) = N'céad'
	DECLARE @ThousandWord		NVARCHAR(20) = N'míle'
	DECLARE @ThousandWords		NVARCHAR(20) = N'míle'
	DECLARE @MillionWord		NVARCHAR(20) = N'milliún'
	DECLARE @MillionWords		NVARCHAR(20) = N'milliún'
	DECLARE @BillionWord		NVARCHAR(20) = N'míle'
	DECLARE @BillionWords		NVARCHAR(20) = N'míle'
	DECLARE @TrillionWord		NVARCHAR(20) = N'míle'
	DECLARE @TrillionWords		NVARCHAR(20) = N'míle'

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
				IF @v00Num <= 20
				BEGIN
					-- less than or equal 20
                    SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than 20
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SELECT @vSubResult = FORMATMESSAGE('%s %s %s', Nam, @AndWord, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10 
				END

				--000
				IF @v000Num > 99
				BEGIN
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s %s %s', 
														(CASE WHEN Num > 1 THEN Nam ELSE '' END), 
														(CASE WHEN Num > 1 THEN @HundredWords ELSE @HundredWord END),
														CASE WHEN @v000Num%100 = 1 AND @vIndex >= 1 THEN N'' ELSE @vSubResult END))
					FROM	@tDict
					WHERE	Num = FLOOR(@v000Num/100)
				END
			END
			
			--000 xxx
			IF @vSubResult <> '' 
			BEGIN
				IF @v000Num = 1 AND @vIndex >= 1
					SET @vSubResult = N''

				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		ELSE N''
																	END)
																	
				SET @vResult = FORMATMESSAGE('%s %s', @vSubResult, @vResult)
			END

			-- next 000 (to left)
			SET @vIndex = @vIndex + 1
			SET @Number = FLOOR(@Number / 1000)
		END
	END

	SET @vResult = FORMATMESSAGE('%s %s', TRIM(@vResult), COALESCE(@DotWord + N' ' + NULLIF(@vSubDecimalResult,''), ''))
	
	-- result
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_GA(3201001.25)
	SELECT dbo.MoneyToWords_GA(123456789.56)
	SELECT dbo.MoneyToWords_GA(123000789.56)
	SELECT dbo.MoneyToWords_GA(123010789.56)
	SELECT dbo.MoneyToWords_GA(123004789.56)
	SELECT dbo.MoneyToWords_GA(123904789.56)
	SELECT dbo.MoneyToWords_GA(205.56)
	SELECT dbo.MoneyToWords_GA(45.1)
	SELECT dbo.MoneyToWords_GA(45.09)
	SELECT dbo.MoneyToWords_GA(0.09)
	SELECT dbo.MoneyToWords_GA(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_GA(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_GA(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_GA(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_GA(100000000000000)
*/