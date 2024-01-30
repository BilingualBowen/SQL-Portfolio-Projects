/*

Cleaning Data in SQL Queries

*/

select *
from PortfolioProject3.dbo.NashvilleHousing

---------------------------------------------------------------------------------------------
-- Statndardize Data Format

select SaleDate, CONVERT(date, SaleDate)
from PortfolioProject3.dbo.NashvilleHousing

--update PortfolioProject3.dbo.NashvilleHousing
--set SaleDate = CONVERT(date, SaleDate)

alter table PortfolioProject3.dbo.NashvilleHousing
add SaleDateConverted date

update PortfolioProject3.dbo.NashvilleHousing
set SaleDateConverted = CONVERT(date, SaleDate)

select SaleDate, SaleDateConverted
from PortfolioProject3.dbo.NashvilleHousing


---------------------------------------------------------------------------------------------
-- Populate Property Address Data

-- There are rows with null values in  column PropertyAddress
-- The solution is to find the ParcelID of the null valued PropertyAddress rows,
-- if there are rows with same ParcelID that has existing PropertyAddress,
-- then copy the existing PropertyAddress to those null rows.

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
from PortfolioProject3.dbo.NashvilleHousing a
join PortfolioProject3.dbo.NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

update a
set a.PropertyAddress = b.PropertyAddress
from PortfolioProject3.dbo.NashvilleHousing a
join PortfolioProject3.dbo.NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null


---------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)

-- 1. PropertyAddress
select PropertyAddress
from PortfolioProject3.dbo.NashvilleHousing

select SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as streetAddress,
	   SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as cityAddress
from PortfolioProject3.dbo.NashvilleHousing

alter table PortfolioProject3.dbo.NashvilleHousing
add PropertySplitAddress NVARCHAR(255),
	PropertySplitCity NVARCHAR(255)

-- ALTER TABLE PortfolioProject3.dbo.NashvilleHousing DROP COLUMN PropertySplitAddress, PropertySplitCity;

update PortfolioProject3.dbo.NashvilleHousing
set PropertySplitAddress = TRIM(SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)),
	PropertySplitCity = TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)))

-- 2. OwnerAddress
select OwnerAddress
from PortfolioProject3.dbo.NashvilleHousing

select
TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)),
TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)),
TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1))
from PortfolioProject3.dbo.NashvilleHousing

alter table PortfolioProject3.dbo.NashvilleHousing
add OwnerSplitAddress NVARCHAR(255),
	OwnerSplitCity NVARCHAR(255),
	OwnerSplitState NVARCHAR(255)

-- ALTER TABLE PortfolioProject3.dbo.NashvilleHousing DROP COLUMN OwnerSplitAddress, OwnerSplitCity, OwnerSplitState;

update PortfolioProject3.dbo.NashvilleHousing
set OwnerSplitAddress = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)),
	OwnerSplitCity = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)),
	OwnerSplitState = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1))


---------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

select SoldAsVacant, count(SoldAsVacant)
from PortfolioProject3.dbo.NashvilleHousing
group by SoldAsVacant


select SoldAsVacant,
	   case when SoldAsVacant = 'Y' then 'Yes'
			when SoldAsVacant = 'N' then 'No'
	   else SoldAsVacant
	   end
from PortfolioProject3.dbo.NashvilleHousing


update PortfolioProject3.dbo.NashvilleHousing
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
						when SoldAsVacant = 'N' then 'No'
				   else SoldAsVacant
				   end

---------------------------------------------------------------------------------------------
-- Remove Duplicates

with rowNumCTE as (
select *,
ROW_NUMBER() OVER(partition by 
					ParcelID, 
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
				  order by
					UniqueID) as row_num
from PortfolioProject3.dbo.NashvilleHousing
)
select * from rowNumCTE
where row_num > 1

-- When delete from cte, the original table it points to will get effected.
with rowNumCTE as (
select *,
ROW_NUMBER() OVER(partition by 
					ParcelID, 
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
				  order by
					UniqueID) as row_num
from PortfolioProject3.dbo.NashvilleHousing
)
delete from rowNumCTE
where row_num > 1


---------------------------------------------------------------------------------------------
-- Delete Unused Columns

alter table PortfolioProject3.dbo.NashvilleHousing
drop column OwnerAddress, PropertyAddress, SaleDate


-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

---- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO
