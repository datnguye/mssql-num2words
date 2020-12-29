﻿--======================================================
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
			(20,N'veinte'),(30,N'treinta'),(40,N'cuarenta'),(50,N'cincuenta'),(60,N'sesenta'),(70,N'setenta'),(80,N'ochenta'),(90,N'noventa')
	
	DECLARE @ZeroWord		NVARCHAR(10) = N'cero'
	DECLARE @DotWord		NVARCHAR(10) = N''
	DECLARE @AndWord		NVARCHAR(10) = N'y'
	DECLARE @HundredWord	NVARCHAR(10) = N'cien'
	DECLARE @HundredWords	NVARCHAR(10) = N'cientos'
	DECLARE @ThousandWord	NVARCHAR(10) = N'mil'
	DECLARE @ThousandWords	NVARCHAR(10) = N'mil'
	DECLARE @MillionWord	NVARCHAR(10) = N'millón'
	DECLARE @MillionWords	NVARCHAR(10) = N'millones'
	DECLARE @BillionWord	NVARCHAR(10) = N'mil millones'--N'millardo'
	DECLARE @BillionWords	NVARCHAR(10) = N'mil millones'
	DECLARE @TrillionWord	NVARCHAR(10) = N'billón'
	DECLARE @TrillionWords	NVARCHAR(10) = N'billones'

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