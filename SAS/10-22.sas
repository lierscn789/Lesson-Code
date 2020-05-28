libname sas 'C:/Users/yecha/Downloads/Compressed';
run;

data youngadult;
set sas.customer_dim;
where Customer_Age between 18 and 36 and Customer_Gender = 'F'
and Customer_Group contains 'Gold';
keep Customer_Name Customer_Age Customer_BirthDate 
Customer_Gender Customer_Group;
run;


proc contents data=youngadult;
run;


proc print data=youngadult;
run;

data work.sports;
   set sas.product_dim;
   where Supplier_Country in ('GB','ES','NL') and 
         Product_Category like '%Sports';
   drop Product_ID Product_Line Product_Group Supplier_ID;
   label Product_Category='Sports Category' 
   Product_Name='Product Name (Abbrev)'
   Supplier_Name='Supplier Name (Abbrev)';
format Product_Name $15.;
format Supplier_Name $15.;
run;
proc print data=work.sports (OBS=10) label;
run;

PROC CONTENTS DATA=work.sports;
RUN;
