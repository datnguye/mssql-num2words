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