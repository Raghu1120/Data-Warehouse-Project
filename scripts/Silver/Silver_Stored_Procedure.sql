/*
===============================================================================
Stored Procedure: Load silver Layer (Bronze ->Silver)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'silver' schema from Bronze layer. 
    It performs the following actions:
    - Truncates the Silver tables before loading data.
    - Uses the `INSERT` command to load data from bronze tables into silver tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/


CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN
DECLARE @start_time DATETIME, @end_time DATETIME,@start_batch_time DATETIME,@end_batch_time DATETIME
    BEGIN TRY
    --1
    SET @start_batch_time = GETDATE()
    PRINT '===========================';
    PRINT 'LOADING SILVER LAYER';
    PRINT '===========================';

    PRINT '---------------------------';
    PRINT 'LOADING CRM TABLES';
    PRINT '---------------------------';

    SET @start_time = GETDATE()

    PRINT '>>Truncating Table : silver.crm_cust_info ';
    TRUNCATE TABLE silver.crm_cust_info;
    PRINT 'Inserting Data into : silver.crm_cust_info';
    INSERT INTO silver.crm_cust_info(
        cst_id,
        cst_key, 
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date)

    SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname, -- Removing spaces
    TRIM(cst_lastname) AS cst_lastname,
    CASE 
    WHEN UPPER(TRIM(cst_gndr))= 'F' THEN 'FEMALE' -- Normalize gender values to readable format
    WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE'
    ELSE 'N/A' END AS cst_gndr,
    CASE 
    WHEN UPPER(TRIM(cst_marital_status))= 'S' THEN 'SINGLE' -- Normalize marital status values to readable format
    WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'MARRIED'
    ELSE 'N/A' END -- Unknown rather than null
    cst_marital_status,
    cst_create_date
    FROM(
        SELECT 
        *,
        ROW_NUMBER () OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
        FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
    )t WHERE flag_last = 1;

    SET @end_time = GETDATE();
    PRINT 'Load Duration :' + CAST(DATEDIFF(Second,@start_time,@end_time) AS NVARCHAR) +'Seconds';

    -- SELECT * FROM silver.crm_cust_info


    --2
    SET @start_time = GETDATE()

    PRINT '>>Truncating Table : silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info;
    PRINT 'Inserting Data into : silver.crm_prd_info';
    INSERT INTO silver.crm_prd_info(
        prd_id       ,
        categeory_id ,
        prd_key     ,
        prd_nm       ,
        prd_cost   ,
        prd_line  ,
        prd_start_dt ,
        prd_end_dt 
    )
    SELECT 
        prd_id,
        REPLACE(SUBSTRING(prd_key,1,5),'-','_' )AS categeory_id, -- Extract categeory id
        SUBSTRING(prd_key,7,len(prd_key)) AS prd_key, -- xtract product key
        prd_nm,
        ISNULL(prd_cost,0) AS prd_cost,
        CASE UPPER(TRIM(prd_line)) -- Map product line codes to descriptive values
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'N/A' END AS prd_line,
        
        CAST(prd_start_dt AS DATE) AS prd_start_dt,
        CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt -- Calculate end date as one day before the next start date
    FROM bronze.crm_prd_info;

    SET @end_time = GETDATE();
    PRINT 'Load Duration :' + CAST(DATEDIFF(Second,@start_time,@end_time) AS NVARCHAR) +'Seconds';



    --3

    SET @start_time = GETDATE()

    PRINT '>>Truncating Table : silver.crm_sales_details ';
    TRUNCATE TABLE silver.crm_sales_details;
    PRINT 'Inserting Data into : silver.crm_sales_details';

    INSERT INTO silver.crm_sales_details(
        sls_ord_num ,
        sls_prd_key  ,
        sls_cust_id  ,
        sls_order_dt ,
        sls_ship_dt  ,
        sls_due_dt   ,
        sls_sales    ,
        sls_quantity ,
        sls_price    
        
    )
    SELECT 
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR )AS DATE) END AS sls_order_dt,

        CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR )AS DATE) END AS sls_ship_dt,

        CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR )AS DATE) END AS sls_due_dt,

        CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price) ELSE sls_sales END AS sls_sales,

        sls_quantity,

        CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN
        sls_sales /NULLIF(sls_quantity ,0) 
        ELSE sls_price END AS sls_price
    FROM DataWarehouse.bronze.crm_sales_details;

    SET @end_time = GETDATE();
    PRINT 'Load Duration :' + CAST(DATEDIFF(Second,@start_time,@end_time) AS NVARCHAR) +'Seconds';

    PRINT '---------------------------';
    PRINT 'LOADING ERP TABLES';
    PRINT '---------------------------';

    --4
    SET @start_time = GETDATE()

    PRINT '>>Truncating Table : silver.erp_cust_az12 ';
    TRUNCATE TABLE silver.erp_cust_az12;
    PRINT 'Inserting Data into : silver.erp_cust_az12';

    INSERT INTO silver.erp_cust_az12(
        cid,bdate,gen
    )
    SELECT 
    CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) -- Remove 'NAS' prefix if present
    ELSE cid END AS cid ,
    CASE WHEN bdate > GETDATE() THEN NULL
    ELSE bdate END AS bdate, -- Set future birthdates to NULL

    CASE UPPER(
        NULLIF(
            TRIM(REPLACE(REPLACE(gen, CHAR(13), ''), CHAR(10), '')),
            ''
        )
        )
    WHEN 'F' THEN 'Female'
    WHEN 'FEMALE' THEN 'Female'
    WHEN 'M' THEN 'Male'
    WHEN 'MALE' THEN 'Male'
    ELSE 'N/A'
    END AS gen -- Normalize gender values and handle unknown cases
    FROM bronze.erp_cust_az12;

    SET @end_time = GETDATE();
    PRINT 'Load Duration :' + CAST(DATEDIFF(Second,@start_time,@end_time) AS NVARCHAR) +'Seconds';

    --5
    SET @start_time = GETDATE()

    PRINT '>>Truncating Table : silver.erp_loc_a101 ';
    TRUNCATE TABLE silver.erp_loc_a101;
    PRINT 'Inserting Data into :silver.erp_loc_a101 ';

    INSERT INTO silver.erp_loc_a101(
        cid,cntry
    )
    SELECT 
    REPLACE(cid,'-','') AS cid,
    CASE 
    WHEN UPPER(TRIM(REPLACE(REPLACE(cntry,CHAR(13),''),CHAR(10),''))) = 'DE' 
        THEN 'Germany'
    WHEN UPPER(TRIM(REPLACE(REPLACE(cntry,CHAR(13),''),CHAR(10),''))) IN ('US','USA') 
        THEN 'United States'
    WHEN NULLIF(TRIM(REPLACE(REPLACE(cntry,CHAR(13),''),CHAR(10),'')),'') IS NULL 
        THEN 'N/A'
    ELSE TRIM(REPLACE(REPLACE(cntry,CHAR(13),''),CHAR(10),''))
    END AS cntry
    FROM bronze.erp_loc_a101;

    SET @end_time = GETDATE();
    PRINT 'Load Duration :' + CAST(DATEDIFF(Second,@start_time,@end_time) AS NVARCHAR) +'Seconds';

    --6
    SET @start_time = GETDATE()


    PRINT '>>Truncating Table : silver.erp_px_cat_g1v2 ';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    PRINT 'Inserting Data into :silver.erp_px_cat_g1v2';

    INSERT INTO silver.erp_px_cat_g1v2(
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT 
    id,
    cat,
    subcat,
    CASE UPPER(TRIM(REPLACE(REPLACE(maintenance,CHAR(10),''),CHAR(13),'')))
    WHEN 'YES' THEN 'Yes'
    WHEN 'NO' THEN 'No'
    ELSE 'N/A'
    END AS maintenance
    FROM bronze.erp_px_cat_g1v2;


    SET @end_time = GETDATE();
    PRINT 'Load Duration :' + CAST(DATEDIFF(Second,@start_time,@end_time) AS NVARCHAR) +'Seconds';

    PRINT '=======================================';
    PRINT 'LOADING SILVER LAYER IS COMPLETED';
    PRINT '=======================================';

    SET @end_batch_time = GETDATE();
    PRINT '>>TOTAL LOAD DURATION :' + CAST(DATEDIFF(Second,@start_batch_time,@end_batch_time) AS NVARCHAR) + 'seconds';

    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
        PRINT 'Error Message' + CAST(ERROR_MESSAGE() AS NVARCHAR);
        PRINT 'Error Message' + CAST(ERROR_NUMBER() AS INT);
        PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END
