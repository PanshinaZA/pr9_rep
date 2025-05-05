CREATE EXTENSION cube;
CREATE EXTENSION earthdistance;

--Создаем временную таблицу с координатами долготы и широты для каждого клиента
CREATE TEMP TABLE customer_points AS (
SELECT
customer_id,
point(longitude, latitude) AS lng_lat_point
FROM customers
WHERE longitude IS NOT NULL
AND latitude IS NOT NULL
);
SELECT * FROM customer_points; --проверка данных

--Создаем аналогичную таблицу для дилерских центров
CREATE TEMP TABLE dealership_points AS (
SELECT
dealership_id,
point(longitude, latitude) AS lng_lat_point
FROM dealerships
);
SELECT * FROM dealership_points;

-- Объединим таблицы, чтобы получить расстояние между клиентами и центрами
CREATE TEMP TABLE customer_dealership_distance_km AS (
    SELECT
        customer_id,
        dealership_id,
        (c.lng_lat_point <@> d.lng_lat_point) * 1.609344 AS distance_km
    FROM customer_points c
    CROSS JOIN dealership_points d
);
SELECT * FROM customer_dealership_distance_km;

--  Определим ближайший дилерский центр 
CREATE TEMP TABLE closest_dealerships AS (
SELECT DISTINCT ON (customer_id)
customer_id,
dealership_id,
distance_km
FROM customer_dealership_distance_km
ORDER BY customer_id, distance_km
);
SELECT * FROM closest_dealerships;

-- Рассчитаем среднее расстояние от каждого клиента до его ближайшего дилерского центра:
SELECT
AVG(distance_km) AS avg_dist,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY distance_km) AS
median_dist
FROM closest_dealerships;

-- Удаление временных таблиц
DROP TABLE IF EXISTS customer_points;
DROP TABLE IF EXISTS dealership_points;
DROP TABLE IF EXISTS customer_dealership_distance_km;
DROP TABLE IF EXISTS closest_dealerships;