--======================================================
-- Usage:	Lib: MoneyToWords in Hebrew 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-hebrew/en/heb/
-- History:
-- Date			Author		Description
-- 2021-01-08	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_HE
GO
CREATE FUNCTION dbo.MoneyToWords_HE(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'אַחַת'),(2,N'שְׁתַּיִם'),(3,N'שָׁלֹשׁ'),(4,N'אַרְבַּע'),(5,N'חָמֵשׁ'),(6,N'שֵׁשׁ'),(7,N'שֶׁבַע'),(8,N'שְׁמוֹנֶה'),(9,N'תֵּשַׁע'),
			(11,N'אֲחַד-עָשָׂר'),(12,N'שְׁנֵים-עָשָׂר'),(13,N'שְׁלֹשָה-עָשָׂר'),(14,N'אַרְבָּעָה-עָשָׂר'),(15,N'חֲמִשָּׁה-עָשָׂר'),(16,N'שִׁשָּׁה-עָשָׂר'),(17,N'שִׁבְעָה-עָשָׂר'),(18,N'שְׁמוֹנָה-עָשָׂר'),(19,N'תִּשְׁעָה-עָשָׂר'),
			(10,N'עֶשֶׂר'),(20,N'עֶשְׂרִים'),(30,N'שְׁלֹשִׁים'),(40,N'אַרְבָּעִים'),(50,N'חֲמִשִּׁים'),(60,N'שִׁשִּׁים'),(70,N'שִׁבְעִים'),(80,N'שְׁמוֹנִים'),(90,N'תִּשְׁעִים')

	DECLARE @ZeroWord			NVARCHAR(20) = N'אֶפֶס'
	DECLARE @DotWord			NVARCHAR(20) = N''
	DECLARE @AndWord			NVARCHAR(20) = N''
	DECLARE @HundredWord		NVARCHAR(20) = N'מֵאָה'
	DECLARE @2HundredWord		NVARCHAR(20) = N'מָאתַיִם'
	DECLARE @HundredWords		NVARCHAR(20) = N'מֵאוֹת'
	DECLARE @ThousandWord		NVARCHAR(20) = N'אֶלֶף'
	DECLARE @2ThousandWord		NVARCHAR(20) = N'אֲלָפִים'
	DECLARE @ThousandWords		NVARCHAR(20) = N'אֲלָפִים'
	DECLARE @MillionWord		NVARCHAR(20) = N'מִילְיוֹן'
	DECLARE @BillionWord		NVARCHAR(20) = N'מִילְיַרְדּ'
	DECLARE @TrillionWord		NVARCHAR(20) = N'טְרִילְיוֹן'
	DECLARE @QuadrillionWord	NVARCHAR(20) = N'קְוַדְרִילְיוֹן'
	
	-- ** NOT IMPLEMENT **
	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	--IF @vDecimalNum <> 0
	--	SET @vSubDecimalResult = dbo.MoneyToWords_HE(@vDecimalNum)
	-- ** NOT IMPLEMENT **
	
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
					SELECT @vSubResult = (CASE WHEN Num IN (2,8) THEN N'וּ' ELSE N'וָ' END)+Nam FROM @tDict WHERE Num = @v0Num 
					SELECT @vSubResult = LTRIM(FORMATMESSAGE('%s %s', Nam, @vSubResult)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					SELECT	@vSubResult = CASE 
											WHEN Num = 1 THEN RTRIM(FORMATMESSAGE('%s %s', @HundredWord, @vSubResult))
											WHEN Num = 2 THEN RTRIM(FORMATMESSAGE('%s %s', @2HundredWord, @vSubResult))
											ELSE RTRIM(FORMATMESSAGE('%s %s %s', Nam, @HundredWords, @vSubResult))
										END
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @v000Num = 1 AND @vIndex = 1
					SET @vSubResult = @ThousandWord
				ELSE IF @v000Num = 2 AND @vIndex = 1
					SET @vSubResult = @2ThousandWord
				ELSE
					SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																			WHEN @vIndex=1 THEN CASE WHEN @v000Num < 11 THEN @ThousandWords ELSE @ThousandWord END 
																			WHEN @vIndex=2 THEN @MillionWord
																			WHEN @vIndex=3 THEN @BillionWord
																			WHEN @vIndex=4 THEN @TrillionWord
																			WHEN @vIndex=5 THEN @QuadrillionWord
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
	SELECT dbo.MoneyToWords_HE(3201001)
	SELECT dbo.MoneyToWords_HE(123456789)
	SELECT dbo.MoneyToWords_HE(123000789)
	SELECT dbo.MoneyToWords_HE(123010789)
	SELECT dbo.MoneyToWords_HE(123004789)
	SELECT dbo.MoneyToWords_HE(123904789)
	SELECT dbo.MoneyToWords_HE(205)
	SELECT dbo.MoneyToWords_HE(45.)
	SELECT dbo.MoneyToWords_HE(0)
	SELECT dbo.MoneyToWords_HE(1234567896789)--1 234 567 896 789
	SELECT dbo.MoneyToWords_HE(1234567896789)--1 234 567 896 789
	SELECT dbo.MoneyToWords_HE(123234567896789)--123 234 567 896 789
	SELECT dbo.MoneyToWords_HE(999999999999999)--999 999 999 999 999
	SELECT dbo.MoneyToWords_HE(100000000000000)
*/