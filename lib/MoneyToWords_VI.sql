--======================================================
-- Usage:	Lib: MoneyToWords in Vietnamese
-- Notes:	Logic based on https://github.com/savoirfairelinux/num2words/blob/master/num2words/lang_VI.py
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
	DECLARE @Result		NVARCHAR(MAX) = N''
	DECLARE @tTo19		TABLE (Num int NOT NULL, Nam nvarchar(255) NOT NULL)
	INSERT 
	INTO	@tTo19 (Num, Nam)
	VALUES	(0,N'không'),(1,N'một'),(2,N'hai'),(3,N'ba'),(4,N'bốn'),(5,N'năm'),(6,N'sáu'),(7,N'bảy'),(8,N'tám'),(9,N'chín'),
			(10,N'mười'),(11,N'mười một'),(12,N'mười hai'),(13,N'mười ba'),(14,N'mười bốn'),(15,N'mười lăm'),(16,N'mười sáu'),(17,N'mười bảy'),(18,N'mười tám'),(19,N'mười chín')
	
	DECLARE @FirstWord		nvarchar(255) = N'mốt'
	DECLARE @OddWord		nvarchar(255) = N'lẻ'
	DECLARE @TensWord		nvarchar(255) = N'mươi'
	DECLARE @HundredWord	nvarchar(255) = N'trăm'
	DECLARE @ThousandWord	nvarchar(255) = N'nghìn'
	DECLARE @MillionWord	nvarchar(255) = N'triệu'
	DECLARE @BillionWord	nvarchar(255) = N'tỷ'
	DECLARE @DotWord		nvarchar(255) = N'phẩy'

	DECLARE @vMainNum DECIMAL(17,2) = FLOOR(@Number)
	DECLARE @vDecimalNum DECIMAL(17,2) = (@Number - FLOOR(@Number)) * 100
	DECLARE @vDecimalWords NVARCHAR(255)

	IF @vDecimalNum <> 0
		SET @vDecimalWords = dbo.MoneyToWords_VI(@vDecimalNum)

	SET @Result = 'xxx' + COALESCE(' '+@DotWord+' '+@vDecimalWords, '')
	/*
		Convert_Integer_2text
			If n < 100
				convert number xx
			Elif n < 1000
				convert number xxx
			Else
				for (didx, dval) in ((v - 1, 1000 ** v) for v in range(len(denom))):
				if dval > val:
					mod = 1000 ** didx
					lval = val // mod
					r = val - (lval * mod)

					ret = self._convert_nnn(lval) + u' ' + denom[didx]
					if 99 >= r > 0:
						ret = self._convert_nnn(lval) + u' ' + denom[didx] + u' lẻ'
					if r > 0:
						ret = ret + ' ' + self.vietnam_number(r)
					return ret

		Main_func:
			Use Convert_Integer_2text
			Fragement by xxx then to call Convert_Integer_2text

		Splitted by dot: first.sec
		Result = Main_func(first) + phẩy + Main_func(sec)

	*/

    RETURN @Result
END
/*
	SELECT dbo.MoneyToWords_VI(255.56)
*/