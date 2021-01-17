--======================================================
-- Usage:	Lib: MoneyToWords in Arabic
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://wordadayarabic.com/2013/03/04/arabic-numbers-0-10/
-- https://wordadayarabic.com/2015/05/23/arabic-numbers-iii-11-1000/
-- https://www.languagesandnumbers.com/how-to-count-in-arabic/en/arb/
-- History:
-- Date			Author		Description
-- 2020-12-29	DN			Intial
-- 2021-01-17	DN			Correctness
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_AR
GO
CREATE FUNCTION dbo.MoneyToWords_AR(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'واحد'),(2,N'إثنان'),(3,N'ثلاثة'),(4,N'أربع'),(5,N'خمسة'),(6,N'ستة'),(7,N'سبعة'),(8,N'ثمانية'),(9,N'تسعة'),
			(11,N'احد عشر'),(12,N'اثنا عشر'),(13,N'ثلاثة عشر'),(14,N'اربعة عشر'),(15,N'خمسة عشر'),(16,N'ستة عشر'),(17,N'سبعة عشر'),(18,N'ثمانية عشر'),(19,N'تسعة عشر'),
			(10,N'عشرة'),(20,N'عشرون'),(30,N'ثلاثون'),(40,N'أربعون'),(50,N'خمسون'),(60,N'ستون'),(70,N'سبعون'),(80,N'ثمانون'),(90,N'تسعون')

	DECLARE @ZeroWord		NVARCHAR(20) = N'صِفْرٌ'
	DECLARE @DotWord		NVARCHAR(20) = N','
	DECLARE @AndWord		NVARCHAR(20) = N'و'
	DECLARE @HundredWord	NVARCHAR(20) = N'مِئَةٌ'
	--DECLARE @2HundredWords	NVARCHAR(20) = N'مِائَتَان'
	DECLARE @ThousandWord	NVARCHAR(20) = N'أَلْفٌ'
	DECLARE @ThousandWordx	NVARCHAR(20) = N'أَلْفَيْن'--2
	DECLARE @ThousandWords	NVARCHAR(20) = N'آلَاف'
	DECLARE @MillionWord	NVARCHAR(20) = N'مَلِيُوْن'
	DECLARE @MillionWords	NVARCHAR(20) = N'ملايين'
	DECLARE @BillionWord	NVARCHAR(20) = N'مليار'
	DECLARE @BillionWords	NVARCHAR(20) = N'مليارات'

	-- decimal number	
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_AR(@vDecimalNum)
	
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
					SELECT @vSubResult = LTRIM(FORMATMESSAGE('%s %s', @vSubResult+N' '+@AndWord, Nam)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10 
				END

				--000
				IF @v000Num > 99
					SELECT	@vSubResult = LTRIM(FORMATMESSAGE('%s %s %s', 
														(CASE WHEN Num > 1 THEN Nam ELSE N'' END),
														@HundredWord,--(CASE WHEN Num = 2 THEN @2HundredWords ELSE @HundredWord END),
														@vSubResult))
					FROM	@tDict
					WHERE	Num = FLOOR(@v000Num/100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num IN (2) THEN @ThousandWordx WHEN @v000Num=1 THEN @ThousandWord ELSE @ThousandWords END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		ELSE N''
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
	SELECT dbo.MoneyToWords_AR(3201001.25)
	SELECT dbo.MoneyToWords_AR(123456789.56)
	SELECT dbo.MoneyToWords_AR(123000789.56)
	SELECT dbo.MoneyToWords_AR(123010789.56)
	SELECT dbo.MoneyToWords_AR(123004789.56)
	SELECT dbo.MoneyToWords_AR(123904789.56)
	SELECT dbo.MoneyToWords_AR(205.56)
	SELECT dbo.MoneyToWords_AR(45.1)
	SELECT dbo.MoneyToWords_AR(45.09)
	SELECT dbo.MoneyToWords_AR(0.09)
	SELECT dbo.MoneyToWords_AR(234567896789.02)--234 567 896 789.02
	SELECT dbo.MoneyToWords_AR(234567896789.52)--234 567 896 789.52
*/