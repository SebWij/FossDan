
-- 1. Stworzenie bazy danych
-- 2. Stworzenie dedykowanej tabeli dla komentarzy Fabryki z Grodziska Maz. i Tuchomia.
-- 3. Dodanie ID komentarza (klucz podstawowy) i ID użykownika (klucz obcy)
-- 4. Stworzenie tabeli zbiorczej opinii o fabrykach FossDan
-- 5. Realizacja KPI's


CREATE DATABASE FossDan

USE FossDan;

Create TABLE OpinieGrodzisk (
Nick NVARCHAR(50),
Platforma NVARCHAR(50),
Ocena FLOAT,
Data1 Date,
Godzina2 Time(7),
LiczbaKomentarzy TINYINT,
Tresc NVARCHAR(250),
);


USE FossDan;

Create TABLE OpinieTuchom (
Nick NVARCHAR(50),
Platforma NVARCHAR(50),
Ocena FLOAT,
Data1 Date,
Godzina2 Time(7),
LiczbaKomentarzy TINYINT,
Tresc NVARCHAR(250),
);

-- Transfer wartosci z tabeli zbiorczej do tabeli docelowej

INSERT INTO OpinieGrodzisk (Nick,
Platforma,
Ocena,
Data1,
Godzina2,
LiczbaKomentarzy,
Tresc)
SELECT Nick,
Platforma,
Ocena,
Data1,
Godzina2,
LiczbaKomentarzy,
Tresc
FROM GroZBIORCZO;


INSERT INTO OpinieTuchom (Nick,
Platforma,
Ocena,
Data1,
Godzina2,
LiczbaKomentarzy,
Tresc)
SELECT Nick,
Platforma,
Ocena,
Data1,
Godzina2,
LiczbaKomentarzy,
Tresc
FROM TuchoZBIORCZO;


-- ID dla każdego komentarza



-- Dla tabeli OpinieTuchom
ALTER TABLE OpinieTuchom
ADD id VARCHAR(5);  

-- Dla tabeli OpinieGrodzisk
ALTER TABLE OpinieGrodzisk
ADD id VARCHAR(5);  

-- Dla tabeli OpinieTuchom
UPDATE OpinieTuchom
SET id = LEFT(NEWID(), 5);  -- Uzupełnienie kolumny id losowymi 5-znakowymi identyfikatorami

-- Dla tabeli OpinieGrodzisk
UPDATE OpinieGrodzisk
SET id = LEFT(NEWID(), 5);  -- Uzupełnienie kolumny id losowymi 5-znakowymi identyfikatorami

-- Dla tabeli OpinieTuchom
ALTER TABLE OpinieTuchom
ALTER COLUMN id VARCHAR(5) NOT NULL; 

-- Dla tabeli OpinieGrodzisk
ALTER TABLE OpinieGrodzisk
ALTER COLUMN id VARCHAR(5) NOT NULL; 

-- Dla tabeli OpinieTuchom
ALTER TABLE OpinieTuchom
ADD CONSTRAINT PK_OpinieTuchom_id PRIMARY KEY (id);  -- Dodanie klucza podstawowego dla kolumny id

-- Dla tabeli OpinieGrodzisk
ALTER TABLE OpinieGrodzisk
ADD CONSTRAINT PK_OpinieGrodzisk_id PRIMARY KEY (id);  -- Dodanie klucza podstawowego dla kolumny id





-- ID użytkownika


CREATE TABLE Uzytkownicy (
    ID INT PRIMARY KEY IDENTITY(1,1), -- Unikalny ID dla każdego użytkownika
    Nick VARCHAR(50) NOT NULL UNIQUE -- Nick musi być unikalny w tej tabeli
);

INSERT INTO Uzytkownicy (Nick)
SELECT DISTINCT Nick
FROM OpinieTuchom
WHERE Nick IS NOT NULL;

ALTER TABLE OpinieTuchom
ADD NickID INT; -- Dodana kolumna z NickID

UPDATE OpinieTuchom -- przypisanie wartosci z tabeli uzytkownicy
SET NickID = (
    SELECT U.ID
    FROM Uzytkownicy AS U
    WHERE U.Nick = OpinieTuchom.Nick
);

-- Dodanie kolumny NickID do tabeli OpinieGrodzisk
ALTER TABLE OpinieGrodzisk
ADD NickID INT;

-- Zaktualizowanie kolumny NickID na podstawie tabeli Uzytkownicy
UPDATE OpinieGrodzisk
SET NickID = (
    SELECT U.ID
    FROM Uzytkownicy AS U
    WHERE U.Nick = OpinieGrodzisk.Nick
);

-- Dodanie klucz obcy do kolumny NickID
ALTER TABLE OpinieGrodzisk
ADD CONSTRAINT FK_OpinieGrodzisk_NickID FOREIGN KEY (NickID) REFERENCES Uzytkownicy(ID);



-- Stworzenie Tabeli zbiorczej OpinieFossDan

CREATE TABLE OpinieFossDan (
    Nick NVARCHAR(50),
    Platforma NVARCHAR(50),
    Ocena FLOAT,
    Data1 DATE,
    Godzina2 TIME(7),
    LiczbaKomentarzy TINYINT,
    Tresc NVARCHAR(250),
    id VARCHAR(5),
    NickID INT
);

-- Wstawianie danych z OpinieTuchom
INSERT INTO OpinieFossDan (Nick, Platforma, Ocena, Data1, Godzina2, LiczbaKomentarzy, Tresc, id, NickID)
SELECT Nick, Platforma, Ocena, Data1, Godzina2, LiczbaKomentarzy, Tresc, id, NickID
FROM OpinieTuchom;

