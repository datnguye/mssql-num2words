/*
	RELEASE: 1.0
	Author: Dat Nguyen
	--------------------------------------------------------------------
	Date			By			Description
	--------------------------------------------------------------------
	2020-01-17		Dat Nguyen	Creation: 30 languages
*/
SET NUMERIC_ROUNDABORT OFF
GO
SET XACT_ABORT, ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS, NOCOUNT ON
GO

/*
	Section: Data Definition Language 
*/
--PRE DDL
BEGIN TRANSACTION PREDDL
	SET DEADLOCK_PRIORITY HIGH
COMMIT TRANSACTION PREDDL
GO
--DDL
BEGIN TRANSACTION DDL
	SET DEADLOCK_PRIORITY HIGH
COMMIT TRANSACTION DDL
GO
--POST DDL
BEGIN TRANSACTION POSTDDL
	SET DEADLOCK_PRIORITY HIGH
COMMIT TRANSACTION POSTDDL
GO


/*
	Section: Data Manipulation Language 
*/
--PRE DML
BEGIN TRANSACTION PREDML
	SET DEADLOCK_PRIORITY HIGH
COMMIT TRANSACTION PREDML
GO
--DML
BEGIN TRANSACTION DML
	SET DEADLOCK_PRIORITY HIGH
COMMIT TRANSACTION DML
GO
--POST DML
BEGIN TRANSACTION POSTDML
	SET DEADLOCK_PRIORITY HIGH
COMMIT TRANSACTION POSTDML
GO

/*
	Section: Routins (Stored Procedure, Funtion, Trigger, etc) 
*/
--PRE ROUTINE
BEGIN TRANSACTION PREROUTINE
	SET DEADLOCK_PRIORITY HIGH
