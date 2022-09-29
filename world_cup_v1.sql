--previewing data 

SELECT 
  MIN(date) , MAX(date) -- checking date range of data
FROM
  World_Cup..world_cup;

SELECT *
FROM World_Cup..world_cup




---------------------- Find which continent has the most wins in World Cup matches-----------------------------------------------

-- created temporary table to store all the wins per continent while they were the away team
IF EXISTS(SELECT *
          FROM    World_Cup..continent_away_wins)
  DROP TABLE  World_Cup..continent_away_wins

CREATE TABLE World_Cup..continent_away_wins AS
SELECT away_team_continent AScontinent, 
  SUM(CASE away_team_result WHEN 'Win' THEN 1 ELSE 0 END) AS total_wins 
FROM World_Cup..world_cup
WHERE 
  tournament = 'FIFA World Cup '
GROUP BY 
  continent;

-- created temporary table to store all the wins per continent while they were the home team
CREATE TABLE
 `fifa-world-cup-case-study.World_CUP.continent_home_wins` AS
SELECT 
  home_team_continent as continent,  SUM(CASE home_team_result WHEN 'Win' THEN 1 ELSE 0 END) AS total_wins 
FROM 
  World_Cup..world_cup
WHERE 
  tournament = 'FIFA World Cup'
GROUP BY continent;
  
-- joining home and away wins tables to compare total wins per continent
SELECT 
  away_wins.continent , away_wins.total_wins + home_wins.total_wins AS total_wins -- added home and away wins into total wins column
FROM
  `fifa-world-cup-case-study.World_CUP.away_wins` as away_wins
JOIN
  `fifa-world-cup-case-study.World_CUP.home_wins` as home_wins
ON
  home_wins.continent = away_wins.continent ; -- Europe has the most game wins in world cups from 1993-2022
  


-------------------------------Best team at World Cups---------------------------------------------------------------------

-- created temporary table to store all the wins per team while they were the home team
CREATE TABLE `fifa-world-cup-case-study.World_CUP.team_wins_home` AS
SELECT
   home_team, COUNT(home_team_result) as total_wins
FROM 
  World_Cup..world_cup
WHERE home_team_result = 'Win' AND tournament = 'FIFA World Cup'
GROUP BY home_team 
ORDER BY total_wins DESC;

-- created temporary table to store all the wins per continent while they were the away team
CREATE TABLE `fifa-world-cup-case-study.World_CUP.team_wins_away` AS
SELECT
   away_team, COUNT(away_team_result) as total_wins
FROM 
  World_Cup..world_cup
WHERE away_team_result = 'Win' AND tournament = 'FIFA World Cup'
GROUP BY away_team 
ORDER BY total_wins DESC;

-- joining home and away wins tables to compare total wins per team
SELECT 
  home_team, team_wins_away.total_wins + team_wins_home.total_wins as total_wins
FROM 
  `fifa-world-cup-case-study.World_CUP.team_wins_away` AS team_wins_away
JOIN
`fifa-world-cup-case-study.World_CUP.team_wins_home` AS team_wins_home
ON
  home_team = away_team
ORDER BY total_wins DESC;  -- Brazil has the most game wins (32 wins) in world cups from 1993-2022 with Germany (29 wins) as close 2nd place 


------------------------------Does the better team always win?--------------------------------------------
SELECT 
  COUNT(CASE WHEN who_won = "Better Team Won" THEN 1 END) AS better_team_won,
  COUNT(CASE WHEN who_won = "Worse Team Won" THEN 1 END) AS worse_team_won,
  COUNT(CASE WHEN who_won = "Better Team Won" THEN 1  END) / COUNT(who_won) AS avg_better_team_won,
  COUNT(CASE WHEN who_won = "Worse Team Won" THEN 1  END) / COUNT(who_won) AS avg_worse_team_won
FROM
(SELECT 
  home_team, away_team, home_team_result, away_team_result, home_team_fifa_rank, away_team_fifa_rank,
  CASE
    WHEN home_team_result = 'Win' AND home_team_fifa_rank < away_team_fifa_rank THEN 'Better Team Won'
    WHEN home_team_result = 'Win' AND home_team_fifa_rank > away_team_fifa_rank THEN 'Worse Team Won'
    WHEN away_team_result = 'Win' AND away_team_fifa_rank < home_team_fifa_rank THEN 'Better Team Won'
    WHEN away_team_result = 'Win' AND away_team_fifa_rank > home_team_fifa_rank THEN 'Worse Team Won'
    ELSE 'Draw'
  END as who_won
FROM
  World_Cup..world_cup
WHERE tournament = 'FIFA World Cup' ); ----- the better team on average wins 56% world cup matches (ranks determined by fifa team score)

----------------------------------------------------------------------------------------------------------------------------------------------


----Created temp table to dijvide matches in between winners and losers instead of home team and awau team
CREATE TABLE `fifa-world-cup-case-study.World_CUP.winner_and_losers_data` AS
SELECT date, CONCAT(home_team, ' vs ' , away_team) AS matches,
CASE
  WHEN home_team_result = 'Win' THEN home_team
  WHEN home_team_result = 'Lose' THEN away_team
  ELSE 'Draw'
END AS match_winner,
CASE
  WHEN home_team_result = 'Lose' THEN home_team
  WHEN home_team_result = 'Win' THEN away_team
  ELSE 'Draw'
END AS match_loser,
CASE
  WHEN home_team_result = 'Win' THEN home_team_mean_offense_score
  WHEN home_team_result = 'Lose' THEN away_team_mean_offense_score
END AS mean_offense_score_of_winner,
CASE
  WHEN home_team_result = 'Lose' THEN home_team_mean_offense_score
  WHEN home_team_result = 'Win' THEN away_team_mean_offense_score
  ELSE NULL
END AS mean_offense_score_of_loser,
CASE
  WHEN home_team_result = 'Win' THEN home_team_mean_defense_score
  WHEN home_team_result = 'Lose' THEN away_team_mean_defense_score
END AS mean_defense_score_of_winner,
CASE
  WHEN home_team_result = 'Lose' THEN home_team_mean_defense_score
  WHEN home_team_result = 'Win' THEN away_team_mean_defense_score
  ELSE NULL
END AS mean_defense_score_of_loser,
FROM 
  World_Cup..world_cup
WHERE  home_team_mean_offense_score IS NOT NULL AND away_team_mean_offense_score IS NOT NULL AND home_team_result <> 'Draw'

ORDER BY date ;


--------------Does the team with the best offense or the best defence win more games?----------------------------
SELECT
  
   COUNT(CASE 
     WHEN  mean_offense_score_of_winner > mean_defense_score_of_winner THEN 1 ELSE NULL END ) / COUNT(matches) AS  better_offense_won ,
     
  COUNT(CASE WHEN  mean_defense_score_of_winner > mean_offense_score_of_winner THEN 1 ELSE NULL END )/ COUNT(matches) AS better_defense_won
FROM
  `fifa-world-cup-case-study.World_CUP.winner_and_losers_data` ;
  ------------ The team with the better offence wins about 64% of the time while the team with the better defence only wins about 30% of the time 
  -----(the remaining 6% are games that ended in a draw)


