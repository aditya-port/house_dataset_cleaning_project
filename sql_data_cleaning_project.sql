/*
cleaning nashville housing data - postgresql version
*/

------------------------------------------------
-- look at the data

select * 
from nashville_housing_data
limit 1000;

select count(*) 
from nashville_housing_data;


------------------------------------------------
-- fill missing propertyaddress using parcelid match

-- check how many null propertyaddress
select count(*) 
from nashville_housing_data
where propertyaddress is null;


-- update propertyaddress by matching parcelid with another row
update nashville_housing_data a
set propertyaddress = b.propertyaddress
from nashville_housing_data b
where a.parcelid = b.parcelid
and a.uniqueid <> b.uniqueid
and a.propertyaddress is null
and b.propertyaddress is not null;


------------------------------------------------
-- split propertyaddress into address and city

-- add new columns
alter table nashville_housing_data
add column short_address varchar(255),
add column property_city varchar(255);


-- update short_address (before comma)
update nashville_housing_data
set short_address = trim(split_part(propertyaddress, ',', 1));


-- update property_city (after comma)
update nashville_housing_data
set property_city = trim(split_part(propertyaddress, ',', 2));


-- check
select propertyaddress, short_address, property_city
from nashville_housing_data;


------------------------------------------------
-- split owneraddress into address, city, state

alter table nashville_housing_data
add column owner_address_short varchar(255),
add column owner_city varchar(255),
add column owner_state varchar(255);


update nashville_housing_data
set owner_address_short = trim(split_part(owneraddress, ',', 1)),
    owner_city = trim(split_part(owneraddress, ',', 2)),
    owner_state = trim(split_part(owneraddress, ',', 3));


-- check
select owneraddress, owner_address_short, owner_city, owner_state
from nashville_housing_data;


------------------------------------------------
-- change y and n to yes and no in soldasvacant

select distinct soldasvacant
from nashville_housing_data;


update nashville_housing_data
set soldasvacant = case
    when soldasvacant = 'Y' then 'Yes'
    when soldasvacant = 'N' then 'No'
    else soldasvacant
end;


-- check
select distinct soldasvacant
from nashville_housing_data;


------------------------------------------------
-- check if saleprice has null

select *
from nashville_housing_data
where saleprice is null;


------------------------------------------------
-- remove duplicates and create clean view

create or replace view clean_nashville_data as
select *
from (
    select *,
           row_number() over (
               partition by
                   parcelid,
                   landuse,
                   propertyaddress,
                   saledate,
                   saleprice,
                   legalreference,
                   soldasvacant,
                   ownername,
                   owneraddress,
                   acreage,
                   taxdistrict,
                   landvalue,
                   buildingvalue,
                   totalvalue,
                   yearbuilt,
                   bedrooms,
                   fullbath,
                   halfbath
               order by uniqueid
           ) as rn
    from nashville_housing_data
) t
where rn = 1;


------------------------------------------------
-- final cleaned data

select *
from clean_nashville_data;