-- Wstawianie danych z OpinieGrodzisk
INSERT INTO OpinieFossDan (Nick, Platforma, Ocena, Data1, Godzina2, LiczbaKomentarzy, Tresc, id, NickID)
SELECT Nick, Platforma, Ocena, Data1, Godzina2, LiczbaKomentarzy, Tresc, id, NickID
FROM OpinieGrodzisk;

-- Dodanie klucza obcego dla NickID
ALTER TABLE OpinieFossDan
ADD CONSTRAINT FK_OpinieFossDan_NickID FOREIGN KEY (NickID) REFERENCES Uzytkownicy(ID);



-- ---------------------------------------------------------------------------------------
-- ---------------------------------------------------------------------------------------
-- ---------------------------------------------------------------------------------------
-- --------------------------------------- KPI's-------------------------------------------
-- ---------------------------------------------------------------------------------------
-- ---------------------------------------------------------------------------------------
-- ---------------------------------------------------------------------------------------



-- Aktualna srednia ocen dla tabeli OpinieFossDan i OpinieGrodzisk, OpinieTuchom 

CREATE VIEW SrednieOceny AS
SELECT 
    ROUND((SELECT AVG(Ocena) FROM OpinieFossDan), 2) AS [Aktualna srednia ocen FossDan],
    ROUND((SELECT AVG(Ocena) FROM OpinieGrodzisk), 2) AS [Aktualna srednia ocen Grodzisk],
    ROUND((SELECT AVG(Ocena) FROM OpinieTuchom), 2) AS [Aktualna srednia ocen Tuchom];

-- Aktualna liczba ocen dla tabeli OpinieFossDan i OpinieGrodzisk, i OpinieTuchoma

CREATE VIEW LiczbaOcen AS
SELECT 
    (SELECT COUNT(*) FROM OpinieFossDan WHERE Ocena IS NOT NULL) AS [Aktualna liczba ocen FossDan],
    (SELECT COUNT(*) FROM OpinieGrodzisk WHERE Ocena IS NOT NULL) AS [Aktualna liczba ocen Grodzisk],
    (SELECT COUNT(*) FROM OpinieTuchom WHERE Ocena IS NOT NULL) AS [Aktualna liczba ocen Tuchom];

-- Procentowy udział poszczególnych ocen dla tabeli OpinieFossDan

SELECT 
    CAST(Ocena AS INT) AS Ocena_zaokraglona,    
    COUNT(*) AS LiczbaOcen,
    (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM OpinieFossDan WHERE Ocena IS NOT NULL)) AS ProcentowyUdzial
FROM OpinieFossDan
WHERE Ocena IS NOT NULL
GROUP BY CAST(Ocena AS INT)   
ORDER BY Ocena_zaokraglona;  

-- Najbardziej aktywny użytkownik dla tabeli OpinieFossDan

SELECT TOP 1 
    OpinieFossDan.NickID,  
    Uzytkownicy.Nick,      
    COUNT(*) AS LiczbaKomentarzy
FROM OpinieFossDan
JOIN Uzytkownicy ON OpinieFossDan.NickID = Uzytkownicy.ID
GROUP BY OpinieFossDan.NickID, Uzytkownicy.Nick
ORDER BY LiczbaKomentarzy DESC;

-- TOP 5 negatywnych komentarzy z najniższą oceną  dla tabeli OpinieFossDan +widok kolumny z komentarzem "Do wyjasnienia"

SELECT TOP 5
    OpinieFossDan.NickID,      
    OpinieFossDan.Ocena,       
    OpinieFossDan.Tresc,      
    'Do wyjaśnienia' AS Komentarz 
FROM OpinieFossDan
WHERE OpinieFossDan.Ocena IS NOT NULL   
  AND OpinieFossDan.Tresc IS NOT NULL   
ORDER BY OpinieFossDan.Ocena ASC;  

-- TOP 5 pozytywnych komentarzy z najwyższą oceną dla tabeli OpinieFossDan


SELECT TOP 5
    OpinieFossDan.NickID,            
    OpinieFossDan.Ocena,           
    OpinieFossDan.Tresc,             
    'Do wyjaśnienia' AS Komentarz   
FROM OpinieFossDan
WHERE OpinieFossDan.Ocena IS NOT NULL
ORDER BY OpinieFossDan.Ocena DESC;      

-- Widok z ostatnimi 5 komentarzami dla tabeli OpinieFossDan

CREATE VIEW OstatnieKomentarze AS
SELECT TOP 5
NickID,
Nick,
Ocena,
Data1,
Godzina2,
Tresc
FROM OpinieFossDan
ORDER BY Data1 DESC, Godzina2 DESC;


-- Najwyższa ocena dla każdego miesiąca

SELECT 
    YEAR(Data1) AS Rok,
    MONTH(Data1) AS Miesiac,
    MAX(Ocena) AS NajwyzszaOcena,
    ROUND(AVG(Ocena), 1) AS SredniaOcenaNaMiesiac
FROM OpinieFossDan
WHERE Ocena IS NOT NULL
GROUP BY YEAR(Data1), MONTH(Data1)
ORDER BY Rok, Miesiac;

-- Liczba komentarzy na poszczegolnych platformach

SELECT 
    Platforma,
    COUNT(*) AS LiczbaKomentarzy
FROM OpinieFossDan
GROUP BY Platforma;

