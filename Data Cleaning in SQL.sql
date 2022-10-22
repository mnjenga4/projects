-- STEP-BY-STEP DATA CLEANING PROCESS IN SQL
SELECT *
FROM [master].[dbo].[Nashville Housing Data for Data Cleaning]

----------------------------------------------------------------------------------------------------------------------------------------------------

/*Format DateTime column to only display Date. Because our SaleDate column already only has the date showing, which is what we want, we will not execute 
this query. Instead we will just type the query out to display how one would go about carrying out this process in regards to tidying their data. */
--SELECT SaleDate, CONVERT (Date, SaleDate)
--FROM [master].[dbo].[Nashville Housing Data for Data Cleaning]

----------------------------------------------------------------------------------------------------------------------------------------------------

-- POPULATE PROPERTY ADDRESSES THAT ARE MISSING/NULL VALUES
SELECT PropertyAddress
FROM [master].[dbo].[Nashville Housing Data for Data Cleaning]
WHERE PropertyAddress IS NULL

SELECT *
FROM [master].[dbo].[Nashville Housing Data for Data Cleaning]
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

/*Looking at rows 44 & 45, along with rows 64 & 65, we can see that the ParcelIDs for each row are the exact same, and the PropertyAddress for each row 
are the exact same aswell. Knowing this, we can use the ParcelID as a reference point, and populate the null PropertyAddress values since it can be 
inferred that the ParcelID and the Property Address match. To do this, we will have to execute a self-join, and join the table to itself in order to
match ParcelIDs to PropertyAddresses. We will also self-join the table on the account that the unique ID's do NOT match one another, as a way to
distinguish between repeating ParcelIDs */

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress
FROM [master].[dbo].[Nashville Housing Data for Data Cleaning] A
JOIN [master].[dbo].[Nashville Housing Data for Data Cleaning] B
    ON A.ParcelID = B.ParcelID
    AND A.UniqueID <> B.UniqueID
WHERE A.PropertyAddress IS NULL

/*Executing the above query, we can see where the ParcelIDs are the exact same, but there are missing PropertyAddresses from the original table (A). This
display is perfect because we can now see where we need to populate with the correct PropertyAddresses, and by ensuring that the UniqueIDs are not equal
to one another, we know that we are not seeing the same rows repeated. Now let's modify the query above to fill in the missing PropertyAddress values */

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress,B.PropertyAddress)
FROM [master].[dbo].[Nashville Housing Data for Data Cleaning] A
JOIN [master].[dbo].[Nashville Housing Data for Data Cleaning] B
    ON A.ParcelID = B.ParcelID
    AND A.UniqueID <> B.UniqueID
WHERE A.PropertyAddress IS NULL

-- Update our original table (A), to fill in the missing values for PropertyAddress

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress,B.PropertyAddress)
FROM [master].[dbo].[Nashville Housing Data for Data Cleaning] A
JOIN [master].[dbo].[Nashville Housing Data for Data Cleaning] B
    ON A.ParcelID = B.ParcelID
    AND A.UniqueID <> B.UniqueID
WHERE A.PropertyAddress IS NULL

/*Perfect! After executing the above query, and re-running the query in line(s) 41-46, we can see that our original table has populated all the
missing PropertyAddress values with the correct Addresses based off of both ParcelID & UniqueID. The ISNULL function allowed for us to replace
any null values in A.PropertyAddress with the correct matching value from B.PropertyAddress. */

----------------------------------------------------------------------------------------------------------------------------------------------------

-- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (Address, City, State)
SELECT PropertyAddress
FROM [master].[dbo].[Nashville Housing Data for Data Cleaning]

SELECT
SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address
FROM [master].[dbo].[Nashville Housing Data for Data Cleaning]

-- the (-1) allows for the removal of the comma from the output. Now let's copy & modify the above query to create a new column for the city for each address.
SELECT
SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address
, SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address
FROM [master].[dbo].[Nashville Housing Data for Data Cleaning]

-- Add two new columns to input the data for the City & State
ALTER TABLE [master].[dbo].[Nashville Housing Data for Data Cleaning]
ADD PropertySplitAddress NVARCHAR(255)

