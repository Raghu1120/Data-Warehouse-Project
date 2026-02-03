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
    -- Bulk inserting the crm files
    TRUNCATE TABLE bronze.crm_cust_info;



    BULK INSERT bronze.crm_cust_info
    FROM '/datasets/source_crm/cust_info.csv'
    WITH (
        FIRSTROW  = 2, -- Inserting from Second row
        FIELDTERMINATOR = ',', -- Differenciates Columns
        TABLOCK

    );


    TRUNCATE TABLE bronze.crm_sales_details;

    BULK INSERT bronze.crm_sales_details
    FROM '/datasets/source_crm/sales_details.csv'
    WITH (
        FIRSTROW  = 2,
        FIELDTERMINATOR = ',',
        TABLOCK

    );



    TRUNCATE TABLE bronze.crm_prd_info;

    BULK INSERT bronze.crm_prd_info
    FROM '/datasets/source_crm/prd_info.csv'
    WITH (
        FIRSTROW  = 2,
        FIELDTERMINATOR = ',',
        TABLOCK

    );

    --Bulk inserting the erp files


    TRUNCATE TABLE bronze.erp_cust_az12;

    BULK INSERT bronze.erp_cust_az12
    FROM '/datasets/source_erp/CUST_AZ12.csv'
    WITH (
        FIRSTROW  = 2,
        FIELDTERMINATOR = ',',
        TABLOCK

    );


    TRUNCATE TABLE bronze.erp_loc_a101

    BULK INSERT bronze.erp_loc_a101
    FROM '/datasets/source_erp/LOC_A101.csv'
    WITH (
        FIRSTROW  = 2,
        FIELDTERMINATOR = ',',
        TABLOCK

    );



    TRUNCATE TABLE bronze.erp_px_cat_g1v2

    BULK INSERT bronze.erp_px_cat_g1v2
    FROM '/datasets/source_erp/PX_CAT_G1V2.csv'
    WITH (
        FIRSTROW  = 2,
        FIELDTERMINATOR = ',',
        TABLOCK

    );
END

EXEC bronze.load_bronze -- executing the stored procedure
