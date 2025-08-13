COPY customers FROM 'D:\PRACTICE\Boutique Hotel\data\customers.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ',',
        ENCODING 'UTF-8'
    );

COPY orders FROM 'D:\PRACTICE\Boutique Hotel\data\orders.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ',',
        ENCODING 'UTF-8'
    );

COPY rooms FROM 'D:\PRACTICE\Boutique Hotel\data\rooms.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ',',
        ENCODING 'UTF-8'
    );
-- These queries copies thae data from the csv files to the already created tables
