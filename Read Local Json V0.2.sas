*--- Set X path variable to the default directory ---;
X "cd H:\StV\Open Banking\SAS\Data\Perm";

*--- Set the Library path where the permanent datasets will be saved ---;
Libname OpenData "H:\StV\Open Banking\SAS\Data\Perm";

*--- The Main macro will execute the code to extract data from the API end points ---;
%Macro Main(Url,JSON,File);
 
Filename API Temp;
/*Filename API "H:\STV\Open Banking\SAS\Temp";*/
 
*--- Proc HTTP assigns the GET method in the URL to access the data ---;
Proc HTTP
	Url = "&Url."
 	Method = "GET"
 	Out = API;
Run;
 
*--- The JSON engine will extract the data from the JSON script ---; 
Libname LibAPIs JSON Fileref=API;

*--- Proc datasets will create the datasets to examine resulting tables and structures ---;
Proc Datasets Lib = LibAPIs; 
Quit;

Data Work.&JSON._&File
	(Keep = RowCnt Count P Bank_API Var2 Var3 P1 - P7 Value 
	Rename=(Var3 = Data_Element Var2 = Hierarchy Value = &JSON));

	Length Bank_API $ 8 Var2 Value1 Value2 $ 1000 Var3 $ 100 P1 - P7 Value $ 1000;

	RowCnt = _N_;

*--- The variable V contains the first level of the Hierarchy which has no Bank information ---;
	Set LibAPIs.Alldata(Where=(V NE 0));
*--- Create Array concatenate variables P1 to P7 which will create the Hierarchy ---;
	Array Cat{7} P1 - P7;

*--- The Do-Loop will create the Hierarchy of Level 1 to 7 (P1 - P7) ---;
	Do i = 1 to P;
		If i = 1 Then 
		Do;
*--- If it is the first data field then do ---;
			Var2 = (Left(Trim(Cat{i})));
			Count = i;
		End;
*--- All subsequent data fields are concatenated to form the Hierarchy variable as in the reports ---;
		Else Do;
			Var2 = Compress(Var2||'-'||Cat{i});
			Count = i;
		End;
		Retain Var2;
	End;

	*--- Create variable to list the API value i.e. ATM or Branches ---;
	Bank_API = "&File";

*--- Extract only the last level of the Hierarchy ---;
	Var3 = Reverse(Scan(Left(Trim(Reverse(Var2))),1,'-',' '));

	If Var2 NE '' Then
	Do;
		Var3 = Var2;
	End;

	If "&JSON" EQ 'Bank_of_Ireland' and "&File" EQ 'CCC' Then
	Do;
		Value1 = Tranwrd(CompBl(Value),"-"," ");
		Value2 = Tranwrd(Value1,":"," ");
		Value = Value2;
		Test = 1; 
	End;

Run;

*--- Sort data by Data_Element ---;
Proc Sort Data = Work.&JSON._&File
	Out = Perm.&JSON._&File(Keep = RowCnt Data_Element Json Rename=(Json = Value_json));
 By RowCnt Data_Element;
Run;

/*Proc Print Data = Work.&Bank._&API;*/
/**	Where V NE 0;*/
/*Run;*/

%Mend Main;
%Main(http://localhost/OpenBanking/&API_File..json,Json,file);



Data Perm.Compare_CSV_JSON(Drop = RowCnt) 
	Perm.Notin_JSON
	Perm.Notin_CSV 
	Perm.MisMatch_CSV_JSON(Drop = RowCnt);

	Length RowCnt 8. Data_Element $ 100 Value_CSV $ 1000 Value_JSON $ 1000;

	Merge Perm.CSV_File(In=a)
	Perm.Json_File(In=b);

	By RowCnt Data_Element;

	If a and not b then Output Perm.Notin_Json;
	If b and not a then Output Perm.Notin_CSV;
	If a and b then Output Perm.Compare_CSV_JSON;
	If Left(Trim(Value_json)) ~= Left(Trim(Value_csv)) then Output Perm.Mismatch_CSV_JSON;

Run;

*--- Set Title Date in Proc Print ---;
%Macro Fdate(Fmt,Fmt2);
   %Global Fdate FdateTime;
   Data _Null_;
      Call Symput("Fdate",Left(Put("&Sysdate"d,&Fmt)));
      Call Symput("FdateTime",Left(Put("&Sysdate"d,&Fmt2)));
  Run;
%Mend Fdate;
%Fdate(worddate12., datetime.);

*--- Run Macro to Print the CMA9 Reports for ATMS, BRANCHES, PCA, etc ---;
%Macro CMA9_Reports(Dsn, Dsn2);
*--- Set Output Delivery Parameters  ---;
ODS _All_ Close;
ODS HTML Body="&Dsn._Body_%sysfunc(datetime(),B8601DT15.).html" 
	Contents="&Dsn._Contents.html" 
	Frame="&Dsn._Frame.html" 
	Style=HTMLBlue;
ODS Graphics On;

*--- Print ATMS Report ---;
Proc Print Data = Perm.&Dsn;
Title1 "Open Banking - QAT";
Title2 "&Dsn Report - &Fdate";
Run;

*--- Print ATMS Report ---;
Proc Print Data = Perm.&Dsn2;
Title1 "Open Banking - QAT";
Title2 "&Dsn2 Report - &Fdate";
Run;

*--- Creat a dummy dataset with 2 blank lines in the which will seperate the reports in the CSV file ---;
Data Work.Dummy;
	Length Data_Element $ 100 Value_CSV $ 1000 Value_JSON $ 1000;
	Data_Element = '';
	Value_CSV = '';
	Value_JSON = '';
*--- Output first blank line ---;
	Output;

	Data_Element = '';
	Value_CSV = '';
	Value_JSON = '';
*--- Output second blank line ---;
	Output;
Run;

Data Perm.Combine_Report_CSV_JSON;
	Length Data_Element $ 100 Value_CSV $ 1000 Value_JSON $ 1000;
	Set Perm.&Dsn 
	Work.Dummy
	Perm.&Dsn2;
Run;
/*
PROC EXPORT DATA = Perm.Combine_Report_CSV_JSON
            OUTFILE= "H:\StV\Open Banking\SAS\Data\Perm\Combine_CSV_JSON_Report_%sysfunc(datetime(),B8601DT15.).csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;
*/

/*
Filename mymail email "Surinder.Lall@openbanking.org.uk"
   subject="CSV - JSON Comparison report"
   attach="H:\StV\Open Banking\SAS\Data\Perm\Compare_CSV_JSON_Body.html";

data _null_;
   file mymail;
   put 'Surinder,';
   put 'This is CSV / JSON Comparison Report for &Fdate.';
   put 'Thanks';
   put 'QAT';
run;
*/
*--- Close Output Delivery Parameters  ---;
ODS HTML Close;
ODS Listing;

%Mend CMA9_Reports;
%CMA9_Reports(Compare_CSV_JSON, Mismatch_CSV_JSON);

Options Noxwait;
X "cd C:\inetpub\wwwroot\OpenBanking";
X "move C:\inetpub\wwwroot\OpenBanking\*.*
	C:\inetpub\wwwroot\OpenBanking\Archive";

X "exit";

*--- Delete Work Library Datasets ---;
Proc Datasets Lib=Work Nolist Kill;
	Quit;
Run;

/*
&API_File._%sysfunc(datetime(),B8601DT15.).csv
&API_File._%sysfunc(datetime(),B8601DT15.).json