COMMIT TRANSACTION PREROUTINE
GO
--ROUTINE
BEGIN TRANSACTION ROUTINE
	SET DEADLOCK_PRIORITY HIGH

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
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Czech 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-czech/en/ces/
-- History:
-- Date			Author		Description
-- 2021-01-03	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_CZ
GO
CREATE FUNCTION dbo.MoneyToWords_CZ(@Number DECIMAL(17,2))
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

	DECLARE @ZeroWord		NVARCHAR(20) = N'nula'
	DECLARE @DotWord		NVARCHAR(20) = N'celá'
	DECLARE @AndWord		NVARCHAR(20) = N''
	DECLARE @HundredWord	NVARCHAR(20) = N'sto'
	DECLARE @HundredWords	NVARCHAR(20) = N'sta'
	DECLARE @ThousandWord	NVARCHAR(20) = N'tisíc'
	DECLARE @ThousandWords	NVARCHAR(20) = N'tisíc'
	DECLARE @MillionWord	NVARCHAR(20) = N'milión'
	DECLARE @MillionWords	NVARCHAR(20) = N'miliony'
	DECLARE @MillionWordss	NVARCHAR(20) = N'milionů'
	DECLARE @BillionWord	NVARCHAR(20) = N'miliarda'
	DECLARE @BillionWords	NVARCHAR(20) = N'miliardy'
	DECLARE @BillionWordss	NVARCHAR(20) = N'miliard'
	DECLARE @TrillionWord	NVARCHAR(20) = N'bilión'
	DECLARE @TrillionWords	NVARCHAR(20) = N'biliony'
	DECLARE @TrillionWordss	NVARCHAR(20) = N'bilionů'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_CZ(@vDecimalNum)
	
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
	SELECT dbo.MoneyToWords_CZ(3201001.25)
	SELECT dbo.MoneyToWords_CZ(123456789.56)
	SELECT dbo.MoneyToWords_CZ(123000789.56)
	SELECT dbo.MoneyToWords_CZ(123010789.56)
	SELECT dbo.MoneyToWords_CZ(123004789.56)
	SELECT dbo.MoneyToWords_CZ(123904789.56)
	SELECT dbo.MoneyToWords_CZ(205.56)
	SELECT dbo.MoneyToWords_CZ(45.1)
	SELECT dbo.MoneyToWords_CZ(45.09)
	SELECT dbo.MoneyToWords_CZ(0.09)
	SELECT dbo.MoneyToWords_CZ(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_CZ(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_CZ(123234567896789.02)--123 234 567 896 789.02	
	SELECT dbo.MoneyToWords_CZ(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_CZ(100000000000000)
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in German
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.fluentin3months.com/german-numbers/
-- History:
-- Date			Author		Description
-- 2020-12-07	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_DE
GO
CREATE FUNCTION dbo.MoneyToWords_DE(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'ein'),(2,N'zwei'),(3,N'drei'),(4,N'vier'),(5,N'fünf'),(6,N'sechs'),(7,N'sieben'),(8,N'acht'),(9,N'neun'),
			(10,N'zehn'),(11,N'elf'),(12,N'zwölf'),(13,N'dreizehn'),(14,N'vierzehn'),(15,N'fünfzehn'),(16,N'sechzehn'),(17,N'siebzehn'),(18,N'achtzehn'),(19,N'neunzehn'),
			(20,N'zwanzig'),(30,N'dreiβig'),(40,N'vierzig'),(50,N'fünfzig'),(60,N'sechzig'),(70,N'siebzig'),(80,N'achtzig'),(90,N'neunzig')
	
	DECLARE @ZeroWord		NVARCHAR(10) = N'null'
	DECLARE @DotWord		NVARCHAR(10) = N'Komma'
	DECLARE @AndWord		NVARCHAR(10) = N'und'
	DECLARE @HundredWord	NVARCHAR(10) = N'hundert'
	DECLARE @ThousandWord	NVARCHAR(10) = N'tausend'
	DECLARE @MillionWord	NVARCHAR(10) = N'Million'
	DECLARE @BillionWord	NVARCHAR(10) = N'Milliarde'
	DECLARE @TrillionWord	NVARCHAR(10) = N'Billion'

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
				IF @v00Num < 20
				BEGIN
					-- less than 20
                    IF @v000Num = 1 AND @vIndex > 1 
                        SET @vSubResult = N'eine'--Adding 'e' to 1 in case of million+
                    ELSE
					    SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than or equal 20
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SET @v00Num = FLOOR(@v00Num/10)*10
					SELECT @vSubResult = FORMATMESSAGE('%s%s%s', @vSubResult, @AndWord, Nam) FROM @tDict WHERE Num = @v00Num 
				END

				--000
				IF @v000Num > 99
					SELECT @vSubResult = FORMATMESSAGE('%s%s%s', Nam, @HundredWord, @vSubResult) FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				SET @vSubResult = FORMATMESSAGE('%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN @ThousandWord
																		WHEN @vIndex=2 THEN ' '+ @MillionWord + CASE WHEN @v000Num > 1 THEN N'en' ELSE '' END
																		WHEN @vIndex=3 THEN ' '+ @BillionWord + CASE WHEN @v000Num > 1 THEN N'n' ELSE '' END
																		WHEN @vIndex=4 THEN ' '+ @TrillionWord + CASE WHEN @v000Num > 1 THEN N'en' ELSE '' END
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN ' '+ (@MillionWord + CASE WHEN @v000Num > 1 THEN N'en' ELSE '' END) + ' ' + TRIM(REPLICATE(@BillionWord + CASE WHEN @v000Num > 1 THEN N'n' ELSE '' END + ' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN ' '+ TRIM(REPLICATE(@BillionWord + CASE WHEN @v000Num > 1 THEN N'n' ELSE '' END + ' ',@vIndex%3))
																		ELSE ''
																	END)
																	
				IF @vIndex <= 1 AND FLOOR(@Number / 1000) > 0
					SET @vResult = FORMATMESSAGE('%s%s', @vSubResult, @vResult)
				ELSE
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
	SELECT dbo.MoneyToWords_DE(3201001.25)
	SELECT dbo.MoneyToWords_DE(123456789.56)
	SELECT dbo.MoneyToWords_DE(123000789.56)
	SELECT dbo.MoneyToWords_DE(123010789.56)
	SELECT dbo.MoneyToWords_DE(123004789.56)
	SELECT dbo.MoneyToWords_DE(123904789.56)
	SELECT dbo.MoneyToWords_DE(205.56)
	SELECT dbo.MoneyToWords_DE(45.1)
	SELECT dbo.MoneyToWords_DE(45.09)
	SELECT dbo.MoneyToWords_DE(0.09)
	SELECT dbo.MoneyToWords_DE(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_DE(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_DE(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_DE(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_DE(100000000000000)
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Denish 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-danish/en/dan/
-- History:
-- Date			Author		Description
-- 2021-01-02	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_DK
GO
CREATE FUNCTION dbo.MoneyToWords_DK(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'en'),(2,N'to'),(3,N'tre'),(4,N'fire'),(5,N'fem'),(6,N'seks'),(7,N'syv'),(8,N'otte'),(9,N'ni'),
			(11,N'elleve'),(12,N'tolv'),(13,N'tretten'),(14,N'fjorten'),(15,N'femten'),(16,N'seksten'),(17,N'sytten'),(18,N'atten'),(19,N'nitten'),
			(10,N'ti'),(20,N'tyve'),(30,N'tredive'),(40,N'fyrre'),(50,N'halvtreds'),(60,N'tres'),(70,N'halvfjerds'),(80,N'firs'),(90,N'halvfems')

	DECLARE @ZeroWord		NVARCHAR(20) = N'nul'
	DECLARE @DotWord		NVARCHAR(20) = N'komma'
	DECLARE @AndWord		NVARCHAR(20) = N'og'
	DECLARE @HundredWord	NVARCHAR(20) = N'hundred'
	DECLARE @HundredWords	NVARCHAR(20) = N'hundrede'
	DECLARE @ThousandWord	NVARCHAR(20) = N'tusind'
	DECLARE @ThousandWords	NVARCHAR(20) = N'tusinde'
	DECLARE @MillionWord	NVARCHAR(20) = N'million'
	DECLARE @MillionWords	NVARCHAR(20) = N'millioner'
	DECLARE @BillionWord	NVARCHAR(20) = N'milliard'
	DECLARE @BillionWords	NVARCHAR(20) = N'milliard'
	DECLARE @TrillionWord	NVARCHAR(20) = N'billion'
	DECLARE @TrillionWords	NVARCHAR(20) = N'billion'

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
					SELECT @vSubResult = RTRIM(FORMATMESSAGE('%s%s%s', @vSubResult, @AndWord, Nam)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					IF @v000Num = 100 AND @vIndex = 0
						SET @vSubResult = @HundredWord
					ELSE
						SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s %s %s', Nam, 
																		CASE WHEN Num > 1 THEN @HundredWords ELSE @HundredWord END, 
																		CASE WHEN @v00Num > 0 THEN @AndWord + N' ' + @vSubResult ELSE N'' END))
						FROM	@tDict
						WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @v000Num = 1 AND @vIndex = 1 AND @vPrev000Number % 1000 = 0
					SET @vSubResult = 'et'

				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN (CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END) + ' ' + TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		ELSE ''
																	END)
				
				IF @vIndex = 1 AND @vPrev000Number % 1000 > 0 AND @vPrev000Number % 1000 < 10
					SET @vResult = FORMATMESSAGE('%s %s %s', LTRIM(@vSubResult), @AndWord, @vResult)
				ELSE
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
	SELECT dbo.MoneyToWords_DK(3201001.25)
	SELECT dbo.MoneyToWords_DK(123456789.56)
	SELECT dbo.MoneyToWords_DK(123000789.56)
	SELECT dbo.MoneyToWords_DK(123010789.56)
	SELECT dbo.MoneyToWords_DK(123004789.56)
	SELECT dbo.MoneyToWords_DK(123904789.56)
	SELECT dbo.MoneyToWords_DK(205.56)
	SELECT dbo.MoneyToWords_DK(45.1)
	SELECT dbo.MoneyToWords_DK(45.09)
	SELECT dbo.MoneyToWords_DK(0.09)
	SELECT dbo.MoneyToWords_DK(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_DK(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_DK(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_DK(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_DK(100000000000000)
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in English
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- History:
-- Date			Author		Description
-- 2020-09-16	NV			Intial
-- 2020-12-07	DN			Fix odd number
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
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
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
				IF @v00Num < 20
				BEGIN
					-- less than 20
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num
					IF @v00Num < 10 AND @v00Num > 0 AND (@v000Num > 99 OR FLOOR(@Number / 1000) > 0)--e.g 1 001: 1000 AND 1; or 201 000: (200 AND 1) 000
						SET @vSubResult = FORMATMESSAGE('%s %s', @AndWord, @vSubResult)
				END
				ELSE 
				BEGIN
					-- greater than or equal 20
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SET @v00Num = FLOOR(@v00Num/10)*10
					SELECT @vSubResult = FORMATMESSAGE('%s-%s', Nam, @vSubResult) FROM @tDict WHERE Num = @v00Num 
				END

				--000
				IF @v000Num > 99
					SELECT @vSubResult = FORMATMESSAGE('%s %s %s', Nam, @HundredWord, @vSubResult) FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN

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

	SET @vResult = FORMATMESSAGE('%s %s', TRIM(@vResult), COALESCE(@DotWord + ' ' + NULLIF(@vSubDecimalResult,''), ''))
	
	-- result
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_EN(3201001.25)
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
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Spainish
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.fluentin3months.com/spanish-numbers
-- History:
-- Date			Author		Description
-- 2020-12-24	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_ES
GO
CREATE FUNCTION dbo.MoneyToWords_ES(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'uno'),(2,N'dos'),(3,N'tres'),(4,N'cuatro'),(5,N'cinco'),(6,N'seis'),(7,N'siete'),(8,N'ocho'),(9,N'nueve'),
			(10,N'diez'),(11,N'once'),(12,N'doce'),(13,N'trece'),(14,N'catorce'),(15,N'quince'),(16,N'dieciséis'),(17,N'diecisiete'),(18,N'dieciocho'),(19,N'diecinueve'),
			(20,N'veinte'),(21,N'veintiuno'),(22,N'veintidós'),(23,N'veintitrés'),(24,N'veinticuatro'),(25,N'veinticinco'),(26,N'veintiséis'),(27,N'veintisiete'),(28,N'veintiocho'),(29,N'veintinueve'),
			(30,N'treinta'),(40,N'cuarenta'),(50,N'cincuenta'),(60,N'sesenta'),(70,N'setenta'),(80,N'ochenta'),(90,N'noventa'),
			(100,N'ciento'),(200,N'doscientos'),(300,N'trescientos'),(400,N'cuatrocientos'),(500,N'quinientos'),(600,N'seiscientos'),(700,N'setecientos'),(800,N'ochocientos'),(900,N'novecientos')
	
	DECLARE @ZeroWord			NVARCHAR(20) = N'cero'
	DECLARE @DotWord			NVARCHAR(20) = N'punto'
	DECLARE @AndWord			NVARCHAR(20) = N'y'
	DECLARE @HundredWord		NVARCHAR(20) = N'ciento'
	DECLARE @HundredWords		NVARCHAR(20) = N'cientos'
	DECLARE @ThousandWord		NVARCHAR(20) = N'mil'
	DECLARE @ThousandWords		NVARCHAR(20) = N'mil'
	DECLARE @MillionWord		NVARCHAR(20) = N'millón'
	DECLARE @MillionWords		NVARCHAR(20) = N'millones'
	DECLARE @TrillionWord		NVARCHAR(20) = N'billón'
	DECLARE @TrillionWords		NVARCHAR(20) = N'billones'
	DECLARE @QuadrillionWord	NVARCHAR(20) = N'mil billones'
	DECLARE @QuadrillionWords	NVARCHAR(20) = N'mil billones'
	DECLARE @QuintillionWord	NVARCHAR(20) = N'trillón'
	DECLARE @QuintillionWords	NVARCHAR(20) = N'trillones'

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
				IF @v00Num < 30
				BEGIN
					-- less than 30
                    SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than or equal 30
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SELECT @vSubResult = FORMATMESSAGE('%s %s %s', Nam, @AndWord, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10 
				END

				--000
				IF @v000Num = 100
					SET @vSubResult = LEFT(@HundredWord,5)--removing "o" ending as 100 = cient but 101 = ciento uno
				ELSE IF @v000Num > 100
				BEGIN
					SELECT	@vSubResult = FORMATMESSAGE('%s %s', (CASE WHEN Num > 1 THEN Nam ELSE '' END), @vSubResult) 
					FROM	@tDict
					WHERE	Num = FLOOR(@v000Num/100)*100
				END
			END
			
			--000 xxx
			IF @vSubResult <> '' 
			BEGIN
				IF @v000Num = 1 AND @vIndex = 1 --No "number" in the front for 101 (ciento uno) and 1001 (mil uno)
					SET @vSubResult = ''
				IF @v000Num = 1 AND @vIndex >= 2--but 200 or 10 000 we do have as "doscientos" or "diez mil"
					SET @vSubResult = 'un'--removing "o" ending of 1 = "uno"

				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 OR @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex=5 THEN CASE WHEN @v000Num > 1 THEN @QuadrillionWords ELSE @QuadrillionWord END
																		WHEN @vIndex=6 THEN CASE WHEN @v000Num > 1 THEN @QuintillionWords ELSE @QuintillionWord END
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
	SELECT dbo.MoneyToWords_ES(3201001.25)
	SELECT dbo.MoneyToWords_ES(123456789.56)
	SELECT dbo.MoneyToWords_ES(123000789.56)
	SELECT dbo.MoneyToWords_ES(123010789.56)
	SELECT dbo.MoneyToWords_ES(123004789.56)
	SELECT dbo.MoneyToWords_ES(123904789.56)
	SELECT dbo.MoneyToWords_ES(205.56)
	SELECT dbo.MoneyToWords_ES(45.1)
	SELECT dbo.MoneyToWords_ES(45.09)
	SELECT dbo.MoneyToWords_ES(0.09)
	SELECT dbo.MoneyToWords_ES(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_ES(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_ES(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_ES(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_ES(100000000000000)
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Finish 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-finnish/en/fin/
-- History:
-- Date			Author		Description
-- 2021-01-02	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_FI
GO
CREATE FUNCTION dbo.MoneyToWords_FI(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'yksi'),(2,N'kaksi'),(3,N'kolme'),(4,N'neljä'),(5,N'viisi'),(6,N'kuusi'),(7,N'seitsemän'),(8,N'kahdeksan'),(9,N'yhdeksän'),
			(11,N'yksitoista'),(12,N'kaksitoista'),(13,N'kolmetoista'),(14,N'neljätoista'),(15,N'viisitoista'),(16,N'kuusitoista'),(17,N'seitsemäntoista'),(18,N'kahdeksantoista'),(19,N'yhdeksäntoista'),
			(10,N'kymmenen'),(20,N'kaksikymmentä'),(30,N'kolmekymmentä'),(40,N'neljäkymmentä'),(50,N'viisikymmentä'),(60,N'kuusikymmentä'),(70,N'seitsemänkymmentä'),(80,N'kahdeksankymmentä'),(90,N'yhdeksänkymmentä')

	DECLARE @ZeroWord		NVARCHAR(20) = N'nolla'
	DECLARE @DotWord		NVARCHAR(20) = N'pilkku'
	DECLARE @AndWord		NVARCHAR(20) = N''
	DECLARE @HundredWord	NVARCHAR(20) = N'sata'
	DECLARE @HundredWords	NVARCHAR(20) = N'sataa'
	DECLARE @ThousandWord	NVARCHAR(20) = N'tuhat'
	DECLARE @ThousandWords	NVARCHAR(20) = N'tuhatta'
	DECLARE @MillionWord	NVARCHAR(20) = N'miljoona'
	DECLARE @MillionWords	NVARCHAR(20) = N'miljoonaa'
	DECLARE @BillionWord	NVARCHAR(20) = N'miljardi'
	DECLARE @BillionWords	NVARCHAR(20) = N'miljardia'
	DECLARE @TrillionWord	NVARCHAR(20) = N'biljoona'
	DECLARE @TrillionWords	NVARCHAR(20) = N'biljoonaa'

	-- decimal number	
	DECLARE @vDecimalNum INT = (@Number - FLOOR(@Number)) * 100
	DECLARE @vLoop SMALLINT = CONVERT(SMALLINT, SQL_VARIANT_PROPERTY(@Number, 'Scale'))
	DECLARE @vSubDecimalResult	NVARCHAR(MAX) = N''
	IF @vDecimalNum > 0
	BEGIN
		WHILE @vLoop > 0
		BEGIN
			IF @vDecimalNum % 10 = 0
				SET @vSubDecimalResult = FORMATMESSAGE(N'%s %s', @ZeroWord, @vSubDecimalResult)
			ELSE
				SELECT	@vSubDecimalResult = FORMATMESSAGE(N'%s %s', Nam, @vSubDecimalResult)
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
		DECLARE @vSubResult	NVARCHAR(MAX) = N''
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
					SELECT @vSubResult = RTRIM(FORMATMESSAGE(N'%s%s', Nam, @vSubResult)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					IF @v000Num < 200
						SET @vSubResult = FORMATMESSAGE(N'%s%s', @HundredWord, @vSubResult)
					ELSE
						SELECT	@vSubResult = RTRIM(FORMATMESSAGE(N'%s%s%s', Nam, @HundredWords, @vSubResult))
						FROM	@tDict
						WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @v000Num = 1 AND @vIndex = 1 AND @vPrev000Number % 1000 = 0
					SET @vSubResult = N''

				SET @vSubResult = FORMATMESSAGE(N'%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN (CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END) + N' ' + TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + N' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + N' ',@vIndex%3))
																		ELSE ''
																	END)
				
				SET @vResult = FORMATMESSAGE(N'%s%s', LTRIM(@vSubResult), @vResult)
			END

			-- next 000 (to left)
			SET @vIndex = @vIndex + 1
			SET @vPrev000Number = @Number
			SET @Number = FLOOR(@Number / 1000)
		END
	END

	SET @vResult = FORMATMESSAGE(N'%s %s', TRIM(@vResult), COALESCE(@DotWord + N' ' + NULLIF(@vSubDecimalResult,N''), N''))
	
	-- result
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_FI(3201001.25)
	SELECT dbo.MoneyToWords_FI(123456789.56)
	SELECT dbo.MoneyToWords_FI(123000789.56)
	SELECT dbo.MoneyToWords_FI(123010789.56)
	SELECT dbo.MoneyToWords_FI(123004789.56)
	SELECT dbo.MoneyToWords_FI(123904789.56)
	SELECT dbo.MoneyToWords_FI(205.56)
	SELECT dbo.MoneyToWords_FI(45.1)
	SELECT dbo.MoneyToWords_FI(45.09)
	SELECT dbo.MoneyToWords_FI(0.09)
	SELECT dbo.MoneyToWords_FI(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_FI(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_FI(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_FI(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_FI(100000000000000)
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in French
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.woodwardfrench.com/lesson/numbers-from-1-to-100-in-french/
-- https://www.lawlessfrench.com/vocabulary/numbers-and-counting-3/
-- History:
-- Date			Author		Description
-- 2020-09-12	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_FR
GO
CREATE FUNCTION MoneyToWords_FR(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	--Return result when zero
	SET @Number = ABS(@Number)
	IF @Number = 0
		RETURN N'zéro'

	--Calculation if non-zero
	DECLARE @vResult NVARCHAR(MAX) = N''

	DECLARE @tTo19		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tTo19 (Num, Nam)
	VALUES	(0,N'zéro'), (1,N'un'),(2,N'deux'),(3,N'trois'),(4,N'quatre'),(5,N'cinq'),(6,N'six'),(7,N'sept'),(8,N'huit'),(9,N'neuf'),
			(10,N'dix'),(11,N'onze'),(12,N'douze'),(13,N'treize'),(14,N'quatorze'),(15,N'quinze'),(16,N'seize'),(17,N'dix-sept'),(18,N'dix-huit'),(19,N'dix-neuf')

	DECLARE @tTen		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tTen (Num, Nam)
	VALUES	(20,N'vingt'),(30,N'trente'),(40,N'quarante'),(50,N'cinquante'),(60,N'soixante'),(70,N'soixante'),(80,N'quatre-vingts'),(90,N'quatre-vingt')
	--NOTE: 80 has 's' in 'vingt' but 81+ does not has 's'

	DECLARE @tTenOddOne	TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tTenOddOne (Num, Nam)
	VALUES	(21,N'vingt-et-un'),(31,N'trente-et-un'),(41,N'quarante-et-un'),(51,N'cinquante-et-un'),(61,N'soixante-et-un'),(71,N'soixante-et-onze'),(81,N'quatre-vingt-un'),(91,N'quatre-vingt-onze')
	
	DECLARE @DotWord		NVARCHAR(10) = N'virgule'
	DECLARE @HundredWord	NVARCHAR(10) = N'cent'
	DECLARE @ThousandWord	NVARCHAR(10) = N'mille'
	DECLARE @MillionWord	NVARCHAR(10) = N'million'
	DECLARE @BillionWord	NVARCHAR(10) = N'milliard'
	DECLARE @TrillionWord	NVARCHAR(10) = N'billion'
	--NOTE: For 'mille' - it is invariable, it doesn’t become 'milles'
	--		Cent, Million, Milliard and Billion take on an s when plural
	--		When cents is followed by another number, it loses the s: deux cents but deux cent un
	
	--Decimal numbers
	DECLARE @vDecimalNum INT = (@Number - FLOOR(@Number)) * 100
	DECLARE @vLoop SMALLINT = CONVERT(SMALLINT, SQL_VARIANT_PROPERTY(@Number, 'Scale'))
	DECLARE @vSubDecimalResult	NVARCHAR(MAX) = N''
	IF @vDecimalNum > 0
	BEGIN
		WHILE @vLoop > 0
		BEGIN
			SELECT	@vSubDecimalResult = FORMATMESSAGE('%s %s', Nam, @vSubDecimalResult)
			FROM	@tTo19
			WHERE	Num = @vDecimalNum%10

			SET @vDecimalNum = FLOOR(@vDecimalNum/10)
			SET @vLoop = @vLoop - 1
		END
	END

	--Main numbers
	DECLARE @vSubResult	NVARCHAR(MAX) = N''
	DECLARE @v000Num DECIMAL(15,0) = 0
	DECLARE @v00Num DECIMAL(15,0) = 0
	DECLARE @vIndex SMALLINT = 0
	SET @Number = FLOOR(@Number)
	WHILE 1 = 1
	BEGIN
		-- from right to left: take first 000
		SET @v000Num = @Number % 1000	--hundreds
		SET @v00Num = @v000Num % 100	--tens
		
		IF @v000Num = 0 AND @vIndex > 0
		BEGIN
			SET @vSubResult = ''
		END
		ELSE
		BEGIN
			--zero
			IF @v00Num = 0 AND FLOOR(@v000Num/100) > 0
			BEGIN
				SET @vSubResult =''
			END
			--less than 20
			ELSE IF @v00Num < 20
			BEGIN
				SELECT @vSubResult = Nam FROM @tTo19 WHERE Num = @v00Num
			END
			--greater than or equal 20
			ELSE IF @v00Num % 10 = 1 --but odd
			BEGIN
				SELECT @vSubResult = Nam FROM @tTenOddOne WHERE Num = @v00Num
			END
			--others
			ELSE
			BEGIN
				SELECT	@vSubResult = CASE WHEN Num = 80 THEN REPLACE(Nam,'s','') ELSE Nam END FROM @tTen WHERE Num = FLOOR(@v00Num/10)*10
				SELECT	@vSubResult = FORMATMESSAGE('%s-%s', @vSubResult, Nam) 
				FROM	@tTo19
				WHERE	Num = CASE
								WHEN FLOOR(@v00Num/10) = 7 THEN @v00Num-60--7x = 60+1x
								WHEN FLOOR(@v00Num/10) = 9 THEN @v00Num-80--9x = (4*20)+1x
								ELSE @v00Num % 10
							END
			END

			--hundreds wording
			IF FLOOR(@v000Num/100) > 0
			BEGIN
				SELECT	@vSubResult = TRIM(FORMATMESSAGE('%s %s%s %s', 
															(CASE WHEN Num > 1 THEN Nam ELSE '' END), 
															@HundredWord, 
															(CASE WHEN Num > 1 AND @v00Num = 0 THEN 's' ELSE '' END),
															@vSubResult))
				FROM	@tTo19 
				WHERE	Num = FLOOR(@v000Num/100)
			END
		END

		--
		IF @vSubResult <> ''
		BEGIN
			--thousands+ wording
			SET @vSubResult = FORMATMESSAGE('%s %s%s', @vSubResult,
														CASE 
															WHEN @vIndex=1 THEN @ThousandWord
															WHEN @vIndex=2 THEN @MillionWord
															WHEN @vIndex=3 THEN @BillionWord
															WHEN @vIndex=4 THEN @TrillionWord
															WHEN @vIndex>4 THEN '***'
															ELSE ''
														END,
														CASE 
															WHEN @v000Num > 1 AND @vIndex > 1 THEN 's'
															ELSE ''
														END)
			SET @vResult = TRIM(FORMATMESSAGE('%s %s',TRIM(@vSubResult), @vResult))
		END
		
		-- next 000 (to left)
		SET @vIndex = @vIndex + 1
		SET @Number = FLOOR(@Number / 1000)
		IF @Number = 0 BREAK
	END

	SET @vResult = FORMATMESSAGE('%s %s', @vResult, COALESCE(@DotWord + ' ' + NULLIF(@vSubDecimalResult,''), ''))

	-- result
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_FR(255.56)
	SELECT dbo.MoneyToWords_FR(123456789.56) --123 456 789.56
	SELECT dbo.MoneyToWords_FR(123000789.23) --123 000 789.23
	SELECT dbo.MoneyToWords_FR(323010789.06) --323 010 789.06
	SELECT dbo.MoneyToWords_FR(123004789.13) --123 004 789.13
	SELECT dbo.MoneyToWords_FR(923904789.49) --923 904 789.49
	SELECT dbo.MoneyToWords_FR(171.99)
	SELECT dbo.MoneyToWords_FR(181.01)
	SELECT dbo.MoneyToWords_FR(285.56)
	SELECT dbo.MoneyToWords_FR(205.28)
	SELECT dbo.MoneyToWords_FR(45.00)
	SELECT dbo.MoneyToWords_FR(0.29)
	SELECT dbo.MoneyToWords_FR(0.0)
	SELECT dbo.MoneyToWords_FR(1200567896789.02)--1 200 567 896 789.02
	SELECT dbo.MoneyToWords_FR(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_FR(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_FR(823234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_FR(999999999999999.99)--999 999 999 999 999.99	
*/
GO
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
GO
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
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Hindi (HI)
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-hindi/en/hin/
-- History:
-- Date			Author		Description
-- 2021-01-17	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_HI
GO
CREATE FUNCTION dbo.MoneyToWords_HI(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'एक'),(2,N'दो'),(3,N'तीन'),(4,N'चार'),(5,N'पाँच'),(6,N'छह'),(7,N'सात'),(8,N'आठ'),(9,N'नौ'),
			(11,N'ग्यारह'),(12,N'बारह'),(13,N'तेरह'),(14,N'चौदह'),(15,N'पंद्रह'),(16,N'सोलह'),(17,N'सत्रह'),(18,N'अट्ठारह'),(19,N'उन्नीस'),
			(10,N'दस'),(20,N'बीस'),(30,N'तीस'),(40,N'चालीस'),(50,N'पचास'),(60,N'साठ'),(70,N'सत्तर'),(80,N'अस्सी'),(90,N'नब्बे')
	/*
		Compound numbers above twenty-one are quite regular, starting with the unit root and ending with the ten, with a lot of vowel change.
		The numbers ending with nine are suffixed by the following ten. Hence here is the full list of them
	*/
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(21,N'इक्कीस'),(22,N'बाईस'),(23,N'तेईस'),(24,N'चौबिस'),(25,N'पच्चीस'),(26,N'छब्बीस'),(27,N'सत्ताईस'),(28,N'अट्ठाईस'),(29,N'उनतीस'),
			(31,N'इकतीस'),(32,N'बत्तीस'),(33,N'तैंतीस'),(34,N'चौंतीस'),(35,N'पैंतीस'),(36,N'छत्तीस'),(37,N'सैंतीस'),(38,N'अड़तीस'),(39,N'उनतालीस'),
			(41,N'इकतालीस'),(42,N'बयालीस'),(43,N'तैंतालीस'),(44,N'चौंतालीस'),(45,N'पैंतालीस'),(46,N'छयालीस'),(47,N'सैंतालीस'),(48,N'अड़तालीस'),(49,N'उनचास'),
			(51,N'इक्यावन'),(52,N'बावन'),(53,N'तिरेपन'),(54,N'चौवन'),(55,N'पचपन'),(56,N'छप्पन'),(57,N'सत्तावन'),(58,N'अट्ठावन'),(59,N'उनसठ'),
			(61,N'इकसठ'),(62,N'बासठ'),(63,N'तिरेसठ'),(64,N'चौंसठ'),(65,N'पैंसठ'),(66,N'छयासठ'),(67,N'सरसठ'),(68,N'अड़सठ'),(69,N'उनहत्तर'),
			(71,N'इकहत्तर'),(72,N'बहत्तर'),(73,N'तिहत्तर'),(74,N'चौहत्तर'),(75,N'पचहत्तर'),(76,N'छिहत्तर'),(77,N'सतहत्तर'),(78,N'अठहत्तर'),(79,N'उन्यासी'),
			(81,N'इक्यासी'),(82,N'बयासी'),(83,N'तिरासी'),(84,N'चौरासी'),(85,N'पचासी'),(86,N'छियासी'),(87,N'सत्तासी'),(88,N'अठासी'),(89,N'नवासी'),
			(91,N'इक्यानवे'),(92,N'बानवे'),(93,N'तिरानवे'),(94,N'चौरानवे'),(95,N'पचानवे'),(96,N'छियानवे'),(97,N'सत्तानवे'),(98,N'अट्ठानवे'),(99,N'निन्यानवे')
	
	DECLARE @ZeroWord				NVARCHAR(20) = N'शून्य'
	DECLARE @DotWord				NVARCHAR(20) = N'बिंदु'
	DECLARE @AndWord				NVARCHAR(20) = N''
	DECLARE @HundredWord			NVARCHAR(20) = N'सौ'
	DECLARE @HundredWords			NVARCHAR(20) = N'सौ'
	DECLARE @ThousandWord			NVARCHAR(20) = N'हज़ार'
	DECLARE @ThousandWords			NVARCHAR(20) = N'हज़ार'
	DECLARE @HundredThousandWord	NVARCHAR(20) = N'लाख'
	DECLARE @HundredThousandWords	NVARCHAR(20) = N'लाख'
	DECLARE @TenMillionWord			NVARCHAR(20) = N'करोड़'
	DECLARE @TenMillionWords		NVARCHAR(20) = N'करोड़'
	DECLARE @BillionWord			NVARCHAR(20) = N'अरब'
	DECLARE @BillionWords			NVARCHAR(20) = N'अरब'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_HI(@vDecimalNum)
	
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
			/*
				The Indian counting system (or more exactly the counting system the Indian subcontinent) 
				groups the decimals by three only up to one thousand, then groups them by two beyond
			*/
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
				 SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num

				--000
				IF @v000Num > 99
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s %s %s', Nam, @HundredWord, @vSubResult))
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
																		--01 00 00 00 000 to 99 00 00 00 000 = 01 000 000 000 to 99 000 000 000
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num=1 THEN @BillionWord ELSE @BillionWords END
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
	SELECT dbo.MoneyToWords_HI(3201001.25)
	SELECT dbo.MoneyToWords_HI(123456789.56)
	SELECT dbo.MoneyToWords_HI(123000789.56)
	SELECT dbo.MoneyToWords_HI(123010789.56)
	SELECT dbo.MoneyToWords_HI(123004789.56)
	SELECT dbo.MoneyToWords_HI(123904789.56)
	SELECT dbo.MoneyToWords_HI(205.56)
	SELECT dbo.MoneyToWords_HI(45.1)
	SELECT dbo.MoneyToWords_HI(45.09)
	SELECT dbo.MoneyToWords_HI(0.09)
	SELECT dbo.MoneyToWords_HI(1234567896789.02)--34 567 896 789.02
	SELECT dbo.MoneyToWords_HI(1234567896789.52)--34 567 896 789.52
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Indonesian (ID)
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-indonesian/en/ind/
-- History:
-- Date			Author		Description
-- 2021-01-10	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_ID
GO
CREATE FUNCTION dbo.MoneyToWords_ID(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'satu'),(2,N'dua'),(3,N'tiga'),(4,N'empat'),(5,N'lima'),(6,N'enam'),(7,N'tujuh'),(8,N'delapan'),(9,N'sembilan'),
			(11,N'sebelas'),(12,N'dua belas'),(13,N'tiga belas'),(14,N'empat belas'),(15,N'lima belas'),(16,N'enam belas'),(17,N'tujuh belas'),(18,N'delapan belas'),(19,N'sembilan belas'),
			(10,N'sepuluh'),(20,N'dua puluh'),(30,N'tiga puluh'),(40,N'empat puluh'),(50,N'lima puluh'),(60,N'enam puluh'),(70,N'tujuh puluh'),(80,N'delapan puluh'),(90,N'sembilan puluh')
	
	DECLARE @ZeroWord			NVARCHAR(20) = N'nol'
	DECLARE @DotWord			NVARCHAR(20) = N'koma'
	DECLARE @AndWord			NVARCHAR(20) = N''
	DECLARE @1HundredPrefix		NVARCHAR(20) = N'se'
	DECLARE @HundredWord		NVARCHAR(20) = N'ratus'
	DECLARE @ThousandWord		NVARCHAR(20) = N'ribu'
	DECLARE @MillionWord		NVARCHAR(20) = N'juta'
	DECLARE @BillionWord		NVARCHAR(20) = N'milyar'
	DECLARE @TrillionWord		NVARCHAR(20) = N'seribu milyar'

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
					SELECT	@vSubResult = FORMATMESSAGE('%s%s %s', (CASE WHEN Num > 1 THEN Nam+N' ' ELSE N'se' END), @HundredWord, @vSubResult) 
					FROM	@tDict
					WHERE	Num = FLOOR(@v000Num/100)
			END
			
			--000 xxx
			IF @vSubResult <> '' 
			BEGIN
				IF @vIndex >= 3 AND @v000Num = 1
					SET @vSubResult = N''

				SET @vSubResult = FORMATMESSAGE('%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num = 1 THEN N'se' ELSE N' ' END+@ThousandWord
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num = 1 THEN N'se' ELSE N' ' END+@MillionWord
																		WHEN @vIndex=3 THEN N' '+@BillionWord
																		WHEN @vIndex=4 THEN N' '+@TrillionWord
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
	SELECT dbo.MoneyToWords_ID(3201001.25)
	SELECT dbo.MoneyToWords_ID(123456789.56)
	SELECT dbo.MoneyToWords_ID(123000789.56)
	SELECT dbo.MoneyToWords_ID(123010789.56)
	SELECT dbo.MoneyToWords_ID(123004789.56)
	SELECT dbo.MoneyToWords_ID(123904789.56)
	SELECT dbo.MoneyToWords_ID(205.56)
	SELECT dbo.MoneyToWords_ID(45.1)
	SELECT dbo.MoneyToWords_ID(45.09)
	SELECT dbo.MoneyToWords_ID(0.09)
	SELECT dbo.MoneyToWords_ID(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_ID(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_ID(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_ID(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_ID(100000000000000)
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Italian
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.italianpod101.com/blog/2019/10/24/italian-numbers/
-- History:
-- Date			Author		Description
-- 2020-12-07	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_IT
GO
CREATE FUNCTION dbo.MoneyToWords_IT(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'uno'),(2,N'due'),(3,N'tre'),(4,N'quattro'),(5,N'cinque'),(6,N'sei'),(7,N'sette'),(8,N'otto'),(9,N'nove'),
			(10,N'dieci'),(11,N'undici'),(12,N'dodici'),(13,N'tredici'),(14,N'quattordici'),(15,N'quindici'),(16,N'sedici'),(17,N'diciassette'),(18,N'diciotto'),(19,N'diciannove'),
			(20,N'venti'),(30,N'trenta'),(40,N'quaranta'),(50,N'cinquanta'),(60,N'sessanta'),(70,N'settanta'),(80,N'ottanta'),(90,N'novanta')
	
	DECLARE @ZeroWord		NVARCHAR(10) = N'zero'
	DECLARE @DotWord		NVARCHAR(10) = N'virgola'
	DECLARE @AndWord		NVARCHAR(10) = N'e'
	DECLARE @HundredWord	NVARCHAR(10) = N'cento'
	DECLARE @ThousandWord	NVARCHAR(10) = N'mille'
	DECLARE @ThousandWords	NVARCHAR(10) = N'mila'--plural
	DECLARE @MillionWord	NVARCHAR(10) = N'milione'
	DECLARE @MillionWords	NVARCHAR(10) = N'milioni'--plural
	DECLARE @BillionWord	NVARCHAR(10) = N'miliardo'
	DECLARE @BillionWords	NVARCHAR(10) = N'miliardi'--plural
	DECLARE @TrillionWord	NVARCHAR(10) = N'bilione'
	DECLARE @TrillionWords	NVARCHAR(10) = N'bilioni'--plural

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
				IF @v00Num < 20
				BEGIN
					-- less than 20
                    SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than or equal 20
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SET @v00Num = FLOOR(@v00Num/10)*10
					SELECT @vSubResult = FORMATMESSAGE('%s%s', Nam, @vSubResult) FROM @tDict WHERE Num = @v00Num 
				END

				--000
				IF @v000Num > 99
				BEGIN
					IF @v000Num < 199
						SET @vSubResult = FORMATMESSAGE('%s%s', @HundredWord, @vSubResult)
					ELSE
						SELECT @vSubResult = FORMATMESSAGE('%s%s%s', Nam, @HundredWord, @vSubResult) FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100)
				END
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @v000Num = 1 AND @vIndex > 0 AND @vIndex < 2
					SET @vSubResult = ''
				IF @v000Num = 1 AND @vIndex >= 2
					SET @vSubResult = 'un'

				SET @vSubResult = FORMATMESSAGE('%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN ' '+ CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END + ' ' + @AndWord
																		WHEN @vIndex=3 THEN ' '+ CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN ' '+ CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN ' '+ (CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END) + ' ' + TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN ' '+ TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		ELSE ''
																	END)
																	
				IF @vIndex <= 1
					SET @vResult = FORMATMESSAGE('%s%s', @vSubResult, @vResult)
				ELSE
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
	SELECT dbo.MoneyToWords_IT(3201001.25)
	SELECT dbo.MoneyToWords_IT(123456789.56)
	SELECT dbo.MoneyToWords_IT(1201001.02)
	SELECT dbo.MoneyToWords_IT(1001.22)
	SELECT dbo.MoneyToWords_IT(205.56)
	SELECT dbo.MoneyToWords_IT(45.1)
	SELECT dbo.MoneyToWords_IT(45.09)
	SELECT dbo.MoneyToWords_IT(0.09)
	SELECT dbo.MoneyToWords_IT(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_IT(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_IT(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_IT(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_IT(100000000000000)
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Japanese (in Kanji)
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- History:
-- References:
-- https://www.fluentin3months.com/japanese-numbers/
-- Date			Author		Description
-- 2020-12-31	NV			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_JA
GO
CREATE FUNCTION dbo.MoneyToWords_JA(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'一'),(2,N'二'),(3,N'三'),(4,N'四'),(5,N'五'),(6,N'六'),(7,N'七'),(8,N'八'),(9,N'九'),(10,N'十'),
			(0,N'')
	
	DECLARE @ZeroWord				NVARCHAR(10) = N'零'
	DECLARE @DotWord				NVARCHAR(10) = N'点'
	DECLARE @AndWord				NVARCHAR(10) = N''
	DECLARE @TenWord				NVARCHAR(10) = N'十'
	DECLARE @HundredWord			NVARCHAR(10) = N'百'
	DECLARE @ThousandWord			NVARCHAR(10) = N'千'
	DECLARE @ManWord				NVARCHAR(10) = N'万'--man (1 0000)
	DECLARE @DoubleManWord			NVARCHAR(10) = N'億'--ichioku (1 0000 0000)
	DECLARE @ChoWord				NVARCHAR(10) = N'兆'--icchou (1 0000 0000 0000)

	-- decimal number	
	DECLARE @vDecimalNum INT = (@Number - FLOOR(@Number)) * 100
	DECLARE @vLoop SMALLINT = CONVERT(SMALLINT, SQL_VARIANT_PROPERTY(@Number, 'Scale'))
	DECLARE @vSubDecimalResult	NVARCHAR(MAX) = N''
	IF @vDecimalNum > 0
	BEGIN
		WHILE @vLoop > 0
		BEGIN
			IF @vDecimalNum % 10 = 0
				SET @vSubDecimalResult = FORMATMESSAGE(N'%s%s', @ZeroWord, @vSubDecimalResult)
			ELSE
				SELECT	@vSubDecimalResult = FORMATMESSAGE(N'%s%s', Nam, @vSubDecimalResult)
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
		DECLARE @v0000Num DECIMAL(15,0) = 0
		DECLARE @v000Num DECIMAL(15,0) = 0
		DECLARE @v00Num DECIMAL(15,0) = 0
		DECLARE @v0Num DECIMAL(15,0) = 0
		DECLARE @vIndex SMALLINT = 0
		
		WHILE @Number > 0
		BEGIN
			-- from right to left: take first 0000
			SET @v0000Num = @Number % 10000
			SET @v000Num = @v0000Num % 1000
			SET @v00Num = @v000Num % 100
			SET @v0Num = @v00Num % 10
			IF @v0000Num = 0
			BEGIN
				SET @vSubResult = N''
			END
			ELSE 
			BEGIN 
				--00
				IF @v00Num <= 10
				BEGIN
					-- less than or equal 10
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than 10
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SELECT @vSubResult = FORMATMESSAGE(N'%s%s%s', Nam, @TenWord, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v00Num/10)
				END

				--000
				IF @v000Num = 100
					SET @vSubResult = @HundredWord
				ELSE IF @v000Num > 100
					SELECT @vSubResult = FORMATMESSAGE(N'%s%s%s', CASE WHEN Num > 1 THEN Nam ELSE '' END, @HundredWord, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v000Num/100)

				--0000
				IF @v0000Num = 1000
					SET @vSubResult = @ThousandWord
				ELSE IF @v0000Num > 1000
					SELECT @vSubResult = FORMATMESSAGE(N'%s%s%s', CASE WHEN Num > 1 THEN Nam ELSE '' END, @ThousandWord, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v0000Num/1000)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN

				SET @vSubResult = FORMATMESSAGE(N'%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN @ManWord
																		WHEN @vIndex=2 THEN @DoubleManWord
																		WHEN @vIndex=3 THEN @ChoWord
																		ELSE ''
																	END)

				SET @vResult = FORMATMESSAGE(N'%s%s', @vSubResult, @vResult)
			END

			-- next 000 (to left)
			SET @vIndex = @vIndex + 1
			SET @Number = FLOOR(@Number / 10000)
		END
	END

	SET @vResult = FORMATMESSAGE(N'%s%s', TRIM(@vResult), COALESCE(@DotWord + NULLIF(@vSubDecimalResult,N''), N''))
	
	-- result
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_JA(3201001.25)
	SELECT dbo.MoneyToWords_JA(123456789.56)
	SELECT dbo.MoneyToWords_JA(123000789.56)
	SELECT dbo.MoneyToWords_JA(123010789.56)
	SELECT dbo.MoneyToWords_JA(123004789.56)
	SELECT dbo.MoneyToWords_JA(123904789.56)
	SELECT dbo.MoneyToWords_JA(205.56)
	SELECT dbo.MoneyToWords_JA(45.1)
	SELECT dbo.MoneyToWords_JA(45.09)
	SELECT dbo.MoneyToWords_JA(0.09)
	SELECT dbo.MoneyToWords_JA(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_JA(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_JA(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_JA(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_JA(100000000000000)
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Korean in Sino-Korean (China System)
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- History:
-- References:
-- https://www.koreanfluent.com/cross_cultural/korean_numbers/korean_numbers.htm
-- https://www.90daykorean.com/korean-numbers/
-- Date			Author		Description
-- 2021-01-01	NV			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_KO
GO
CREATE FUNCTION dbo.MoneyToWords_KO(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'일'),(2,N'이'),(3,N'삼'),(4,N'사'),(5,N'오'),(6,N'육'),(7,N'칠'),(8,N'팔'),(9,N'구'),(10,N'십'),
			(0,N'')
	
	DECLARE @ZeroWord				NVARCHAR(10) = N'영'
	DECLARE @DotWord				NVARCHAR(10) = N'점'
	DECLARE @AndWord				NVARCHAR(10) = N''
	DECLARE @TenWord				NVARCHAR(10) = N'십'
	DECLARE @HundredWord			NVARCHAR(10) = N'백'
	DECLARE @ThousandWord			NVARCHAR(10) = N'천'
	DECLARE @ManWord				NVARCHAR(10) = N'만'--man (1 0000)
	DECLARE @DoubleManWord			NVARCHAR(10) = N'억'--ireok (1 0000 0000)
	DECLARE @ChoWord				NVARCHAR(10) = N'조'--joh (1 0000 0000 0000)

	-- decimal number	
	DECLARE @vDecimalNum INT = (@Number - FLOOR(@Number)) * 100
	DECLARE @vLoop SMALLINT = CONVERT(SMALLINT, SQL_VARIANT_PROPERTY(@Number, 'Scale'))
	DECLARE @vSubDecimalResult	NVARCHAR(MAX) = N''
	IF @vDecimalNum > 0
	BEGIN
		WHILE @vLoop > 0
		BEGIN
			IF @vDecimalNum % 10 = 0
				SET @vSubDecimalResult = FORMATMESSAGE(N'%s %s', @ZeroWord, @vSubDecimalResult)
			ELSE
				SELECT	@vSubDecimalResult = FORMATMESSAGE(N'%s %s', Nam, @vSubDecimalResult)
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
		DECLARE @v0000Num DECIMAL(15,0) = 0
		DECLARE @v000Num DECIMAL(15,0) = 0
		DECLARE @v00Num DECIMAL(15,0) = 0
		DECLARE @v0Num DECIMAL(15,0) = 0
		DECLARE @vIndex SMALLINT = 0
		
		WHILE @Number > 0
		BEGIN
			-- from right to left: take first 0000
			SET @v0000Num = @Number % 10000
			SET @v000Num = @v0000Num % 1000
			SET @v00Num = @v000Num % 100
			SET @v0Num = @v00Num % 10
			IF @v0000Num = 0
			BEGIN
				SET @vSubResult = N''
			END
			ELSE 
			BEGIN 
				--00
				IF @v00Num <= 10
				BEGIN
					-- less than or equal 10
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than 10
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SELECT @vSubResult = FORMATMESSAGE(N'%s%s%s', Nam, @TenWord, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v00Num/10)
				END

				--000
				IF @v000Num = 100
					SET @vSubResult = @HundredWord
				ELSE IF @v000Num > 100
					SELECT @vSubResult = FORMATMESSAGE(N'%s%s%s', CASE WHEN Num > 1 THEN Nam ELSE '' END, @HundredWord, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v000Num/100)

				--0000
				IF @v0000Num = 1000
					SET @vSubResult = @ThousandWord
				ELSE IF @v0000Num > 1000
					SELECT @vSubResult = FORMATMESSAGE(N'%s%s%s', CASE WHEN Num > 1 THEN Nam ELSE '' END, @ThousandWord, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v0000Num/1000)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN

				SET @vSubResult = FORMATMESSAGE(N'%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN @ManWord
																		WHEN @vIndex=2 THEN @DoubleManWord
																		WHEN @vIndex=3 THEN @ChoWord
																		ELSE ''
																	END)

				SET @vResult = FORMATMESSAGE(N'%s %s', @vSubResult, @vResult)
			END

			-- next 000 (to left)
			SET @vIndex = @vIndex + 1
			SET @Number = FLOOR(@Number / 10000)
		END
	END

	SET @vResult = FORMATMESSAGE(N'%s %s', TRIM(@vResult), COALESCE(@DotWord + N' ' + NULLIF(@vSubDecimalResult,N''), N''))
	
	-- result
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_KO(3201001.25)
	SELECT dbo.MoneyToWords_KO(123456789.56)
	SELECT dbo.MoneyToWords_KO(123000789.56)
	SELECT dbo.MoneyToWords_KO(123010789.56)
	SELECT dbo.MoneyToWords_KO(123004789.56)
	SELECT dbo.MoneyToWords_KO(123904789.56)
	SELECT dbo.MoneyToWords_KO(205.56)
	SELECT dbo.MoneyToWords_KO(45.1)
	SELECT dbo.MoneyToWords_KO(45.09)
	SELECT dbo.MoneyToWords_KO(0.09)
	SELECT dbo.MoneyToWords_KO(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_KO(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_KO(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_KO(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_KO(100000000000000)
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Kazakh (KZ) 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-kazakh/en/kaz/
-- History:
-- Date			Author		Description
-- 2021-01-10	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_KZ
GO
CREATE FUNCTION dbo.MoneyToWords_KZ(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'бір'),(2,N'екі'),(3,N'үш'),(4,N'төрт'),(5,N'бес'),(6,N'алты'),(7,N'жеті'),(8,N'сегіз'),(9,N'тоғыз'),
			(11,N'он бір'),(12,N'он екі'),(13,N'он үш'),(14,N'он төрт'),(15,N'он бес'),(16,N'он алты'),(17,N'он жеті'),(18,N'он сегіз'),(19,N'он тоғыз'),
			(10,N'он'),(20,N'жиырма'),(30,N'отыз'),(40,N'қырық'),(50,N'елу'),(60,N'алпыс'),(70,N'жетпіс'),(80,N'сексен'),(90,N'тоқсан')

	DECLARE @ZeroWord		NVARCHAR(20) = N'нөл'
	DECLARE @DotWord		NVARCHAR(20) = N'балл'
	DECLARE @AndWord		NVARCHAR(20) = N''
	DECLARE @HundredWord	NVARCHAR(20) = N'жүз'
	DECLARE @ThousandWord	NVARCHAR(20) = N'мың'
	DECLARE @MillionWord	NVARCHAR(20) = N'миллион'
	DECLARE @BillionWord	NVARCHAR(20) = N'миллиард'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_KZ(@vDecimalNum)
	
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
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s %s %s', CASE WHEN Num > 1 THEN Nam ELSE N'' END, @HundredWord, @vSubResult))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @vIndex >= 1 AND @v000Num = 1 
					SET @vSubResult = N''

				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN @ThousandWord
																		WHEN @vIndex=2 THEN @MillionWord
																		WHEN @vIndex=3 THEN @BillionWord
																		WHEN @vIndex=4 THEN @ThousandWord + N' ' + @BillionWord
																		WHEN @vIndex=5 THEN @MillionWord + N' ' + @BillionWord
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
	SELECT dbo.MoneyToWords_KZ(3201001.25)
	SELECT dbo.MoneyToWords_KZ(123456789.56)
	SELECT dbo.MoneyToWords_KZ(123000789.56)
	SELECT dbo.MoneyToWords_KZ(123010789.56)
	SELECT dbo.MoneyToWords_KZ(123004789.56)
	SELECT dbo.MoneyToWords_KZ(123904789.56)
	SELECT dbo.MoneyToWords_KZ(205.56)
	SELECT dbo.MoneyToWords_KZ(45.1)
	SELECT dbo.MoneyToWords_KZ(45.09)
	SELECT dbo.MoneyToWords_KZ(0.09)
	SELECT dbo.MoneyToWords_KZ(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_KZ(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_KZ(123234567896789.02)--123 234 567 896 789.02	
	SELECT dbo.MoneyToWords_KZ(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_KZ(100000000000000)
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Lithuanian (LT) 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-lithuanian/en/lit/
-- History:
-- Date			Author		Description
-- 2021-01-10	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_LT
GO
CREATE FUNCTION dbo.MoneyToWords_LT(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'vienas'),(2,N'du'),(3,N'trys'),(4,N'keturi'),(5,N'penki'),(6,N'šeši'),(7,N'septyni'),(8,N'aštuoni'),(9,N'devyni'),
			(11,N'vienuolika'),(12,N'dvylika'),(13,N'trylika'),(14,N'keturiolika'),(15,N'penkiolika'),(16,N'šešiolika'),(17,N'septyniolika'),(18,N'aštuoniolika'),(19,N'devyniolika'),
			(10,N'dešimt'),(20,N'dvidešimt'),(30,N'trisdešimt'),(40,N'keturiasdešimt'),(50,N'penkiasdešimt'),(60,N'šešiasdešimt'),(70,N'septyniasdešimt'),(80,N'aštuoniasdešimt'),(90,N'devyniasdešimt')

	DECLARE @ZeroWord			NVARCHAR(20) = N'nulis'
	DECLARE @DotWord			NVARCHAR(20) = N'kablelis'
	DECLARE @AndWord			NVARCHAR(20) = N''
	DECLARE @HundredWord		NVARCHAR(20) = N'šimtas'
	DECLARE @HundredWords		NVARCHAR(20) = N'šimtai'
	DECLARE @ThousandWord		NVARCHAR(20) = N'tūkstantis'
	DECLARE @ThousandWords		NVARCHAR(20) = N'tūkstančiai'
	DECLARE @MillionWord		NVARCHAR(20) = N'milijonas'
	DECLARE @MillionWords		NVARCHAR(20) = N'milijonai'
	DECLARE @BillionWord		NVARCHAR(20) = N'milijardas'
	DECLARE @BillionWords		NVARCHAR(20) = N'milijardai'
	DECLARE @TrillionWord		NVARCHAR(20) = N'trilijonas'
	DECLARE @TrillionWords		NVARCHAR(20) = N'trilijonai'
	DECLARE @QuadrillionWord	NVARCHAR(20) = N'kvadrilijonas'
	DECLARE @QuadrillionWords	NVARCHAR(20) = N'kvadrilijonai'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_LT(@vDecimalNum)
	
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
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s %s %s', 
																CASE WHEN Num > 1 THEN Nam ELSE N'' END,
																CASE WHEN Num > 1 THEN @HundredWords ELSE @HundredWord END,
																@vSubResult))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @vIndex >= 1 AND @v000Num = 1
					SET @vSubResult = N''

				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex=5 THEN CASE WHEN @v000Num > 1 THEN @QuadrillionWords ELSE @QuadrillionWord END
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
	SELECT dbo.MoneyToWords_LT(3201001.25)
	SELECT dbo.MoneyToWords_LT(123456789.56)
	SELECT dbo.MoneyToWords_LT(123000789.56)
	SELECT dbo.MoneyToWords_LT(123010789.56)
	SELECT dbo.MoneyToWords_LT(123004789.56)
	SELECT dbo.MoneyToWords_LT(123904789.56)
	SELECT dbo.MoneyToWords_LT(205.56)
	SELECT dbo.MoneyToWords_LT(45.1)
	SELECT dbo.MoneyToWords_LT(45.09)
	SELECT dbo.MoneyToWords_LT(0.09)
	SELECT dbo.MoneyToWords_LT(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_LT(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_LT(123234567896789.02)--123 234 567 896 789.02	
	SELECT dbo.MoneyToWords_LT(999999999999999.99)--999 999 999 999 999.99
	SELECT dbo.MoneyToWords_LT(100000000000000)
*/
GO
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
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Norwegian (NO)
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-norwegian-bokmal/en/nob/
-- History:
-- Date			Author		Description
-- 2021-01-10	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_NO
GO
CREATE FUNCTION dbo.MoneyToWords_NO(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'én'),(2,N'to'),(3,N'tre'),(4,N'fire'),(5,N'fem'),(6,N'seks'),(7,N'sju'),(8,N'åtte'),(9,N'ni'),
			(11,N'elleve'),(12,N'tolv'),(13,N'tretten'),(14,N'fjorten'),(15,N'femten'),(16,N'seksten'),(17,N'sytten'),(18,N'atten'),(19,N'nitten'),
			(10,N'ti'),(20,N'tjue'),(30,N'tretti'),(40,N'førti'),(50,N'femti'),(60,N'seksti'),(70,N'sytti'),(80,N'åtti'),(90,N'nitti')

	DECLARE @ZeroWord			NVARCHAR(20) = N'null'
	DECLARE @DotWord			NVARCHAR(20) = N'komma'
	DECLARE @AndWord			NVARCHAR(20) = N'og'
	DECLARE @HundredWord		NVARCHAR(20) = N'hundre'
	DECLARE @HundredWords		NVARCHAR(20) = N'hundre'
	DECLARE @ThousandWord		NVARCHAR(20) = N'ett tusen'
	DECLARE @ThousandWords		NVARCHAR(20) = N'tusen'
	DECLARE @MillionWord		NVARCHAR(20) = N'million'
	DECLARE @MillionWords		NVARCHAR(20) = N'millioner'
	DECLARE @BillionWord		NVARCHAR(20) = N'milliard'
	DECLARE @BillionWords		NVARCHAR(20) = N'milliard'
	--DECLARE @TrillionWord		NVARCHAR(20) = N'trillion'
	--DECLARE @TrillionWords		NVARCHAR(20) = N'billioner'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_NO(@vDecimalNum)
	
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
                    SELECT @vSubResult = (CASE WHEN FLOOR(@Number/1000)>0 AND Num<10 THEN @AndWord+N' ' ELSE N'' END) + Nam FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than 20
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SELECT @vSubResult = RTRIM(FORMATMESSAGE('%s%s', Nam, @vSubResult)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s %s %s', 
																CASE WHEN Num > 1 THEN Nam ELSE N'' END,
																CASE WHEN Num > 1 THEN @HundredWords ELSE @HundredWord END,
																CASE WHEN @vSubResult LIKE +N'%'+@AndWord+N' %' OR @v00Num = 0 THEN @vSubResult ELSE @AndWord+N' '+@vSubResult END))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @vIndex = 1 AND @v000Num = 1
					SET @vSubResult = @ThousandWord
				ELSE
					SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																			WHEN @vIndex=1 THEN @ThousandWords
																			WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																			WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																			WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																			--WHEN @vIndex=5 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
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
	SELECT dbo.MoneyToWords_NO(3201001.25)
	SELECT dbo.MoneyToWords_NO(123456789.56)
	SELECT dbo.MoneyToWords_NO(123000789.56)
	SELECT dbo.MoneyToWords_NO(123010789.56)
	SELECT dbo.MoneyToWords_NO(123004789.56)
	SELECT dbo.MoneyToWords_NO(123904789.56)
	SELECT dbo.MoneyToWords_NO(205.56)
	SELECT dbo.MoneyToWords_NO(45.1)
	SELECT dbo.MoneyToWords_NO(45.09)
	SELECT dbo.MoneyToWords_NO(0.09)
	SELECT dbo.MoneyToWords_NO(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_NO(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_NO(123234567896789.02)--123 234 567 896 789.02	
	SELECT dbo.MoneyToWords_NO(999999999999999.99)--999 999 999 999 999.99
	SELECT dbo.MoneyToWords_NO(100000000000000)
*/
GO
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
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Portuguese 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://ielanguages.com/portuguese-numbers.html
-- https://www.languagesandnumbers.com/how-to-count-in-portuguese-portugal/en/por-prt/
-- History:
-- Date			Author		Description
-- 2021-01-01	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_PT
GO
CREATE FUNCTION dbo.MoneyToWords_PT(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'um'),(2,N'dois'),(3,N'tr�s'),(4,N'quatro'),(5,N'cinco'),(6,N'seis'),(7,N'sete'),(8,N'oito'),(9,N'nove'),
			(10,N'dez'),(11,N'onze'),(12,N'doze'),(13,N'treze'),(14,N'catorze'),(15,N'quinze'),(16,N'dezesseis'),(17,N'dezessete'),(18,N'dezoito'),(19,N'dezenove'),
			(20,N'vinte'),(30,N'trinta'),(40,N'quarenta'),(50,N'cinq�enta'),(60,N'sessenta'),(70,N'setenta'),(80,N'oitenta'),(90,N'noventa'),
			(100,N'cento'),(200,N'duzentos'),(300,N'trezentos'),(400,N'quatrocentos'),(500,N'quinhentos'),(600,N'seiscentos'),(700,N'setecentos'),(800,N'oitocentos'),(900,N'novecentos')
	
	DECLARE @ZeroWord		NVARCHAR(20) = N'zero'
	DECLARE @DotWord		NVARCHAR(20) = N'v�rgula'
	DECLARE @AndWord		NVARCHAR(20) = N'e'
	DECLARE @HundredWord	NVARCHAR(20) = N'cem'
	DECLARE @ThousandWord	NVARCHAR(20) = N'mil'
	DECLARE @ThousandWords	NVARCHAR(20) = N'mil'
	DECLARE @MillionWord	NVARCHAR(20) = N'milh�o'
	DECLARE @MillionWords	NVARCHAR(20) = N'milh�es'
	DECLARE @BillionWord	NVARCHAR(20) = N'mil milh�es'
	DECLARE @BillionWords	NVARCHAR(20) = N'mil milh�es'
	DECLARE @TrillionWord	NVARCHAR(20) = N'bili�o'
	DECLARE @TrillionWords	NVARCHAR(20) = N'bili�es'

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
		DECLARE @vPrev000Number DECIMAL(17,2) = 0
		
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
					SELECT @vSubResult = FORMATMESSAGE('%s %s %s', Nam, @AndWord, @vSubResult) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10 
				END

				--000
				IF @v000Num = 100
					SET @vSubResult = @HundredWord
				ELSE IF @v00Num = 0
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100)*100
				ELSE IF @v000Num > 100
					SELECT @vSubResult = FORMATMESSAGE('%s %s %s', Nam, @AndWord, @vSubResult) FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100)*100
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN (CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END) + ' ' + TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		ELSE ''
																	END)

				IF @vResult <> '' AND @vIndex >=1 AND (@vPrev000Number % 100 = 0 OR @vPrev000Number < 10)
					SET @vResult = FORMATMESSAGE('%s %s %s', @vSubResult, @AndWord, @vResult)
				ELSE
					SET @vResult = FORMATMESSAGE('%s %s', @vSubResult, @vResult)
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
	SELECT dbo.MoneyToWords_PT(3201001.25)
	SELECT dbo.MoneyToWords_PT(123456789.56)
	SELECT dbo.MoneyToWords_PT(123000789.56)
	SELECT dbo.MoneyToWords_PT(123010789.56)
	SELECT dbo.MoneyToWords_PT(123004789.56)
	SELECT dbo.MoneyToWords_PT(123904789.56)
	SELECT dbo.MoneyToWords_PT(205.56)
	SELECT dbo.MoneyToWords_PT(45.1)
	SELECT dbo.MoneyToWords_PT(45.09)
	SELECT dbo.MoneyToWords_PT(0.09)
	SELECT dbo.MoneyToWords_PT(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_PT(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_PT(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_PT(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_PT(100000000000000)
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Russian 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-russian/en/rus/
-- History:
-- Date			Author		Description
-- 2021-01-03	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_RU
GO
CREATE FUNCTION dbo.MoneyToWords_RU(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'один'),(2,N'две'),(3,N'три'),(4,N'четыре'),(5,N'пять'),(6,N'шесть'),(7,N'семь'),(8,N'восемь'),(9,N'девять'),
			(11,N'одиннадцать'),(12,N'двенадцать'),(13,N'тринадцать'),(14,N'четырнадцать'),(15,N'пятнадцать'),(16,N'шестнадцать'),(17,N'семнадцать'),(18,N'восемнадцать'),(19,N'девятнадцать'),
			(10,N'десять'),(20,N'двадцать'),(30,N'тридцать'),(40,N'сорок'),(50,N'пятьдесят'),(60,N'шестьдесят'),(70,N'семьдесят'),(80,N'восемьдесят'),(90,N'девяносто'),
			(100,N'сто'),(200,N'двести'),(300,N'триста'),(400,N'четыреста'),(500,N'пятьсот'),(600,N'шестьсот'),(700,N'семьсот'),(800,N'восемьсот'),(900,N'девятьсот'),
			(1000,N'тысяча'),(2000,N'две тысячи'),(3000,N'три тысячи'),(4000,N'четыре тысячи')

	DECLARE @ZeroWord		NVARCHAR(20) = N'ноль'
	DECLARE @DotWord		NVARCHAR(20) = N'запятая'
	DECLARE @AndWord		NVARCHAR(20) = N'и'
	DECLARE @HundredWord	NVARCHAR(20) = N'сто'
	DECLARE @HundredWords	NVARCHAR(20) = N'сто'
	DECLARE @ThousandWord	NVARCHAR(20) = N'тысяч'
	DECLARE @ThousandWords	NVARCHAR(20) = N'тысяч'
	DECLARE @MillionWord	NVARCHAR(20) = N'миллион'
	DECLARE @MillionWords	NVARCHAR(20) = N'миллион'
	DECLARE @BillionWord	NVARCHAR(20) = N'миллиард'
	DECLARE @BillionWords	NVARCHAR(20) = N'миллиард'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_RU(@vDecimalNum)
	
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
				IF @vIndex%3=1 AND @v000Num%1000 = 1
					SELECT	@vSubResult = Nam
					FROM	@tDict
					WHERE	Num = @v000Num%1000 * 1000
				ELSE IF @vIndex%3=1 AND @v000Num%10 IN (2,3,4)
					SET @vSubResult = LTRIM(FORMATMESSAGE('%s%s%s',
														COALESCE((SELECT Nam+N' ' FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100) * 100),N''),
														COALESCE((SELECT Nam+N' ' FROM @tDict WHERE Num = CONVERT(INT,@v00Num / 10) * 10),N''),
														(SELECT Nam FROM @tDict WHERE Num = @v000Num%10*1000)))
				ELSE
					SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																			WHEN @vIndex=0 THEN N''
																			WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																			WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																			WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																			WHEN @vIndex>3 AND @vIndex%3=2 THEN (CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END) + ' ' + TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																			WHEN @vIndex>3 AND @vIndex%3=0 THEN TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																			ELSE @ThousandWords
																		END)
				
				IF @vIndex = 0 OR (@vIndex = 1 AND @vPrev000Number%1000 < 100 AND @vPrev000Number%1000 > 0) OR @vResult = ''
					SET @vResult = FORMATMESSAGE('%s %s', LTRIM(@vSubResult), @vResult)
				ELSE
					SET @vResult = FORMATMESSAGE('%s, %s', LTRIM(@vSubResult), @vResult)
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
	SELECT dbo.MoneyToWords_RU(3201001.25)
	SELECT dbo.MoneyToWords_RU(123456789.56)
	SELECT dbo.MoneyToWords_RU(123000789.56)
	SELECT dbo.MoneyToWords_RU(123010789.56)
	SELECT dbo.MoneyToWords_RU(123004789.56)
	SELECT dbo.MoneyToWords_RU(123904789.56)
	SELECT dbo.MoneyToWords_RU(205.56)
	SELECT dbo.MoneyToWords_RU(45.1)
	SELECT dbo.MoneyToWords_RU(45.09)
	SELECT dbo.MoneyToWords_RU(0.09)
	SELECT dbo.MoneyToWords_RU(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_RU(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_RU(123234567896789.02)--123 234 567 896 789.02	
	SELECT dbo.MoneyToWords_RU(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_RU(100000000000000)
*/
GO
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
	VALUES	(1,N'ena'),(2,N'dve'),(3,N'tri'),(4,N'štiri'),(5,N'pet'),(6,N'šest'),(7,N'sedem'),(8,N'osem'),(9,N'devet'),
			(11,N'enajst'),(12,N'dvanajst'),(13,N'trinajst'),(14,N'štirinajst'),(15,N'petnajst'),(16,N'šestnajst'),(17,N'sedemnajst'),(18,N'osemnajst'),(19,N'devetnajst'),
			(10,N'deset'),(20,N'dvajset'),(30,N'trideset'),(40,N'štirideset'),(50,N'petdeset'),(60,N'šestdeset'),(70,N'sedemdeset'),(80,N'osemdeset'),(90,N'devetdeset')

	DECLARE @ZeroWord		NVARCHAR(20) = N'nič'
	DECLARE @DotWord		NVARCHAR(20) = N'celih'
	DECLARE @AndWord		NVARCHAR(20) = N'in'
	DECLARE @HundredWord	NVARCHAR(20) = N'sto'
	DECLARE @HundredWords	NVARCHAR(20) = N'sto'
	DECLARE @ThousandWord	NVARCHAR(20) = N'tisoč'
	DECLARE @ThousandWords	NVARCHAR(20) = N'tisoč'
	DECLARE @MillionWord	NVARCHAR(20) = N'milijon'
	DECLARE @MillionWords	NVARCHAR(20) = N'milijona'
	DECLARE @MillionWordss	NVARCHAR(20) = N'milijonov'
	DECLARE @BillionWord	NVARCHAR(20) = N'milijarda'
	DECLARE @BillionWords	NVARCHAR(20) = N'milijardi'
	DECLARE @TrillionWord	NVARCHAR(20) = N'bilijon'
	DECLARE @TrillionWords	NVARCHAR(20) = N'bilijoni'

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
					SELECT @vSubResult = LTRIM(FORMATMESSAGE('%s%s%s', @vSubResult, @AndWord, Nam)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s%s %s', CASE WHEN Num>1 THEN Nam ELSE N'' END, CASE WHEN Num>1 THEN @HundredWords ELSE @HundredWord END, @vSubResult))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100)
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
																			WHEN @vIndex=2 THEN CASE WHEN @v000Num = 2 THEN @MillionWords WHEN @v000Num > 2 THEN @MillionWordss ELSE @MillionWord END
																			WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																			WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
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
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Serbian (SR) 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-serbian/en/srp/
-- History:
-- Date			Author		Description
-- 2021-01-12	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_SR
GO
CREATE FUNCTION dbo.MoneyToWords_SR(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'један'),(2,N'два'),(3,N'три'),(4,N'четири'),(5,N'пет'),(6,N'шест'),(7,N'седам'),(8,N'осам'),(9,N'девет'),
			(11,N'једанаест'),(12,N'дванаест'),(13,N'тринаест'),(14,N'четрнаест'),(15,N'петнаест'),(16,N'шеснаест'),(17,N'седамнаест'),(18,N'осамнаест'),(19,N'деветнаест'),
			(10,N'десет'),(20,N'двадесет'),(30,N'тридесет'),(40,N'четрдесет'),(50,N'педесет'),(60,N'шездесет'),(70,N'седамдесет'),(80,N'осамдесет'),(90,N'деведесет')

	DECLARE @ZeroWord		NVARCHAR(20) = N'нула'
	DECLARE @DotWord		NVARCHAR(20) = N'поен'
	DECLARE @AndWord		NVARCHAR(20) = N'и'
	DECLARE @HundredWord	NVARCHAR(20) = N'сто'
	DECLARE @HundredWordx	NVARCHAR(20) = N'ста'--2,3
	DECLARE @HundredWords	NVARCHAR(20) = N'сто'
	DECLARE @ThousandWord	NVARCHAR(20) = N'хиљада'
	DECLARE @ThousandWordx	NVARCHAR(20) = N'хиљаде'--2,3,4
	DECLARE @ThousandWords	NVARCHAR(20) = N'хиљада'
	DECLARE @MillionWord	NVARCHAR(20) = N'милион'
	DECLARE @MillionWords	NVARCHAR(20) = N'милиона'
	DECLARE @BillionWord	NVARCHAR(20) = N'милијарда'
	DECLARE @BillionWordx	NVARCHAR(20) = N'милијарде'--2,3,4
	DECLARE @BillionWords	NVARCHAR(20) = N'милијарди'
	DECLARE @TrillionWord	NVARCHAR(20) = N'билион'
	DECLARE @TrillionWords	NVARCHAR(20) = N'билиона'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_SR(@vDecimalNum)
	
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
					SELECT @vSubResult = RTRIM(FORMATMESSAGE('%s %s %s', Nam, @AndWord, @vSubResult)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					SELECT	@vSubResult = RTRIM(FORMATMESSAGE('%s%s %s', 
														CASE WHEN Num>1 THEN Nam ELSE N'' END,
														CASE WHEN Num=1 THEN @HundredWord WHEN Num IN (2) THEN N' '+@HundredWord WHEN Num IN (3) THEN @HundredWordx ELSE @HundredWords END,
														@vSubResult))
					FROM	@tDict
					WHERE	Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @vIndex=1 AND @v000Num=1
					SET @vSubResult = N''

				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num=1 THEN @ThousandWord WHEN @v000Num IN (2,3,4) THEN @ThousandWordx ELSE @ThousandWords END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num=1 THEN @BillionWord WHEN @v000Num IN (2,3,4) THEN @BillionWordx ELSE @BillionWords END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		ELSE N''
																	END)
				
				IF (@vIndex = 1 AND @vPrev000Number%1000 < 100) OR @vResult = ''
					SET @vResult = RTRIM(FORMATMESSAGE('%s %s', @vSubResult, @vResult))
				ELSE 
					SET @vResult = FORMATMESSAGE('%s, %s', @vSubResult, @vResult)
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
	SELECT dbo.MoneyToWords_SR(3201001.25)
	SELECT dbo.MoneyToWords_SR(123456789.56)
	SELECT dbo.MoneyToWords_SR(123000789.56)
	SELECT dbo.MoneyToWords_SR(123010789.56)
	SELECT dbo.MoneyToWords_SR(123004789.56)
	SELECT dbo.MoneyToWords_SR(123904789.56)
	SELECT dbo.MoneyToWords_SR(205.56)
	SELECT dbo.MoneyToWords_SR(45.1)
	SELECT dbo.MoneyToWords_SR(45.09)
	SELECT dbo.MoneyToWords_SR(0.09)
	SELECT dbo.MoneyToWords_SR(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_SR(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_SR(123234567896789.02)--123 234 567 896 789.02	
	SELECT dbo.MoneyToWords_SR(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_SR(100000000000000)
*/
GO
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
GO
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
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Turkish 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-turkish/en/tur/
-- History:
-- Date			Author		Description
-- 2021-01-01	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_TR
GO
CREATE FUNCTION dbo.MoneyToWords_TR(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'bir'),(2,N'iki'),(3,N'üç'),(4,N'dört'),(5,N'beş'),(6,N'altı'),(7,N'yedi'),(8,N'sekiz'),(9,N'dokuz'),
			(10,N'on'),(20,N'yirmi'),(30,N'otuz'),(40,N'kırk'),(50,N'elli'),(60,N'altmış'),(70,N'yetmiş'),(80,N'seksen'),(90,N'doksan')

	DECLARE @ZeroWord		NVARCHAR(20) = N'sıfır'
	DECLARE @DotWord		NVARCHAR(20) = N'virgül'
	DECLARE @AndWord		NVARCHAR(20) = N'e'
	DECLARE @HundredWord	NVARCHAR(20) = N'yüz'
	DECLARE @ThousandWord	NVARCHAR(20) = N'bin'
	DECLARE @ThousandWords	NVARCHAR(20) = N'bin'
	DECLARE @MillionWord	NVARCHAR(20) = N'milyon'
	DECLARE @MillionWords	NVARCHAR(20) = N'milyon'
	DECLARE @BillionWord	NVARCHAR(20) = N'milyar'
	DECLARE @BillionWords	NVARCHAR(20) = N'milyar'
	DECLARE @TrillionWord	NVARCHAR(20) = N'trilyon'
	DECLARE @TrillionWords	NVARCHAR(20) = N'trilyon'

	-- decimal number	
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_TR(@vDecimalNum)
	
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
				IF @v00Num < 10
				BEGIN
					-- less than 10
                    SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than or equal 10
					SELECT @vSubResult = Nam FROM @tDict WHERE Num = @v0Num 
					SELECT @vSubResult = RTRIM(FORMATMESSAGE('%s %s', Nam, @vSubResult)) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10
				END

				--000
				IF @v000Num > 99
					SELECT @vSubResult = FORMATMESSAGE('%s %s %s', CASE WHEN Num > 1 THEN Nam ELSE '' END, @HundredWord, @vSubResult) FROM @tDict WHERE Num = CONVERT(INT,@v000Num / 100)
			END
			
			--000xxx
			IF @vSubResult <> ''
			BEGIN
				IF @v000Num = 1 AND @vIndex = 1
					SET @vSubResult = ''

				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num > 1 THEN @ThousandWords ELSE @ThousandWord END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		WHEN @vIndex>3 AND @vIndex%3=2 THEN (CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END) + ' ' + TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		WHEN @vIndex>3 AND @vIndex%3=0 THEN TRIM(REPLICATE((CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END) + ' ',@vIndex%3))
																		ELSE ''
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
	SELECT dbo.MoneyToWords_TR(3201001.25)
	SELECT dbo.MoneyToWords_TR(123456789.56)
	SELECT dbo.MoneyToWords_TR(123000789.56)
	SELECT dbo.MoneyToWords_TR(123010789.56)
	SELECT dbo.MoneyToWords_TR(123004789.56)
	SELECT dbo.MoneyToWords_TR(123904789.56)
	SELECT dbo.MoneyToWords_TR(205.56)
	SELECT dbo.MoneyToWords_TR(45.1)
	SELECT dbo.MoneyToWords_TR(45.09)
	SELECT dbo.MoneyToWords_TR(0.09)
	SELECT dbo.MoneyToWords_TR(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_TR(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_TR(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_TR(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_TR(100000000000000)
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Ukrainian (UK) 
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://www.languagesandnumbers.com/how-to-count-in-ukrainian/en/ukr/
-- History:
-- Date			Author		Description
-- 2021-01-14	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_UK
GO
CREATE FUNCTION dbo.MoneyToWords_UK(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'один'),(2,N'два'),(3,N'три'),(4,N'чотири'),(5,N'п’ять'),(6,N'шість'),(7,N'сім'),(8,N'вісім'),(9,N'дев’ять'),
			(11,N'одинадцять'),(12,N'дванадцять'),(13,N'тринадцять'),(14,N'чотирнадцять'),(15,N'п’ятнадцять'),(16,N'шістнадцять'),(17,N'сімнадцять'),(18,N'вісімнадцять'),(19,N'дев’ятнадцять'),
			(10,N'десять'),(20,N'двадцять'),(30,N'тридцять'),(40,N'сорок'),(50,N'п’ятдесят'),(60,N'шістдесят'),(70,N'сімдесят'),(80,N'вісімдесят'),(90,N'дев’яносто'),
			(100,N'сто'),(200,N'двісті'),(300,N'триста'),(400,N'чотириста'),(500,N'п’ятсот'),(600,N'шістсот'),(700,N'сімсот'),(800,N'вісімсот'),(900,N'дев’ятсот')

	DECLARE @ZeroWord		NVARCHAR(20) = N'нуль'
	DECLARE @DotWord		NVARCHAR(20) = N'кома'
	DECLARE @AndWord		NVARCHAR(20) = N''
	DECLARE @TwoWordx		NVARCHAR(20) = N'дві'
	--DECLARE @HundredWord	NVARCHAR(20) = N'сто'
	--DECLARE @HundredWords	NVARCHAR(20) = N'сто'
	DECLARE @ThousandWord	NVARCHAR(20) = N'тисяча'
	DECLARE @ThousandWordx	NVARCHAR(20) = N'тисячі'--2,3,4
	DECLARE @ThousandWords	NVARCHAR(20) = N'тисяч'
	DECLARE @MillionWord	NVARCHAR(20) = N'мільйон'
	DECLARE @MillionWords	NVARCHAR(20) = N'мільйон'
	DECLARE @BillionWord	NVARCHAR(20) = N'мільярд'
	DECLARE @BillionWords	NVARCHAR(20) = N'мільярд'
	DECLARE @TrillionWord	NVARCHAR(20) = N'трильйон'
	DECLARE @TrillionWords	NVARCHAR(20) = N'трильйон'

	-- decimal number		
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vSubDecimalResult NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vSubDecimalResult = dbo.MoneyToWords_UK(@vDecimalNum)
	
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
                    SELECT @vSubResult = (CASE WHEN @vIndex>=1 AND Num=2 THEN @TwoWordx ELSE Nam END) FROM @tDict WHERE Num = @v00Num
				END
				ELSE 
				BEGIN
					-- greater than 20
					SELECT @vSubResult = (CASE WHEN @vIndex>=1 AND Num=2 THEN @TwoWordx ELSE Nam END) FROM @tDict WHERE Num = @v0Num 
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
				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN CASE WHEN @v000Num=1 THEN @ThousandWord WHEN @v000Num%10 IN (2,3,4) THEN @ThousandWordx ELSE @ThousandWords END
																		WHEN @vIndex=2 THEN CASE WHEN @v000Num > 1 THEN @MillionWords ELSE @MillionWord END
																		WHEN @vIndex=3 THEN CASE WHEN @v000Num > 1 THEN @BillionWords ELSE @BillionWord END
																		WHEN @vIndex=4 THEN CASE WHEN @v000Num > 1 THEN @TrillionWords ELSE @TrillionWord END
																		ELSE N''
																	END)
				
				IF (@vIndex = 1 AND @vPrev000Number%1000 < 100 AND @vPrev000Number%1000 > 0) OR @vResult = N''
					SET @vResult = FORMATMESSAGE('%s %s', LTRIM(@vSubResult), @vResult)
				ELSE
					SET @vResult = FORMATMESSAGE('%s, %s', LTRIM(@vSubResult), @vResult)
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
	SELECT dbo.MoneyToWords_UK(3201001.25)
	SELECT dbo.MoneyToWords_UK(123456789.56)
	SELECT dbo.MoneyToWords_UK(123000789.56)
	SELECT dbo.MoneyToWords_UK(123010789.56)
	SELECT dbo.MoneyToWords_UK(123004789.56)
	SELECT dbo.MoneyToWords_UK(123904789.56)
	SELECT dbo.MoneyToWords_UK(205.56)
	SELECT dbo.MoneyToWords_UK(45.1)
	SELECT dbo.MoneyToWords_UK(45.09)
	SELECT dbo.MoneyToWords_UK(0.09)
	SELECT dbo.MoneyToWords_UK(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_UK(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_UK(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_UK(999999999999999.99)--999 999 999 999 999.99
	SELECT dbo.MoneyToWords_UK(100000000000000)
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Vietnamese
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://yourvietnamese.com/learn-vietnamese/say-numbers-in-vietnamese/
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
	DECLARE @tTo19		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tTo19 (Num, Nam)
	VALUES	(1,N'một'),(2,N'hai'),(3,N'ba'),(4,N'bốn'),(5,N'năm'),(6,N'sáu'),(7,N'bảy'),(8,N'tám'),(9,N'chín'),
			(10,N'mười'),(11,N'mười một'),(12,N'mười hai'),(13,N'mười ba'),(14,N'mười bốn'),(15,N'mười lăm'),(16,N'mười sáu'),(17,N'mười bảy'),(18,N'mười tám'),(19,N'mười chín')
	
	DECLARE @ZeroWord		NVARCHAR(10) = N'không'
	DECLARE @DotWord		NVARCHAR(10) = N'phẩy'
	DECLARE @FirstWord		NVARCHAR(10) = N'mốt'
	DECLARE @OddWord		NVARCHAR(10) = N'lẻ'
	DECLARE @FifthWord		NVARCHAR(10) = N'lăm'
	DECLARE @TensWord		NVARCHAR(10) = N'mươi'
	DECLARE @HundredWord	NVARCHAR(10) = N'trăm'
	DECLARE @ThousandWord	NVARCHAR(10) = N'nghìn'
	DECLARE @MillionWord	NVARCHAR(10) = N'triệu'
	DECLARE @BillionWord	NVARCHAR(10) = N'tỷ'

	-- decimal number
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vDecimalWords NVARCHAR(255)
	IF @vDecimalNum <> 0
		SET @vDecimalWords = dbo.MoneyToWords_VI(@vDecimalNum)
		IF @vDecimalNum < 10 SET @vDecimalWords = REPLACE(@vDecimalWords,@OddWord,@ZeroWord)
		
	-- main number
	SET @Number = FLOOR(@Number)
	IF @Number = 0
		SET @vResult = @ZeroWord
	ELSE
	BEGIN
		DECLARE @vSubResult	NVARCHAR(MAX) = N''
		DECLARE @v000Num DECIMAL(15,0) = 0
		DECLARE @v00Num DECIMAL(15,0) = 0
		DECLARE @vIndex SMALLINT = 0
		WHILE @Number > 0
		BEGIN
			-- from right to left: take first 000
			SET @v000Num = @Number % 1000
			SET @v00Num = @v000Num % 100
			IF @v000Num = 0
			BEGIN
				SET @vSubResult = ''
			END
			ELSE IF @v00Num < 20
			BEGIN
				-- less than 20
				SELECT @vSubResult = Nam FROM @tTo19 WHERE Num = @v00Num
				IF @v000Num >= 100 AND @v00Num < 10--odd
					SET @vSubResult = FORMATMESSAGE('%s %s', @OddWord, @vSubResult)
			END
			ELSE
			BEGIN
				-- greater than or equal 20
				SELECT @vSubResult = Nam FROM @tTo19 WHERE Num = CONVERT(INT,@v00Num / 10)
				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, @TensWord)
				SELECT @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE WHEN Num=5 THEN @FifthWord ELSE Nam END) FROM @tTo19 WHERE Num = CONVERT(INT,@v00Num % 10)
			END

			IF @vSubResult <> ''
			BEGIN
				SELECT @vSubResult = FORMATMESSAGE('%s %s %s', Nam, @HundredWord, @vSubResult) FROM @tTo19 WHERE Num = CONVERT(INT,@v000Num / 100)--000
				SET @vSubResult = FORMATMESSAGE('%s %s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN @ThousandWord
																		WHEN @vIndex=2 THEN @MillionWord
																		WHEN @vIndex=3 THEN @BillionWord
																		WHEN @vIndex>3 AND @vIndex%3=1 THEN @ThousandWord + ' ' + TRIM(REPLICATE(@BillionWord + ' ',@vIndex%3))
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
	SET @vResult = TRIM(FORMATMESSAGE('%s %s', TRIM(@vResult), COALESCE(@DotWord+' '+@vDecimalWords, '')))
    RETURN @vResult
END
/*	
	SELECT dbo.MoneyToWords_VI(255.56)
	SELECT dbo.MoneyToWords_VI(123456789.56)
	SELECT dbo.MoneyToWords_VI(123000789.56)
	SELECT dbo.MoneyToWords_VI(123010789.56)
	SELECT dbo.MoneyToWords_VI(123004789.56)
	SELECT dbo.MoneyToWords_VI(123904789.56)
	SELECT dbo.MoneyToWords_VI(205.56)
	SELECT dbo.MoneyToWords_VI(45.00)
	SELECT dbo.MoneyToWords_VI(0.29)
	SELECT dbo.MoneyToWords_VI(0.0)
	SELECT dbo.MoneyToWords_VI(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_VI(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_VI(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_VI(999999999999999.99)--999 999 999 999 999.99	
*/
GO
--======================================================
-- Usage:	Lib: MoneyToWords in Dutch (NL)
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- References:
-- https://omniglot.com/language/numbers/dutch.htm
-- https://www.dutch-and-go.com/numbers-how-to-count-in-dutch/
-- History:
-- Date			Author		Description
-- 2021-01-17	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_NL
GO
CREATE FUNCTION dbo.MoneyToWords_NL(@Number DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	SET @Number = ABS(@Number)
	DECLARE @vResult NVARCHAR(MAX) = ''

	-- pre-data
	DECLARE @tDict		TABLE (Num INT NOT NULL, Nam NVARCHAR(255) NOT NULL)
	INSERT 
	INTO	@tDict (Num, Nam)
	VALUES	(1,N'één'),(2,N'twee'),(3,N'drie'),(4,N'vier'),(5,N'vijf'),(6,N'zes'),(7,N'zeven'),(8,N'acht'),(9,N'negen'),
			(11,N'elf'),(12,N'twaalf'),(13,N'dertien'),(14,N'veertien'),(15,N'vijftien'),(16,N'zestien'),(17,N'zeventien'),(18,N'achttien'),(19,N'negentien'),
			--(21,N'eenentwintig'),(22,N'tweeëntwintig'),(23,N'drieëntwintig'),(24,N'vierentwintig'),(25,N'vijfentwintig'),(26,N'zesentwintig'),(27,N'zevenentwintig'),(28,N'achtentwintig'),(29,N'negenentwintig'),
			(10,N'tien'),(20,N'twintig'),(30,N'dertig'),(40,N'veertig'),(50,N'vijftig'),(60,N'zestig'),(70,N'zeventig'),(80,N'tachtig'),(90,N'negentig')
	
	DECLARE @ZeroWord			NVARCHAR(20) = N'nul'
	DECLARE @DotWord			NVARCHAR(20) = N'komma'
	DECLARE @AndWord			NVARCHAR(20) = N'en'
	DECLARE @HundredWord		NVARCHAR(20) = N'honderd'
	DECLARE @ThousandWord		NVARCHAR(20) = N'duizend'
	DECLARE @MillionWord		NVARCHAR(20) = N'miljoen'
	DECLARE @BilllionWord		NVARCHAR(20) = N'miljard'
	DECLARE @TrillionWord		NVARCHAR(20) = N'biljoen'
	DECLARE @QuadrillionWord	NVARCHAR(20) = N'biljard'
	DECLARE @QuintillionWord	NVARCHAR(20) = N'triljoen'

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
					SELECT @vSubResult = FORMATMESSAGE('%s%s%s', @vSubResult, @AndWord, Nam) FROM @tDict WHERE Num = FLOOR(@v00Num/10)*10 
				END

				--000
				IF @v000Num > 99
				BEGIN
					SELECT	@vSubResult = FORMATMESSAGE('%s%s%s', (CASE WHEN Num > 1 THEN Nam ELSE N'' END), @HundredWord, @vSubResult) 
					FROM	@tDict
					WHERE	Num = FLOOR(@v000Num/100)
				END
			END
			
			--000 xxx
			IF @vSubResult <> '' 
			BEGIN
				SET @vSubResult = FORMATMESSAGE('%s%s', @vSubResult, CASE 
																		WHEN @vIndex=1 THEN @ThousandWord
																		WHEN @vIndex=2 THEN N' '+@MillionWord+N' '
																		WHEN @vIndex=3 THEN N' '+@BilllionWord+N' '
																		WHEN @vIndex=4 THEN N' '+@TrillionWord+N' '
																		WHEN @vIndex=5 THEN N' '+@QuadrillionWord+N' '
																		WHEN @vIndex=6 THEN N' '+@QuintillionWord+N' '
																		ELSE N''
																	END)
																	
				SET @vResult = FORMATMESSAGE('%s%s', @vSubResult, @vResult)
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
	SELECT dbo.MoneyToWords_NL(3201001.25)
	SELECT dbo.MoneyToWords_NL(123456789.56)
	SELECT dbo.MoneyToWords_NL(123000789.56)
	SELECT dbo.MoneyToWords_NL(123010789.56)
	SELECT dbo.MoneyToWords_NL(123004789.56)
	SELECT dbo.MoneyToWords_NL(123904789.56)
	SELECT dbo.MoneyToWords_NL(205.56)
	SELECT dbo.MoneyToWords_NL(45.1)
	SELECT dbo.MoneyToWords_NL(45.09)
	SELECT dbo.MoneyToWords_NL(0.09)
	SELECT dbo.MoneyToWords_NL(1234567896789.02)--1 234 567 896 789.02
	SELECT dbo.MoneyToWords_NL(1234567896789.52)--1 234 567 896 789.52
	SELECT dbo.MoneyToWords_NL(123234567896789.02)--123 234 567 896 789.02
	SELECT dbo.MoneyToWords_NL(999999999999999.99)--999 999 999 999 999.99	
	SELECT dbo.MoneyToWords_NL(100000000000000)
*/
GO
--======================================================
-- Usage:	MAIN FUNCTION: MoneyToWords with input money and language
-- Notes:	It DOES NOT support negative number.
--			Please concat 'negative word' into the result in that case
-- History:
-- Date			Author		Description
-- 2020-09-05	DN			Intial
-- 2021-01-17	DN			Finished 30 languages
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords
GO
CREATE FUNCTION MoneyToWords(@Number DECIMAL(17,2), @Lang char(2) = 'en')
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	RETURN CASE 
		WHEN LOWER(@Lang)='ar' THEN dbo.MoneyToWords_AR(@Number)
		WHEN LOWER(@Lang)='cz' THEN dbo.MoneyToWords_CZ(@Number)
		WHEN LOWER(@Lang)='de' THEN dbo.MoneyToWords_DE(@Number)
		WHEN LOWER(@Lang)='dk' THEN dbo.MoneyToWords_DK(@Number)
		WHEN LOWER(@Lang)='es' THEN dbo.MoneyToWords_ES(@Number)
		WHEN LOWER(@Lang)='fi' THEN dbo.MoneyToWords_FI(@Number)
		WHEN LOWER(@Lang)='fr' THEN dbo.MoneyToWords_FR(@Number)
		WHEN LOWER(@Lang)='ga' THEN dbo.MoneyToWords_GA(@Number)
		WHEN LOWER(@Lang)='he' THEN dbo.MoneyToWords_HE(@Number)
		WHEN LOWER(@Lang)='hi' THEN dbo.MoneyToWords_HI(@Number)
		WHEN LOWER(@Lang)='id' THEN dbo.MoneyToWords_ID(@Number)
		WHEN LOWER(@Lang)='th' THEN dbo.MoneyToWords_TH(@Number)
		WHEN LOWER(@Lang)='it' THEN dbo.MoneyToWords_IT(@Number)
		WHEN LOWER(@Lang)='ja' THEN dbo.MoneyToWords_JA(@Number)
		WHEN LOWER(@Lang)='ko' THEN dbo.MoneyToWords_KO(@Number)
		WHEN LOWER(@Lang)='kz' THEN dbo.MoneyToWords_KZ(@Number)
		WHEN LOWER(@Lang)='lt' THEN dbo.MoneyToWords_LT(@Number)
		WHEN LOWER(@Lang)='lv' THEN dbo.MoneyToWords_LV(@Number)
		WHEN LOWER(@Lang)='nl' THEN dbo.MoneyToWords_NL(@Number)
		WHEN LOWER(@Lang)='no' THEN dbo.MoneyToWords_NO(@Number)
		WHEN LOWER(@Lang)='pl' THEN dbo.MoneyToWords_PL(@Number)
		WHEN LOWER(@Lang)='pt' THEN dbo.MoneyToWords_PT(@Number)
		WHEN LOWER(@Lang)='ru' THEN dbo.MoneyToWords_RU(@Number)
		WHEN LOWER(@Lang)='sl' THEN dbo.MoneyToWords_SL(@Number)
		WHEN LOWER(@Lang)='sr' THEN dbo.MoneyToWords_SR(@Number)
		WHEN LOWER(@Lang)='te' THEN dbo.MoneyToWords_TE(@Number)
		WHEN LOWER(@Lang)='tr' THEN dbo.MoneyToWords_TR(@Number)
		WHEN LOWER(@Lang)='uk' THEN dbo.MoneyToWords_UK(@Number)
		WHEN LOWER(@Lang)='vi' THEN dbo.MoneyToWords_VI(@Number)
		ELSE dbo.MoneyToWords_EN(@Number)
	END		
END
GO

COMMIT TRANSACTION ROUTINE
GO
--POST ROUTINE
BEGIN TRANSACTION POSTROUTINE
	SET DEADLOCK_PRIORITY HIGH
COMMIT TRANSACTION POSTROUTINE
GO