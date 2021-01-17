--======================================================
-- Usage:	Lib: MoneyToWords in Telugu (TE)
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-telugu/en/tel/
-- History:
-- Date			Author		Description
-- 2021-01-14	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_TE
GO
CREATE FUNCTION dbo.MoneyToWords_TE(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'ఒకటి'),(2,N'రెండు'),(3,N'మూడు'),(4,N'నాలుగు'),(5,N'అయిదు'),(6,N'ఆరు'),(7,N'ఏడు'),(8,N'ఎనిమిది'),(9,N'తొమ్మిది'),
			(11,N'పదకొండు'),(12,N'పన్నెండు'),(13,N'పదమూడు'),(14,N'పధ్నాలుగు'),(15,N'పదునయిదు'),(16,N'పదహారు'),(17,N'పదిహేడు'),(18,N'పధ్ధెనిమిది'),(19,N'పందొమ్మిది'),
			(10,N'పది'),(20,N'ఇరవై'),(30,N'ముప్పై'),(40,N'నలభై'),(50,N'యాభై'),(60,N'అరవై'),(70,N'డెబ్బై'),(80,N'ఎనభై'),(90,N'తొంభై')

	DECLARE @ZeroWord				NVARCHAR(20) = N'సున్న'
	DECLARE @DotWord				NVARCHAR(20) = N'పాయింట్'
	DECLARE @AndWord				NVARCHAR(20) = N''
	DECLARE @HundredWord			NVARCHAR(20) = N'వంద'
	DECLARE @HundredWords			NVARCHAR(20) = N'వందల'
	DECLARE @ThousandWord			NVARCHAR(20) = N'వెయ్యి'
	DECLARE @ThousandWords			NVARCHAR(20) = N'వేలు'
	DECLARE @HundredThousandWord	NVARCHAR(20) = N'లక్ష'
	DECLARE @HundredThousandWords	NVARCHAR(20) = N'లక్షల'
	DECLARE @TenMillionWord			NVARCHAR(20) = N'కోటి'
	DECLARE @TenMillionWords		NVARCHAR(20) = N'కోటిల'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_TE(@vDecimalNum)
	
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
			-- from the 2nd slice: take only 00
			IF @vIndex >= 1
			BEGIN
				SET @v000Num = 0
				SET @v00Num = @Number % 100
				SET @v0Num = @v00Num % 10
			END

			SET @vSubResult = ''
			IF @v000Num > 0 OR (@vIndex >= 1 AND @v00Num > 0)
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
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s %s %s', Nam, CASE WHEN Num>1 THEN @HundredWords ELSE @HundredWord END, @vSubResult))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		--01 000 to 99 000
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num=1 THEN @ThousandWord ELSE @ThousandWords END
																		--01 00 000 to 99 00 000
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num=1 THEN @HundredThousandWord ELSE @HundredThousandWords END
																		--01 00 00 000 to 99 00 00 000
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num=1 THEN @TenMillionWord ELSE @TenMillionWords END
																		ELSE N''
																	END)
				
				SET @vResult = FORMATMESSAGE('%s %s', @vSubResult, @vResult)
			END

			-- next 000 (to left)
			SET @vIndex = @vIndex + 1
			IF @vIndex >= 1
				SET @Number = FLOOR(@Number / 100)
			ELSE
				SET @Number = FLOOR(@Number / 1000)
		END
	END

	SET @vResult = FORMATMESSAGE('%s %s', TRIM(@vResult), COALESCE(@DotWord + ' ' + NULLIF(@vSubDecimalResult,''), ''))
	
	-- result
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_TE(3201001.25)
	SELECT dbo.MoneyToWords_TE(123456789.56)
	SELECT dbo.MoneyToWords_TE(123000789.56)
	SELECT dbo.MoneyToWords_TE(123010789.56)
	SELECT dbo.MoneyToWords_TE(123004789.56)
	SELECT dbo.MoneyToWords_TE(123904789.56)
	SELECT dbo.MoneyToWords_TE(205.56)
	SELECT dbo.MoneyToWords_TE(45.1)
	SELECT dbo.MoneyToWords_TE(45.09)
	SELECT dbo.MoneyToWords_TE(0.09)

	--SELECT dbo.MoneyToWords_TE(1234567896789.02)--1 234 567 8 96 789.02
	--SELECT dbo.MoneyToWords_TE(1234567896789.52)--1 234 567 896 789.52
	--SELECT dbo.MoneyToWords_TE(123234567896789.02)--123 234 567 896 789.02	
	--SELECT dbo.MoneyToWords_TE(999999999999999.99)--999 999 999 999 999.99	
	--SELECT dbo.MoneyToWords_TE(100000000000000)
*/