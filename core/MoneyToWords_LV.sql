--======================================================
-- Usage:	Lib: MoneyToWords in Latvian (LV)
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-latvian/en/lav/
-- History:
-- Date			Author		Description
-- 2021-01-10	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_LV
GO
CREATE FUNCTION dbo.MoneyToWords_LV(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'viens'),(2,N'divi'),(3,N'trīs'),(4,N'četri'),(5,N'pieci'),(6,N'seši'),(7,N'septiņi'),(8,N'astoņi'),(9,N'deviņi'),
			(11,N'vienpadsmit'),(12,N'divpadsmit'),(13,N'trīspadsmit'),(14,N'četrpadsmit'),(15,N'piecpadsmit'),(16,N'sešpadsmit'),(17,N'septiņpadsmit'),(18,N'astoņpadsmit'),(19,N'deviņpadsmit'),
			(10,N'desmit'),(20,N'divdesmit'),(30,N'trīsdesmit'),(40,N'četrdesmit'),(50,N'piecdesmit'),(60,N'sešdesmit'),(70,N'septiņdesmit'),(80,N'astoņdesmit'),(90,N'deviņdesmit')

	DECLARE @ZeroWord			NVARCHAR(20) = N'nulle'
	DECLARE @DotWord			NVARCHAR(20) = N'komats'
	DECLARE @AndWord			NVARCHAR(20) = N''
	DECLARE @HundredWord		NVARCHAR(20) = N'simts'
	DECLARE @HundredWords		NVARCHAR(20) = N'simt'
	DECLARE @ThousandWord		NVARCHAR(20) = N'tūkstoš'
	DECLARE @ThousandWords		NVARCHAR(20) = N'tūkstoši'
	DECLARE @MillionWord		NVARCHAR(20) = N'miljons'
	DECLARE @MillionWords		NVARCHAR(20) = N'miljonu'
	DECLARE @BillionWord		NVARCHAR(20) = N'miljards'
	DECLARE @BillionWords		NVARCHAR(20) = N'miljardu'
	DECLARE @TrillionWord		NVARCHAR(20) = N'triljons'
	DECLARE @TrillionWords		NVARCHAR(20) = N'triljonu'
	DECLARE @QuadrillionWord	NVARCHAR(20) = N'kvadriljons'
	DECLARE @QuadrillionWords	NVARCHAR(20) = N'kvadriljonu'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_LV(@vDecimalNum)
	
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
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s%s %s', 
																CASE WHEN Num > 1 THEN SUBSTRING(Nam,1,LEN(Nam)-1) ELSE N'' END,
																CASE WHEN Num > 1 OR @vIndex > 0 THEN @HundredWords ELSE @HundredWord END,
																@vSubResult))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @vIndex = 1 AND @v000Num%10 < 10 AND @vSubResult LIKE N'%i'
					SET @vSubResult = SUBSTRING(@vSubResult,1,LEN(@vSubResult)-1)
				IF @vIndex >= 1 AND @v000Num = 1
					SET @vSubResult = N''

				SET @vSubResult = FORMATMESSAGE('%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN N' '+CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN N' '+CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN N' '+CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex=5 THEN N' '+CASE WHEN @v000Num > 1 THEN @QuadrillionWords ELSE @QuadrillionWord END
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
	SELECT dbo.MoneyToWords_LV(3201001.25)
	SELECT dbo.MoneyToWords_LV(123456789.56)
	SELECT dbo.MoneyToWords_LV(123000789.56)
	SELECT dbo.MoneyToWords_LV(123010789.56)
	SELECT dbo.MoneyToWords_LV(123004789.56)
	SELECT dbo.MoneyToWords_LV(123904789.56)
	SELECT dbo.MoneyToWords_LV(205.56)
	SELECT dbo.MoneyToWords_LV(45.1)
	SELECT dbo.MoneyToWords_LV(45.09)
	SELECT dbo.MoneyToWords_LV(0.09)
	SELECT dbo.MoneyToWords_LV(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_LV(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_LV(123234567896789.02)--123 234 567 896 789.02	
	SELECT dbo.MoneyToWords_LV(999999999999999.99)--999 999 999 999 999.99
	SELECT dbo.MoneyToWords_LV(100000000000000)
*/