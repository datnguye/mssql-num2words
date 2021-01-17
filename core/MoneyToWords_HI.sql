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