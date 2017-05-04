%Macro Compare_CSV_JSON(API_File);

%Let API_File = &API_File;

*--- Read CSV File ---;
%Include "H:\StV\Open Banking\SAS\Source\Test Harness\Read Local CSV V0.2.sas";
*--- Read JSON File ---;
%Include "H:\StV\Open Banking\SAS\Source\Test Harness\Read Local JSON V0.2.sas";

*--- Move file to Archive Directory ---;

%Mend Compare_CSV_JSON;
*%Compare_CSV_JSON(API-USER);
%Compare_CSV_JSON(API-PROVIDER);