UPDATE [master].[dbo].[Nashville Housing Data for Data Cleaning]
SET PropertySplitAddress = SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)


ALTER TABLE [master].[dbo].[Nashville Housing Data for Data Cleaning]
ADD PropertySplitCity NVARCHAR(255)

UPDATE [master].[dbo].[Nashville Housing Data for Data Cleaning]
SET PropertySplitCity = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

/* Great! For extra practice now, let's look at the OwnerAddress column which contains the Address, City, AND state, and let's now repeat what we have done
above, but utilizing a MUCH simpler method. We will use the function PARSENAME as opposed to the SUBSTRING function to separate our results. */

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)
FROM [master].[dbo].[Nashville Housing Data for Data Cleaning]

-- Now add the columns and values to the table.
ALTER TABLE [master].[dbo].[Nashville Housing Data for Data Cleaning]
ADD OwnerSplitAddress NVARCHAR(255)

UPDATE [master].[dbo].[Nashville Housing Data for Data Cleaning]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)

ALTER TABLE [master].[dbo].[Nashville Housing Data for Data Cleaning]
ADD OwnerSplitCity NVARCHAR(255)

UPDATE [master].[dbo].[Nashville Housing Data for Data Cleaning]
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)

ALTER TABLE [master].[dbo].[Nashville Housing Data for Data Cleaning]
ADD OwnerSplitState NVARCHAR(255)

UPDATE [master].[dbo].[Nashville Housing Data for Data Cleaning]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)

----------------------------------------------------------------------------------------------------------------------------------------------------

-- CHANGE Y & N TO YES AND NO IN "SOLD AS VACANT" FIELD
SELECT DISTINCT(CAST(SoldAsVacant AS NVARCHAR(5)))
FROM [master].[dbo].[Nashville Housing Data for Data Cleaning]



SELECT CAST(SoldAsVacant AS NVARCHAR(5))
,   CASE WHEN CAST(SoldAsVacant AS NVARCHAR(5)) = 'Y' THEN 'Yes'
         WHEN CAST(SoldAsVacant AS NVARCHAR(5)) = 'N' THEN 'No'
         ELSE CAST(SoldAsVacant AS NVARCHAR(5))
         END
FROM [master].[dbo].[Nashville Housing Data for Data Cleaning]

UPDATE [master].[dbo].[Nashville Housing Data for Data Cleaning]
SET SoldAsVacant = CASE WHEN CAST(SoldAsVacant AS NVARCHAR(5)) = 'Y' THEN 'Yes'
         WHEN CAST(SoldAsVacant AS NVARCHAR(5)) = 'N' THEN 'No'
         ELSE CAST(SoldAsVacant AS NVARCHAR(5))
         END

/* When uploading this dataset in Azure, I had set the "SoldAsVacant" field to have a data type of "text" because the the Yes/No values were being read as Boolean,
and I could not (at the time of uploading), figure out which data type was best to use as "Boolean" was not an option. Unfortunately, "text" data types
cannot be counted by the COUNT function because they are text/string variables and not numerical -- hence the reason why my code shows me casting the 
"SoldAsVacant" field as a "NVARCHAR" data type. Thankfully though, the above queries executed, and all variables indicated in the CASE WHEN statement 
above have been replaced. */

----------------------------------------------------------------------------------------------------------------------------------------------------

-- REMOVE DUPLICATES

WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY
                    UniqueID
                    ) row_num
FROM [master].[dbo].[Nashville Housing Data for Data Cleaning]
--ORDER BY ParcelID
)
DELETE 
FROM [RowNumCTE]
WHERE row_num > 1

/*It can be seen that there are 104 rows that are duplicated within the table. Now, by changing our function from SELECT to DELETE, we will eliminate 
these duplicates. After doing this, simply changing the DELETE function back to SELECT and running the query shows us that all 104 duplicate rows have
successfully been removed. */

----------------------------------------------------------------------------------------------------------------------------------------------------

-- DELETE UNUSUED COLUMNS

SELECT *
FROM [Nashville Housing Data for Data Cleaning]

ALTER TABLE [Nashville Housing Data for Data Cleaning]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress
