--======================================================
-- Usage:	Lib: MoneyToWords in Vietnamese
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- History:
-- Date			Author		Description
-- 2020-08-31	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_VI
GO
CREATE FUNCTION MoneyToWords_VI(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = N''

	-- pre-data
	DECLARE @tTo19		TABLE (Num int NOT NULL, Nam nvarchar(255) NOT NULL)
	INSERT 
	INTO	@tTo19 (Num, Nam)
	VALUES	(1,N'một'),(2,N'hai'),(3,N'ba'),(4,N'bốn'),(5,N'năm'),(6,N'sáu'),(7,N'bảy'),(8,N'tám'),(9,N'chín'),
			(10,N'mười'),(11,N'mười một'),(12,N'mười hai'),(13,N'mười ba'),(14,N'mười bốn'),(15,N'mười lăm'),(16,N'mười sáu'),(17,N'mười bảy'),(18,N'mười tám'),(19,N'mười chín')
	
	DECLARE @ZeroWord		nvarchar(10) = N'không'
	DECLARE @DotWord		nvarchar(10) = N'phẩy'
	DECLARE @FirstWord		nvarchar(10) = N'mốt'
	DECLARE @OddWord		nvarchar(10) = N'lẻ'
	DECLARE @FifthWord		nvarchar(10) = N'lăm'
	DECLARE @TensWord		nvarchar(10) = N'mươi'
	DECLARE @HundredWord	nvarchar(10) = N'trăm'
	DECLARE @ThousandWord	nvarchar(10) = N'nghìn'
	DECLARE @MillionWord	nvarchar(10) = N'triệu'
	DECLARE @BillionWord	nvarchar(10) = N'tỷ'

	-- decimal number
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vDecimalWords NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vDecimalWords = dbo.MoneyToWords_VI(@vDecimalNum)
		
	-- main number
	SET @Number = FLOOR(@Number)
	IF @Number = 0
		SET @vResult = @ZeroWord
	ELSE
	BEGIN
		DECLARE @vSubResult	NVARCHAR(MAX) = N''
		DECLARE @v000Num DECIMAL(15,0) = 0
		DECLARE @v00Num DECIMAL(15,0) = 0
		DECLARE @vIndex INT = 0
		WHILE @Number > 0
		BEGIN
			-- from right to left: take first 000
			SET @v000Num = @Number % 1000
			SET @v00Num = @v000Num % 100
			IF @v00Num < 20
			BEGIN
				-- less than 20
				SELECT @vSubResult = Nam FROM @tTo19 WHERE Num = @v00Num
				IF @vIndex = 0 AND @v00Num < 10 --odd
					SET @vSubResult = FORMATMESSAGE('%s %s', @OddWord, @vSubResult)
			END
			ELSE
			BEGIN
				-- greater than or equal 20
				SELECT @vSubResult = Nam FROM @tTo19 WHERE Num = CONVERT(INT,@v00Num / 10)
				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, @TensWord)
				SELECT @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE WHEN Num=5 THEN @FifthWord ELSE Nam END) FROM @tTo19 WHERE Num = CONVERT(INT,@v00Num % 10)
			END
			SELECT @vSubResult = FORMATMESSAGE('%s %s %s', Nam, @HundredWord, @vSubResult) FROM @tTo19 WHERE Num = CONVERT(INT,@v000Num / 100)--000
			SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																	WHEN @vIndex=1 THEN @ThousandWord
																	WHEN @vIndex=2 THEN @MillionWord
																	WHEN @vIndex>=3 THEN TRIM(REPLICATE(@BillionWord + ' ',@vIndex-2))
																	ELSE ''
																END)
			SET @vResult = FORMATMESSAGE('%s %s', @vSubResult, @vResult)

			-- next 000 (to left)
			SET @vIndex = @vIndex + 1
			SET @Number = FLOOR(@Number / 1000)
		END
	END

	-- result
	SET @vResult = TRIM(FORMATMESSAGE('%s %s', TRIM(@vResult), COALESCE(@DotWord+' '+@vDecimalWords, '')))
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_VI(255.56)
	SELECT dbo.MoneyToWords_VI(123456789.56)
	SELECT dbo.MoneyToWords_VI(205.56)
	SELECT dbo.MoneyToWords_VI(0.29)
	SELECT dbo.MoneyToWords_VI(0.0)
*/
