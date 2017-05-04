Options Symbolgen;

Libname Perm "H:\StV\Open Banking\SAS\Data\Perm";

%Macro ImportCSV(Dir,Filename);
PROC IMPORT OUT= WORK.&Filename 
            DATAFILE= "&Dir" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
%Mend ImportCSV;
%ImportCSV(C:\inetpub\wwwroot\OpenBanking\&API_File..csv,CSVFile);


%Macro TestAPI(Dsn);

%let dsid=%sysfunc(open(&dsn,i));
%put dsid= &dsid;
%let num=%sysfunc(attrn(&dsid,nvars));
%put num=&num;
%let varlist=;

%do i=1 %to &num;

	%Let vartype= %SYSFUNC(VARTYPE(&dsid,&i));
	%Put vartype= &vartype;

	%If "&Vartype" EQ "C" %Then
	%Do;
	    %Let Varlist&i= %SYSFUNC(varname(&dsid,&i));
		%Put Varlist&i= &&varlist&i;
    	%Let varnum = %SYSFUNC(varnum(&dsid,&&Varlist&i));
		%Put varnum = &varnum;


		%let mydataid=%sysfunc(open(&Dsn,i));
		%let rc=%sysfunc(fetchobs(&mydataid,1));
		%let Value&i=%qsysfunc(getvarC(&mydataid,%sysfunc(varnum(&mydataid,&&Varlist&i))));
		%put Value&i=%str(&&Value&i);
		%let rc=%sysfunc(close(&mydataid));

	%End;
	%Else %Do;
	    %Let Varlist&i= %SYSFUNC(varname(&dsid,&i));
		%Put Varlist&i= &&varlist&i;
    	%Let varnum = %SYSFUNC(varnum(&dsid,&&Varlist&i));
		%Put varnum = &varnum;


		%let mydataid=%sysfunc(open(&Dsn,i));
		%let rc=%sysfunc(fetchobs(&mydataid,1));
		%let Value&i=%sysfunc(Trim(%sysfunc(Left(%sysfunc(getvarN(&mydataid,%sysfunc(varnum(&mydataid,&&Varlist&i))))))));
		%put Value&i=%str(&&Value&i);
		%let rc=%sysfunc(close(&mydataid));
	%End;
%End;

	Data Work.Test2(Rename=(Variable = Data_Element Value = Value_CSV));
		Length RowCnt 8. Variable $ 100 Value $ 1000;
		%Do j = 1 %to &num;
			RowCnt = &j;
			Variable = "&&Varlist&j";
			Value = "&&Value&j";
			Output;	
		%End;
	Run;

	Proc Sort Data = Work.Test2
		Out = Perm.CSV_File(Keep=RowCnt Data_Element Value_CSV);
		By RowCnt Data_Element;
	Run;

%Mend TestAPI;
%TestAPI(CSVFile);


