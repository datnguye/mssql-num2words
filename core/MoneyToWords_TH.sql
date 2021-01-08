--======================================================
-- Usage:	Lib: MoneyToWords in Thai 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- http://www.thai-language.com/ref/numbers
-- History:
-- Date			Author		Description
-- 2021-01-04	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_TH
GO
CREATE FUNCTION dbo.MoneyToWords_TH(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'หนึ่ง'),(2,N'สอง'),(3,N'สาม'),(4,N'สี่'),(5,N'ห้า'),(6,N'หก'),(7,N'เจ็ด'),(8,N'แปด'),(9,N'เก้า'),
			(11,N'สิบเอ็ด'),(12,N'สิบสอง'),(13,N'สิบสาม'),(14,N'สิบสี่'),(15,N'สิบห้า'),(16,N'สิบหก'),(17,N'สิบเจ็ด'),(18,N'สิบแปด'),(19,N'สิบเก้า'),
			(10,N'สิบ'),(20,N'ยี่สิบ'),(30,N'สามสิบ'),(40,N'สี่สิบ'),(50,N'ห้าสิบ'),(60,N'หกสิบ'),(70,N'เจ็ดสิบ'),(80,N'แปดสิบ'),(90,N'เก้าสิบ'),
			(100,N'ร้อย'),(200,N'สองร้อย'),(300,N'สามร้อย'),(400,N'สี่ร้อย'),(500,N'ห้าร้อย'),(600,N'หกร้อย'),(700,N'เจ็ดร้อย'),(800,N'แปดร้อย'),(900,N'เก้าร้อย')

	DECLARE @ZeroWord				NVARCHAR(20) = N'ศูนย์'
	DECLARE @OneOddWord				NVARCHAR(20) = N'เอ็ด'--between 11 and 91
	DECLARE @DotWord				NVARCHAR(20) = N'จุด'
	DECLARE @AndWord				NVARCHAR(20) = N''
	DECLARE @HundredWord			NVARCHAR(20) = N'ร้อย'
	DECLARE @ThousandWord			NVARCHAR(20) = N'พัน'
	DECLARE @TenThousandWord		NVARCHAR(20) = N'หมื่น'
	DECLARE @HundredThousandWord	NVARCHAR(20) = N'แสน'
	DECLARE @MillionWord			NVARCHAR(20) = N'ล้าน'

	-- decimal number		
	DECLARE @vDecimalNum INT = (@Number - FLOOR(@Number)) * 100
	DECLARE @vLoop SMALLINT = CONVERT(SMALLINT, SQL_VARIANT_PROPERTY(@Number, 'Scale'))
	DECLARE @vSubDecimalResult	NVARCHAR(MAX) = N''
	IF @vDecimalNum > 0
	BEGIN
		WHILE @vLoop > 0
		BEGIN
			IF @vDecimalNum % 10 = 0
				SET @vSubDecimalResult = FORMATMESSAGE('%s%s', @ZeroWord, @vSubDecimalResult)
			ELSE
				SELECT	@vSubDecimalResult = FORMATMESSAGE('%s%s', Nam, @vSubDecimalResult)
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
					IF @v00Num > 20 AND @v00Num <= 91 AND @v00Num%10 = 1
						SET @vSubResult = @OneOddWord
					SELECT @vSubResult = RTRIM(FORMATMESSAGE('%s%s', Nam, @vSubResult)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s%s', CASE WHEN Num > 1 THEN Nam ELSE N'' END, @vSubResult))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100) * 100
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @vIndex=1
				BEGIN
					SET @vSubResult = N''

					SELECT @vSubResult = CASE WHEN Num > 1 THEN Nam ELSE N'' END+@HundredThousandWord FROM @tDict WHERE Num = FLOOR(@v000Num/100)
					SELECT @vSubResult = COALESCE(@vSubResult,N'')+COALESCE(CASE WHEN Num > 1 THEN Nam ELSE N'' END+@TenThousandWord,N'') FROM @tDict WHERE Num = FLOOR((@v000Num%100)/10)
					SELECT @vSubResult = COALESCE(@vSubResult,N'')+COALESCE(CASE WHEN Num > 1 THEN Nam ELSE N'' END+@ThousandWord,N'') FROM @tDict WHERE Num = @v000Num%10
				END
				ELSE
				BEGIN
					SET @vSubResult = FORMATMESSAGE(N'%s%s', @vSubResult, CASE 
																			WHEN @vIndex=2 THEN @MillionWord
																			WHEN @vIndex=3 THEN @ThousandWord+@MillionWord
																			WHEN @vIndex>3 AND @vIndex%2=0 THEN REPLICATE(@MillionWord,@vIndex/2)
																			WHEN @vIndex>3 AND @vIndex%2=1 THEN REPLICATE(@ThousandWord+@MillionWord,(@vIndex-1)/2)
																			ELSE N''
																		END)
				END
				
				SET @vResult = FORMATMESSAGE('%s%s', LTRIM(@vSubResult), @vResult)
			END

			-- next 000 (to left)
			SET @vIndex = @vIndex + 1
			SET @vPrev000Number = @Number
			SET @Number = FLOOR(@Number / 1000)
		END
	END

	SET @vResult = FORMATMESSAGE('%s%s', TRIM(@vResult), COALESCE(@DotWord + NULLIF(@vSubDecimalResult,''), ''))
	
	-- result
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_TH(3201001.25)
	SELECT dbo.MoneyToWords_TH(123456789.56)
	SELECT dbo.MoneyToWords_TH(123000789.56)
	SELECT dbo.MoneyToWords_TH(123010789.56)
	SELECT dbo.MoneyToWords_TH(123004789.56)
	SELECT dbo.MoneyToWords_TH(123904789.56)
	SELECT dbo.MoneyToWords_TH(205.56)
	SELECT dbo.MoneyToWords_TH(45.1)
	SELECT dbo.MoneyToWords_TH(45.09)
	SELECT dbo.MoneyToWords_TH(0.09)
	SELECT dbo.MoneyToWords_TH(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_TH(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_TH(123234567896789.02)--123 234 567 896 789.02	
	SELECT dbo.MoneyToWords_TH(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_TH(100000000000000)
*/