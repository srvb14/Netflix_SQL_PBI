use netflix;
table netflix_data;

# Data Cleaning:
-----------------|
-- checking missing values for critical columns :
select 
count(*) - count(id) as missing_id ,
count(*) - count(title) as missing_title,
count(*) - count(type) as missing_type ,
count(*) - count(description) as missing_desc,
count(*) - count(release_year) as missing_release_year,
count(*) - count(age_certification) as missing_age_cert,
count(*) - count(runtime) as missing_runtime,
count(*) - count(imdb_id) as missing_imdb_id,
count(*) - count(imdb_score) as missing_imdb_score,
count(*) - count(imdb_votes) as missing_imdb_votes
from netflix_data;
-- missing description = 3, missing_age_certification = 2285, missing_imdb_votes = 16

-- check for duplicate id:
select id, count(*) 
from netflix_data group by id
having count(*) >1;
-- no duplicates found


-- creating a view of cleean_script:

create view	netflix_clean as
with cte as (
select distinct * from netflix_data),

cte2 as(
select id, 
trim(title) as title,
trim(type) as type,
coalesce(trim(description),'Not Available') as description,
release_year,
case when age_certification is NULL or age_certification = '' 
	then 'Unrated' else age_certification end as age_certification,
runtime, 
imdb_id,
imdb_score,
coalesce(imdb_votes, 0) as imdb_votes
from cte 
where runtime >0),

cte3 as (
select *,
floor(release_year/10)*10 as decade,
case
	when imdb_score >=8.0  then 'High'
    when imdb_score >=5.0 then 'Average'
    else 'Low' end as imdb_category
from cte2)
select * from cte3;
table netflix_clean;


-- Task 1: 
-- Content Breakdown: Count total titles by type (Movie/Show) and age certification. Which demographic is Netflix targeting most.
select Type, age_certification , count(*) as total_titles 
from netflix_clean
group by Type, age_certification
order by type , count(*) desc;
/* While 'Unrated' is the largest technical category due to data gaps, the explicit strategic focus for Movies is the
R-rated audience, and for TV Shows, it is the TV-MA audience (Mature Adults)*/


select Type, age_certification , count(*) as total_titles ,
round(count(*)*100.0/ sum(count(*)) over (partition by type),2) as pct_of_type
from netflix_clean where age_certification ='Unrated'
group by Type, age_certification
order by type , count(*) desc;


select Type, age_certification , count(*) as total_titles ,
round(count(*)*100.0/ sum(count(*)) over (partition by type),2) as pct_of_type
from netflix_clean where age_certification !='Unrated'
group by Type, age_certification
order by type , pct_of_type desc;


-- Task 2:
-- High Performing Content: Filter titles with imdb_score >8.0 and imdb_votes>10000.
with cte as(
select title, type, decade, imdb_score, imdb_votes
from netflix_clean
where imdb_score > 8.0 and imdb_votes > 10000
)

select type, decade, 
count(*) as high_performing_count ,
round(avg(imdb_score),2) as avg_score
from cte 
group by type, decade
order by high_performing_count desc , avg_score desc;

/* Even though netflix has more movies than TV shows but TV shows are more likely to achieve high performance status.
this likely highlight the binge effect , shows provide more hours of engagements than movies leading to more fan loyalty 
and higher imdb votes compared to one time movie viewing.
2010 is the golden decade for netflix.
*/

select 
	(select count(*) from netflix_clean where imdb_score > 8.0 and imdb_votes > 10000)*100.0/
    (select count(*) from netflix_clean) as pct_contribution;
-- only 3.41% of movies+shows are high performer in netflix



-- Task 3: Historical Quality Trends: 
-- Calculate the average imdb_score per year for Movies vs. TV Shows.
-- Has the average quality increased or decreased as the volume grew?

select type, release_year,
round(avg(imdb_score),2) as avg_imdb, count(*) as volume
from netflix_clean where release_year>2010
group by type, release_year
order by type, release_year;



-- Task 4: Runtime Analysis
-- Group movies into "Short" (<90 min), "Standard" (90–120 min), and "Long" (>120 min) and compare their average
-- ratings.
with cte as(
select *,
case
	when runtime <90 then 'Short'
    when runtime between 90 and 120 then 'Standard'
    else 'Long' end as runtime_status
from netflix_clean where type ='Movie'
)
select runtime_status, count(*) as total, avg(runtime) as avg_runtime,
 round(avg(imdb_score),2) as imdb_score
from cte group by runtime_status;

select runtime,
count(*) as total,
round(avg(imdb_score),2) as imdb_score
from netflix_clean where type = 'Movie'
group by runtime order by runtime desc, imdb_score desc; 

/* 
we can see that when the runtime increase avg imdb_score also increase, most likely because viewers like to watch 
long movies,
*/



-- Task 5: Identifying "Hidden Gems":
-- Find titles with high scores (>8.5) but low vote counts (indicates cult classics or niche high-quality content).
select title ,type, 
imdb_score, imdb_votes, release_year
from netflix_clean
where imdb_score > 8.5
and 
imdb_votes between 1000 and 10000
order by imdb_votes asc;

/*
enough people have watched those and have good response in terms of imdb rating but not gone viral, 
most of them are shows .
*/








