function Invoke-SQLSearch {
$conn = New-Object System.Data.SQLClient.SQLConnection
$conn.ConnectionString = "Server=DESKTOP-1E81M77,1433; database = test; Integrated Security = False;User Id=sa;Password=Password123123"
$conn.Open()
$QueryTimeout = 120
$ConnectionTimeout = 30

$Query = " 
IF OBJECT_ID('tempdb..#dbTable') IS NOT NULL DROP TABLE #dbTable
IF OBJECT_ID('tempdb..#FieldSearchTable') IS NOT NULL DROP TABLE #FieldSearchTable
 
create table #dbTable
(
   ServerName nvarchar(max),
   DatabaseName nvarchar(max),
   TableName nvarchar(max),
   dbTableSchema nvarchar(max),
   ColumnName nvarchar(max),
   SearchTerm nvarchar(max)
)
 
create table #FieldSearchTable
(
    Processed int,
    FieldName nvarchar(max)
)
 
insert into #FieldSearchTable (Processed, FieldName) values (0, 'firstname')
insert into #FieldSearchTable (Processed, FieldName) values (0, 'password')
insert into #FieldSearchTable (Processed, FieldName) values (0, 'ssn')

EXEC sp_msforeachDB 'USE [?]
 
declare @name nvarchar(max)
 
    set @name = db_name()

    while (select top 1 Processed from #FieldSearchTable where Processed = 0) = 0
    begin
            declare @fieldname nvarchar(max)
            set @fieldname = (select top 1 FieldName  from #FieldSearchTable where Processed = 0)
 
            --search text find in DB sql search sql table search sql
            Declare @text NVARCHAR(1024)
                    set @text = @fieldname
            -- columns
 
            insert  #dbTable (ServerName, DatabaseName, TableName, dbTableSchema, ColumnName, SearchTerm)
            SELECT @@SERVERNAME,
                           ''['' + @name  + '']'' ,        
                           ''['' + c.TABLE_NAME  + '']'' ,
                           ''['' + c.TABLE_SCHEMA  + '']'' ,
                           ''['' + c.COLUMN_NAME   + '']'' ,
                           @fieldname as tableName
                           FROM  INFORMATION_SCHEMA.TABLES  t
                                    inner join INFORMATION_SCHEMA.COLUMNS c
                                        on t.TABLE_CATALOG  = c.TABLE_CATALOG
                                               and t.TABLE_SCHEMA = c.TABLE_SCHEMA
                                               and t.TABLE_NAME = c.TABLE_NAME
                                               and t.TABLE_TYPE <> ''view''
 
                           WHERE charindex(@text collate database_default , c.COLUMN_NAME collate database_default)>0
                           and @name  not in (''tempdb'', ''model'', ''master'',  ''msdb'' )
 
            update #FieldSearchTable set processed = 1 where FieldName COLLATE SQL_Latin1_General_CP1_CI_AS = @fieldname COLLATE SQL_Latin1_General_CP1_CI_AS
 
    end     
    update #FieldSearchTable set processed = 0    
'
 
select 'servername: ' + ServerName + ' location ' + DatabaseName + '.' + dbTableSchema + '.' +  TableName + ' Column: ' + ColumnName + ' searchterm: ' + SearchTerm from #dbTable
"


$cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn)
$cmd.CommandTimeout=$QueryTimeout
$ds=New-Object system.Data.DataSet
$da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
[void]$da.fill($ds)
$conn.Close()
$ds.Tables

}


