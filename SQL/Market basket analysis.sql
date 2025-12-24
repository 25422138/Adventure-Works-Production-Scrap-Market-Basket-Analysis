-- Step 1: Drop and create #OrderCategoryTemp
IF OBJECT_ID('tempdb..#OrderCategoryTemp') IS NOT NULL
    DROP TABLE #OrderCategoryTemp;
CREATE TABLE #OrderCategoryTemp (
    SalesOrderID INT,
    FY INT,
    FQ INT,
    ProductCategory VARCHAR(50),
    OnlineOrderFlag BIT
);

-- Insert base order-category data using Sales schema
INSERT INTO #OrderCategoryTemp
SELECT
    soh.SalesOrderID,
    CASE 
        WHEN MONTH(soh.OrderDate) >= 7 THEN YEAR(soh.OrderDate) + 1 
        ELSE YEAR(soh.OrderDate) 
    END AS FY,
    CASE 
        WHEN MONTH(soh.OrderDate) IN (7,8,9) THEN 1
        WHEN MONTH(soh.OrderDate) IN (10,11,12) THEN 2
        WHEN MONTH(soh.OrderDate) IN (1,2,3) THEN 3
        ELSE 4 
    END AS FQ,
    pc.Name AS ProductCategory,
    soh.OnlineOrderFlag
FROM
    Sales.SalesOrderHeader soh -- Use Sales schema
INNER JOIN Sales.SalesOrderDetail sod 
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc 
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc 
    ON psc.ProductCategoryID = pc.ProductCategoryID
    AND pc.Name IN ('Bikes', 'Accessories', 'Clothing', 'Components')
WHERE
    soh.OrderDate BETWEEN '2011-07-01' AND '2014-06-30';


-- Step 2: Drop and create #DistinctOrderMixTemp
IF OBJECT_ID('tempdb..#DistinctOrderMixTemp') IS NOT NULL
    DROP TABLE #DistinctOrderMixTemp;
CREATE TABLE #DistinctOrderMixTemp (
    SalesOrderID INT,
    FY INT,
    FQ INT,
    Bikes INT,
    Accessories INT,
    Clothing INT,
    Components INT,
    OnlineOrderFlag BIT
);

-- Insert aggregated category flags (0/1)
INSERT INTO #DistinctOrderMixTemp
SELECT
    SalesOrderID,
    FY,
    FQ,
    MAX(CASE WHEN ProductCategory = 'Bikes' THEN 1 ELSE 0 END) AS Bikes,
    MAX(CASE WHEN ProductCategory = 'Accessories' THEN 1 ELSE 0 END) AS Accessories,
    MAX(CASE WHEN ProductCategory = 'Clothing' THEN 1 ELSE 0 END) AS Clothing,
    MAX(CASE WHEN ProductCategory = 'Components' THEN 1 ELSE 0 END) AS Components,
    OnlineOrderFlag
FROM
    #OrderCategoryTemp
GROUP BY
    SalesOrderID, FY, FQ, OnlineOrderFlag;


-- Step 3: Generate final report
SELECT
    FY,
    FQ,
    Bikes,
    Accessories,
    Clothing,
    Components,
    COUNT(DISTINCT CASE WHEN OnlineOrderFlag = 0 THEN SalesOrderID END) AS OfflineOrders,
    COUNT(DISTINCT CASE WHEN OnlineOrderFlag = 1 THEN SalesOrderID END) AS OnlineOrders
FROM
    #DistinctOrderMixTemp
GROUP BY
    FY, FQ, Bikes, Accessories, Clothing, Components
ORDER BY
    FY, FQ;


-- Clean up temporary tables
DROP TABLE #OrderCategoryTemp;
DROP TABLE #DistinctOrderMixTemp;