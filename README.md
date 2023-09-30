# project-engeto-data

Průvodní listina 
SQL projekt ke kurzu Engeto: Datová analýza 06/2023


Výzkumné otázky:

1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?


Odpovědi na základě analýzy dat v přiloženém SQL skriptu:

ad 1. Ve 14 z celkem 19 odvětví je alespoň 1 rok, kdy mzdy klesaly.

ad 2. První a poslední srovnatelné období je rok 2006 a 2018. V roce 2006 bylo možné si za průměrnou mzdu koupit maximálně 1 408 l mléka nebo 1261 kg chleba. V roce 2018 bylo možné si za průměrnou mzdu v tomto roce koupit 1 613 l mléka nebo 1 319 kg chleba.

ad 3. Nejpomaleji zdražuje cukr krystal, jehož cena v průběhu sledovaného období spíše klesala.

ad 4. Ve sledovaném období v letech 2006 až 2018 nebyl žádný rok, kde by růst cen potravin oproti růstu mezd byl vyšší než 10 %.

ad 5. Výraznější růst HDP, nad 5 %, v období 2006 až 2018 byl pouze ve 4 letech. Z toho ve 3 letech byl i výraznější růst cen potravin a průměrných mezd. Nicméně aby se dala určit nějaká větší závislost v datech, byla by vhodná delší časová řada a použití statistických metod jako analýza korelace apod.


Poznámka:
Analýzu dat ovlivňují chybějící data cen potravin, která jsou dostupná až pro roky 2006 až 2018, oproti tomu údaje o mzdách v jedn. odvětvích jsou dostupné v letech 2000 až 2021.
Pro posuzování výsledků analýzy u otázek na mzdy i potraviny dohromady, pracuji se společnou základnou let 2006 až 2018.