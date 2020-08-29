--======================================================
-- Usage:	Lib: MoneyToWords in Vietnamese
-- Notes:	Logic based on https://github.com/savoirfairelinux/num2words/blob/master/num2words/lang_VI.py
-- History:
-- Date			Author		Description
-- 2020-08-31	DN			Intial
--======================================================
DROP FUNCTION IF EXISTS MoneyToWords_VI
GO
CREATE FUNCTION MoneyToWords_VI(@BaseNumber DECIMAL(17,2))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	DECLARE @Result NVARCHAR(MAX) = N''
	DECLARE @vTo19 TABLE (ID int)

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
			Fragement by 1000 then to call Convert_Integer_2text

		Splitted by dot: first.sec
		Result = Main_func(first) + phẩy + Main_func(sec)

	*/

    RETURN @Result
END
/*
	SELECT dbo.MoneyToWords_VI(255)
*/