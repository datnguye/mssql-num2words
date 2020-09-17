--======================================================
-- Usage:	Lib: MoneyToWords in English
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- History:
-- Date			Author		Description
-- 2020-09-16	NV			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_EN
GO
CREATE FUNCTION dbo.MoneyToWords_EN(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @special		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@special (Num, Nam)
	VALUES	(1,'one'),(2,'two'),(3,'three'),(4,'four'),(5,'five'),(6,'six'),(7,'seven'),(8,'eight'),(9,'nine'),
			(10,'ten'),(11,'eleven'),(12,'twelve'),(13,'thirteen'),(14,'fourteen'),(15,'fifteen'),(16,'sixteen'),(17,'seventeen'),(18,'eighteen'),(19,'nineteen'),
			(20,'twenty'),(30,'thirty'),(40,'fourty'),(50,'fifty'),(60,'sixty'),(70,'seventy'),(80,'eighty'),(90,'ninety')
	
	DECLARE @ZeroWord		NVARCHAR(10) = 'zero'
	DECLARE @DotWord		NVARCHAR(10) = 'point'
	DECLARE @AndWord		NVARCHAR(10) = 'and'
	DECLARE @HundredWord	NVARCHAR(10) = 'hundred'
	DECLARE @ThousandWord	NVARCHAR(10) = 'thousand'
	DECLARE @MillionWord	NVARCHAR(10) = 'million'
	DECLARE @BillionWord	NVARCHAR(10) = 'billion'
	DECLARE @TrillionWord	NVARCHAR(10) = 'trillion'
	-- decimal number
	
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vDecimalNum_tmp DECIMAL(17,2) = @vDecimalNum/10
	DECLARE @vDecimalWords NVARCHAR(255) = '', @vDecimalWords_tmp NVARCHAR(255) = ''

	IF @vDecimalNum <> 0
		WHILE @vDecimalNum_tmp > 0
		BEGIN
			IF @vDecimalNum_tmp < 1
				BEGIN
				SET @vDecimalNum_tmp = @vDecimalNum_tmp *10
				SET @vDecimalWords = ' '+ @ZeroWord
				END
			ELSE
				SET @vDecimalNum_tmp =  CONVERT(INT,@vDecimalNum_tmp)

			SET @vDecimalNum = (@vDecimalNum - @vDecimalNum_tmp*10)
			SET @vDecimalWords_tmp = (SELECT Nam FROM @special WHERE Num = @vDecimalNum_tmp)
			SET @vDecimalWords =  @vDecimalWords + ' '+  @vDecimalWords_tmp 
			SET @vDecimalNum_tmp = @vDecimalNum--/10
		END
	
	-- main number
	SET @Number = FLOOR(@Number)
	IF @Number = 0
		SET @vResult = @ZeroWord
	ELSE
	BEGIN
		DECLARE @vSubResult	NVARCHAR(MAX) = ''
		DECLARE @vSubResult_unit NVARCHAR(MAX) = ''
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
			ELSE IF @v00Num < 20
			BEGIN
				-- less than 20
				SELECT @vSubResult = Nam FROM @special WHERE Num = @v00Num
			END
			ELSE 
			BEGIN
				-- greater than or equal 20
				SELECT @vSubResult_unit = Nam FROM @special WHERE Num = @v0Num 

				SET @v00Num = FLOOR(@v00Num/10)*10
				
				SELECT @vSubResult = Nam FROM @special WHERE Num = @v00Num 

				SET @vSubResult = @vSubResult + ' '+ @vSubResult_unit
			END

			IF @vSubResult <> '' OR @v000Num != 0
			BEGIN
				IF @vSubResult <> ''
					SELECT @vSubResult = FORMATMESSAGE('%s %s %s %s', Nam, @HundredWord, @AndWord, @vSubResult) FROM @special WHERE Num = CONVERT(INT,@v000Num / 100)--000

				IF @v000Num != 0 and @vSubResult = ''
					SELECT @vSubResult = FORMATMESSAGE('%s %s %s', Nam, @HundredWord, @vSubResult) FROM @special WHERE Num = CONVERT(INT,@v000Num / 100)--000

				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN @ThousandWord
																		WHEN @vIndex=2 THEN @MillionWord
																		WHEN @vIndex=3 THEN @BillionWord
																		WHEN @vIndex=4 THEN @TrillionWord
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN @MillionWord + ' ' + TRIM(REPLICATE(@BillionWord + ' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN TRIM(REPLICATE(@BillionWord + ' ',@vIndex%3))
																		ELSE ''
																	END)
				SET @vResult = FORMATMESSAGE('%s %s', @vSubResult, @vResult)
			END

			-- next 000 (to left)
			SET @vIndex = @vIndex + 1
			SET @Number = FLOOR(@Number / 1000)
		END
	END

	-- result
	IF @vDecimalWords <>''
		SET @vResult = TRIM(FORMATMESSAGE('%s %s', TRIM(@vResult), COALESCE(@DotWord  +@vDecimalWords, '')))
	ELSE
		SET @vResult = TRIM(FORMATMESSAGE('%s %s', TRIM(@vResult), COALESCE(@vDecimalWords, '')))

	SET @vResult =  REPLACE(@vResult,'ty ','ty-')
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_EN(11111.255)
	SELECT dbo.MoneyToWords_EN(123456789.56)
	SELECT dbo.MoneyToWords_EN(123000789.56)
	SELECT dbo.MoneyToWords_EN(123010789.56)
	SELECT dbo.MoneyToWords_EN(123004789.56)
	SELECT dbo.MoneyToWords_EN(123904789.56)
	SELECT dbo.MoneyToWords_EN(205.56)
	SELECT dbo.MoneyToWords_EN(45.1)
	SELECT dbo.MoneyToWords_EN(45.09)
	SELECT dbo.MoneyToWords_EN(0.09)
	SELECT dbo.MoneyToWords_EN(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_EN(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_EN(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_EN(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_EN(100000000000000)
*/