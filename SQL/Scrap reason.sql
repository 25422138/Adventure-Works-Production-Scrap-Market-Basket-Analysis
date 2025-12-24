-- Step1: Count the number of WorkOrder corresponding to each ScrapReason for each product
WITH CTE1 AS
    (SELECT p.ProductID,
            p.Name AS ProductName,
            s.Name AS ScrapReason,
            COUNT(w.WorkOrderID) AS WorkOrderCount
    from Production.Product AS p
    JOIN Production.WorkOrder AS w
    ON p.ProductID = w.ProductID
    JOIN Production.ScrapReason AS s
    ON w.ScrapReasonID = s.ScrapReasonID
    GROUP BY p.ProductID,p.Name, s.Name),
-- Step2: Descending order by 'Step1: WorkOrderCount' for each product of ScrapReason
CTE2 AS 
    (SELECT ProductID,
            ProductName,
            ScrapReason,
            WorkOrderCount,
            ROW_NUMBER() OVER(PARTITION by ProductID order by WorkOrderCount desc) AS ReasonRank
    from CTE1)

-- Step3: Filter most common ScrapReason for each product
SELECT  ProductID,
        ProductName,
        WorkOrderCount,
        ScrapReason
FROM CTE2
WHERE ReasonRank = 1
ORDER BY ProductID