/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/




-- Creating a stored procedure so that everyday it can be executed for a full insert


CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
DECLARE @start_time DATETIME, @end_time DATETIME,@start_batch_time DATETIME,@end_batch_time DATETIME

    BEGIN TRY
    SET @start_batch_time = GETDATE();
    PRINT '===========================';
    PRINT 'LOADING BRONZE LAYER';
    PRINT '===========================';

    PRINT '---------------------------';
    PRINT 'LOADING CRM TABLES';
    PRINT '---------------------------';
    -- Bulk inserting the crm files

    SET @start_time = GETDATE();
    PRINT '>>Truncationg Table : bronze.crm_cust_info: ';
    TRUNCATE TABLE bronze.crm_cust_info;

    PRINT '>>Inserting into : bronze.crm_cust_info: ';
    BULK INSERT bronze.crm_cust_info
    FROM '/datasets/source_crm/cust_info.csv'
    WITH (
        FIRSTROW  = 2, -- Inserting from Second row
        FIELDTERMINATOR = ',', -- Differenciates Columns
        TABLOCK

    );
    SET @end_time = GETDATE();
    PRINT '>>LOAD DURTION : ' + CAST(DATEDIFF(Second,@start_time,@end_time)AS NVARCHAR) + 'seconds';
    PRINT '------------------';


    SET @start_time = GETDATE();
    PRINT '>>Truncationg Table : bronze.crm_sales_details ';
    TRUNCATE TABLE bronze.crm_sales_details;

    PRINT '>>Inserting into : bronze.crm_sales_details ';
    BULK INSERT bronze.crm_sales_details
    FROM '/datasets/source_crm/sales_details.csv'
    WITH (
        FIRSTROW  = 2,
        FIELDTERMINATOR = ',',
        TABLOCK

    );
    SET @end_time = GETDATE();
    PRINT 'LOAD DURATION :' + CAST(DATEDIFF(Second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------';

    SET @start_time = GETDATE();
    PRINT '>>Truncationg Table : bronze.crm_prd_info ';
    TRUNCATE TABLE bronze.crm_prd_info;

    PRINT '>>Inserting into : bronze.crm_prd_info ';
    BULK INSERT bronze.crm_prd_info
    FROM '/datasets/source_crm/prd_info.csv'
    WITH (
        FIRSTROW  = 2,
        FIELDTERMINATOR = ',',
        TABLOCK

    );
    SET @end_time = GETDATE();
    PRINT 'LOAD DURATION :' + CAST(DATEDIFF(Second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------';


    PRINT '---------------------------';
    PRINT 'LOADING ERP TABLES';
    PRINT '---------------------------';
    --Bulk inserting the erp files

    SET @start_time =GETDATE();
    PRINT '>>Truncationg Table : bronze.erp_cust_az12 ';
    TRUNCATE TABLE bronze.erp_cust_az12;

    PRINT '>>Inserting into : bronze.erp_cust_az12 ';
    BULK INSERT bronze.erp_cust_az12
    FROM '/datasets/source_erp/CUST_AZ12.csv'
    WITH (
        FIRSTROW  = 2,
        FIELDTERMINATOR = ',',
        TABLOCK

    );
    SET @end_time = GETDATE();
    PRINT 'LOAD DURATION :' + CAST(DATEDIFF(Second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------';

    SET @start_time =GETDATE();
    PRINT '>>Truncationg Table : bronze.erp_loc_a101 ';
    TRUNCATE TABLE bronze.erp_loc_a101

    PRINT '>>Inserting into : bronze.erp_loc_a101 ';
    BULK INSERT bronze.erp_loc_a101
    FROM '/datasets/source_erp/LOC_A101.csv'
    WITH (
        FIRSTROW  = 2,
        FIELDTERMINATOR = ',',
        TABLOCK

    );
    SET @end_time = GETDATE();
    PRINT 'LOAD DURATION :' + CAST(DATEDIFF(Second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------';

    SET @start_time =GETDATE();
    PRINT '>>Truncationg Table : bronze.erp_px_cat_g1v2 ';
    TRUNCATE TABLE bronze.erp_px_cat_g1v2

    PRINT '>>Inserting into : bronze.erp_px_cat_g1v2 ';
    BULK INSERT bronze.erp_px_cat_g1v2
    FROM '/datasets/source_erp/PX_CAT_G1V2.csv'
    WITH (
        FIRSTROW  = 2,
        FIELDTERMINATOR = ',',
        TABLOCK

    );
    SET @end_time = GETDATE();
    PRINT '=======================================';
    PRINT 'LOADING BRONZE LAYER IS COMPLETED'
    PRINT 'LOAD DURATION :' + CAST(DATEDIFF(Second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '=======================================';

    SET @end_batch_time = GETDATE();
    PRINT '>>TOTAL LOAD DURATION :' + CAST(DATEDIFF(Second,@start_batch_time,@end_batch_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------';
    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message' + CAST(ERROR_MESSAGE() AS NVARCHAR);
        PRINT 'Error Message' + CAST(ERROR_NUMBER() AS INT);
        PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END

EXEC bronze.load_bronze -- executing the stored procedure

