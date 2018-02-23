use SmartDash

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--create Procedure [dbo].[Tab_SP_GetSODOGIBill_Dashboard] 
alter Procedure [dbo].[Tab_SP_GetSODOGIBill_Dashboard] 

as Begin

SET NOCOUNT ON

declare @current_year_int int = datepart(YY,getdate())

declare @current_month_int int = datepart(mm,getdate())

declare @current_month_text varchar(20) = 
case @current_month_int
		when '01' then 'January'
		when '02' then 'February'
		when '03' then 'March'
		when '04' then 'April'
		when '05' then 'May'
		when '06' then 'June'
		when '07' then 'July'
		when '08' then 'August'
		when '09' then 'September'
		when '10' then 'October'
		when '11' then 'November'
		when '12' then 'December'
end

create table #ThisMonthTarget
(
	BranchID varchar(50),
	BranchName  varchar(150),
	PrincipalShortName varchar(150),
	SubChannelName varchar(150),
	SalesTarget float
)

exec
(
'insert into #ThisMonthTarget 
	select
		BranchId,
		BranchName,
		case PrincipalShortName
			when ''ACE FOOD'' then ''ACEFOOD''
			else PrincipalShortName
		end as PrincipalShortName,
		case SubChannelName
			when ''GT-LD'' then ''LD''
			else SubChannelName
		end as SubChannelName,
		'+ @current_month_text + ' as SalesTarget
	from 
		smartdash.dbo.Hadrian_SalesTarget
	where
		BranchID <>''999''
		and [Year] = ' + @current_year_int
)

create table #source
(
	SalesOrder varchar(150),
	SOItem varchar(150),
	SODocDate date,
	RejectDesc varchar(150),
	OrderType varchar(150),
	SalOffCode varchar(150),
	SalOffName varchar(150),
	ChannelSO varchar(150),
	RealChannel varchar(150),
	DivDesc varchar(150),
	RealPrincipal varchar(150),
	SOAmount float,
	DOAmount float,
	GIAmt float,
	BillAmount float
)

insert into #source
	select 
		SalesOrder,
		SOItem,
		SODocDate,
		RejectDesc,
		OrderType,
		SalOffCode,
		SalOffName,
		ChannelSO,
		case ChannelSO 
			when 'GT' then
				case
					when (CustCategory = 'A1') then 'FS-Branch' 
					when (CustCategory = 'A5') then 'MT-Branch' --SDN - LMT
					when (CustCategory = 'A9') then 'MT-Branch' --SDN - LMT Strategic
					when (CustCategory = 'A2') and (SalOffName = 'Jakarta 2') then 'LD' --SDN - LD
					else 'GT-Branch'
				end
			when 'FS' then 'FSBC'
			when 'LD' then 'LD'
			when 'MT' then 'MT'
			when 'IT' then
				case
					when (SoldToPartyName = 'Dinamika Makmur Sentosa, PT.') then 'GT-Branch' 
					when (SalOffName = 'Jakarta 2') and (ShipToPartyName like '%Mitra Abadijaya%') and (DivDesc = 'Branded') then 'LD'
					when (SalOffName = 'Jakarta 2') and (DivDesc like '%Branded%') then 'IT'
					when (SoldToPartyName like 'Trijaya Niaga') then 'IT'
					else 'FSBC'
				end
		end as RealChannel,
		DivDesc,
		case
			when (DivDesc = 'SAPPE') and (MaterialDesc like '%GOO.N%') then 'SAPPE-GOON'
			when (DivDesc = 'PECU') and (MaterialDesc like '%Cocoday%') then 'PECU-COCODAY'
			else DivDesc
		end as RealPrincipal,
		SOAmount,
		DOAmount,
		GIAmt,
		BillAmount
	from 
		smartdash.dbo.tab_sapsalesdetail
	where
		0=0
		and month(SODocDate) = @current_month_int
		and OrderType not in ('ZDSA', 'ZDR1', 'ZDR5')
		and 
			(
			RejectDesc is null 
			or RejectDesc in ('Stock kosong', 'Assigned by the system (Internal)')
			)

create table #SOCompiled
(
	SalesOrder varchar(150),
	SOItem varchar(150),
	OrderType varchar(150),
	SalOffCode varchar(150),
	SalOffName varchar(150),
	RealChannel varchar(150),
	RealPrincipal varchar(150),
	SO float,
	DO float,
	GI float,
	Bill float
)

