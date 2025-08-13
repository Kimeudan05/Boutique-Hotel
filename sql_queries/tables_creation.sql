CREATE TABLE customers (
    CustomerID BIGINT PRIMARY KEY,
    CustomerAge BIGINT,
    CustomerGender TEXT,
    CustomerCountry TEXT
);

CREATE TABLE rooms (
    RoomNumber BIGINT PRIMARY KEY,
    Capacity BIGINT,
    RoomType TEXT,
    BasePrice BIGINT
);

CREATE TABLE orders (
    OrderID BIGINT PRIMARY KEY,
    CustomerIDs TEXT,  -- You may want to normalize this later
    CustomerCount BIGINT,
    RoomNumber BIGINT REFERENCES rooms(RoomNumber),
    CheckInDate DATE,
    CheckOutDate DATE,
    StayDuration BIGINT,
    TotalCost NUMERIC,
    PaymentMethod TEXT,
    SeasonalFactor TEXT
);

