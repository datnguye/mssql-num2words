# mssql-num2words
This is the TSQL container to help to convert money to words.

![Alt text](icon.png?raw=true "mssql-num2words icon")

### About
This repo hopefully would be a somwhere for SQL Server Devs to come and take away the functions have been implemented for the multiple languages.
So by the end, it will do:
* Converting MONEY (with 2 decimal places) to WORDS
* 100% TSQL (MSSQL) speaking
* Already supported 30 LANGUAGES in popular
* NOT Machine Learning, ONLY the ALGORITHM
* TESTED in SQL SERVER 2019, but WILL WORK for THE OLDERS too

## Support Languages
* Arabic (AR)
* Czech (CZ)
* German (DE)
* Danish (DK)
* English (EN)
* Spanish (ES)
* Finnish (FI)
* French (FR)
* Irish (GA)
* Hebrew (HE)
* Hindi (HI)
* Indonesian (ID)
* Italian (IT)
* Japanese (JA)
* Korean (KO)
* Kazakh (KZ)
* Lithuanian (LT)
* Latvian (LV)
* Dutch (NL)
* Norwegian (NO)
* Polish (PL)
* Portuguese (PT)
* Russian (RU)
* Slovene (SL)
* Serbian (SR)
* Telugu (TE)
* Thai (TH)
* Turkish (TR)
* Ukrainian (UK)
* Vietnamese (VI)


## Installaton
* Take the file /release/release_1_0.sql and compile into your database(s)
* Open new query, and run somes to make sure that it is working:
```
SELECT dbo.MoneyToWords(9999, 'ar')--Arabic (AR):       تسعة آلَاف تسعة مِئَةٌ تسعة و تسعون 
SELECT dbo.MoneyToWords(9999, 'cz')--Czech (CZ):        devět tisíc devět set devadesát devět 
SELECT dbo.MoneyToWords(9999, 'de')--German (DE):       neuntausend neunhundertneunundneunzig 
SELECT dbo.MoneyToWords(9999, 'dk')--Danish (DK):       ni tusinde ni hundrede og nioghalvfems 
SELECT dbo.MoneyToWords(9999, 'en')--English (EN):      nine thousand nine hundred ninety-nine 
SELECT dbo.MoneyToWords(9999, 'es')--Spanish (ES):      nueve mil novecientos noventa y nueve 
SELECT dbo.MoneyToWords(9999, 'fi')--Finnish (FI):      yhdeksäntuhattayhdeksänsataayhdeksänkymmentäyhdeksän 
SELECT dbo.MoneyToWords(9999, 'fr')--French (FR):       neuf mille neuf cent quatre-vingt-dix-neuf 
SELECT dbo.MoneyToWords(9999, 'ga')--Irish (GA):        naoi míle naoi céad nócha a naoi 
SELECT dbo.MoneyToWords(9999, 'he')--Hebrew (HE):       תֵּשַׁע אֲלָפִים תֵּשַׁע מֵאוֹת תִּשְׁעִים וָתֵּשַׁע 
SELECT dbo.MoneyToWords(9999, 'hi')--Hindi (HI):        निन्यानवे हज़ार नौ सौ निन्यानवे 
SELECT dbo.MoneyToWords(9999, 'id')--Indonesian (ID):   sembilan ribu sembilan ratus sembilan puluh sembilan 
SELECT dbo.MoneyToWords(9999, 'it')--Italian (IT):      novemilanovecentonovantanove 
SELECT dbo.MoneyToWords(9999, 'th')--Thai (TH):         เก้าพันเก้าร้อยเก้าสิบเก้า
SELECT dbo.MoneyToWords(9999, 'ja')--Japanese (JA):     九千九百九十九
SELECT dbo.MoneyToWords(9999, 'ko')--Korean (KO):       구천구백구십구 
SELECT dbo.MoneyToWords(9999, 'kz')--Kazakh (KZ):       тоғыз мың тоғыз жүз тоқсан тоғыз 
SELECT dbo.MoneyToWords(9999, 'lt')--Lithuanian (LT):   devyni tūkstančiai devyni šimtai devyniasdešimt devyni 
SELECT dbo.MoneyToWords(9999, 'lv')--Latvian (LV):      deviņtūkstoši deviņsimt deviņdesmit deviņi 
SELECT dbo.MoneyToWords(9999, 'nl')--Dutch (NL):        negenduizendnegenhonderdnegenennegentig 
SELECT dbo.MoneyToWords(9999, 'no')--Norwegian (NO):    ni tusen ni hundre og nittini 
SELECT dbo.MoneyToWords(9999, 'pl')--Polish (PL):       dziewięć tysięcy dziewięćset dziewięćdziesiąt dziewięć 
SELECT dbo.MoneyToWords(9999, 'pt')--Portuguese (PT):   nove mil novecentos e noventa e nove 
SELECT dbo.MoneyToWords(9999, 'ru')--Russian (RU):      девять тысяч, девятьсот девяносто девять 
SELECT dbo.MoneyToWords(9999, 'sl')--Slovene (SL):      devet tisoč devetsto devetindevetdeset 
SELECT dbo.MoneyToWords(9999, 'sr')--Serbian (SR):      девет хиљада, деветсто деведесет и девет 
SELECT dbo.MoneyToWords(9999, 'te')--Telugu (TE):       తొంభై తొమ్మిది వేలు తొమ్మిది వందల తొంభై తొమ్మిది 
SELECT dbo.MoneyToWords(9999, 'tr')--Turkish (TR):      dokuz bin dokuz yüz doksan dokuz 
SELECT dbo.MoneyToWords(9999, 'uk')--Ukrainian (UK):    дев’ять тисяч, дев’ятсот дев’яносто дев’ять 
SELECT dbo.MoneyToWords(9999, 'vi')--Vietnamese (VI):   chín nghìn chín trăm chín mươi chín
```

## Contacts
Have a touch to us via emails: [Dat Nguyen](mailto:datnguyen.it09@gmail.com),  [Nam Vu](mailto:yvisvu@gmail.com)

Or via the socials: [Facebook](https://www.facebook.com/mssqlnum2words)

At the end, welcome the PR(s) for any issue(s)!