insert into #SOCompiled
	select
		SalesOrder,
		SOItem,
		OrderType,
		SalOffCode,
		SalOffName,
		RealChannel,
		RealPrincipal,
		avg(SOAmount) as SO,
		sum(DOAmount) as DO,
		sum(GIAmt) as GI,
		sum(BillAmount) as Bill 
	from 
		#source
	group by
		SalesOrder,
		SOItem,
		OrderType,
		SalOffCode,
		SalOffName,
		RealChannel,
		RealPrincipal

create table #value
(
	SalOffCode varchar(150),
	SalOffName varchar(150),
	Channel varchar(150),
	Principal varchar(150),
	SO float,
	DO float,
	GI float,
	Bill float
)

insert into #value	
	select 
		SalOffCode,
		SalOffName,
		RealChannel as Channel,
		RealPrincipal as Principal,
		sum(SO) as SO,
		sum(DO) as DO,
		sum(GI) as GI,
		sum(Bill) as Bill
	from
		#SOCompiled
	group by
		SalOffCode,
		SalOffName,
		RealChannel,
		RealPrincipal

/*	
select
	sum(SalesTarget) as TotalSalesTarget,
	sum(SO) as TotalSO,
	sum(DO) as TotalDO,
	sum(GI) as TotalGI,
	sum(Bill) as TotalBill
from
	#value V
	full outer join #ThisMonthTarget
		on (V.SalOffCode = BranchID) 
			and (V.Principal = PrincipalShortName) 
			and (Channel = SubChannelName)
	inner join smartdash.dbo.Hadrian_BMMapping BMM
		on BMM.Principal = isnull(V.Principal, PrincipalShortName)
	inner join smartdash.dbo.Hadrian_SalOffMapping SOM
		on SOM.SalOffCode = isnull(V.SalOffCode, BranchID) 
*/

truncate table smartdash.dbo.Tab_SODOGIBill_Dashboard
insert into smartdash.dbo.Tab_SODOGIBill_Dashboard
	select
		(select cast(max(SOCreation) as date) from smartdash.dbo.Tab_SAPSalesDetail) as DataDate, 
		isnull(V.SalOffCode, BranchID) as SalOffCode,
		isnull(V.SalOffName, BranchName) as SalOffName,
		isnull(Channel, SubChannelName) as Channel,
		PrincipalCategory,
		isnull(V.Principal, PrincipalShortName) as Principal,
		BusinessManager,
		case
			when isnull(Channel, SubChannelName) in ('FSBC', 'MT') then '-'
			else RMAreaName
		end as RMAreaName,
		case
			when isnull(Channel, SubChannelName) in ('FSBC', 'MT') then '-'
			else RMName
		end as RMName,
		BranchManager,
		isnull(SalesTarget,0) as SalesTarget,
		isnull(SO,0) as SO,
		isnull(DO,0) as DO,
		isnull(GI,0) as GI,
		isnull(Bill,0) as Bill
	from 
		#value V
		full outer join #ThisMonthTarget
			on (V.SalOffCode = BranchID) 
				and (V.Principal = PrincipalShortName) 
				and (Channel = SubChannelName)
		left join smartdash.dbo.Hadrian_BMMapping BMM
			on BMM.Principal = isnull(V.Principal, PrincipalShortName)
		inner join smartdash.dbo.Hadrian_SalOffMapping SOM
			on SOM.SalOffCode = isnull(V.SalOffCode, BranchID) 
	order by
		2,3,4,5

/*
drop table smartdash.dbo.tab_SODOGIBill_Dashboard
use SMARTDash
create table Tab_SODOGIBill_Dashboard
( 
	DataDate date,
	SalOffCode varchar(150),
	SalOffName varchar(150),
	Channel varchar(150),
	PrincipalCategory varchar(150),
	Principal varchar(150),
	BusinessManager varchar(150),
	RBMArea varchar(150),
	RBMName varchar(150),
	BranchManager varchar(150),
	SalesTarget float,
	SO float,
	DO float,
	GI float,
	Bill float
)
*/

-- select * from smartdash.dbo.tab_sodogibill_dashboard

drop table #ThisMonthTarget
drop table #source
drop table #SOCompiled
drop table #value

SET NOCOUNT OFF

End