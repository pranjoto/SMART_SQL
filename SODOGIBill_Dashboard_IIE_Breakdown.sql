use SmartDash

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--create Procedure [dbo].[Tab_SP_GetSODOGIBill_Dashboard_IIE_Breakdown] 
alter Procedure [dbo].[Tab_SP_GetSODOGIBill_Dashboard_IIE_Breakdown] 

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

create table #value
(
	OrderType varchar(150),
	SalesOrder varchar(150),
	SOItem varchar(150),
	DivDesc varchar(150),
	RSMDesc varchar(150),
	SOAmount float,
	DOAmount float,
	GIAmount float,
	BillAmount float
)

insert into #value
	select 
		OrderType,
		SalesOrder,
		SOItem,
		case
			when (DivDesc = 'SAPPE') and (MaterialDesc like '%GOO.N%') then 'SAPPE-GOON'
			when (DivDesc = 'PECU') and (MaterialDesc like '%Cocoday%') then 'PECU-COCODAY'
			else DivDesc
		end as DivDesc,
		case RSMDesc
			when 'RSM 3' then 'RSM East'
			else RSMDesc
		end as RSMDesc,
		avg(SOAmount) as SOAmount,
		sum(DOAmount) as DOAmount,
		sum(GIAmt) as GIAmount,
		sum(BillAmount) as BillAmount
	from 
		smartdash.dbo.tab_sapsalesdetail
	where
		0=0
		and month(SODocDate) = @current_month_int 
		and ChannelSO = 'IT' 
		and SalOffName = 'Jakarta 2'
		and DivDesc like '%Branded%'  
		and SoldToPartyName not like '%Mitra Abadijaya%'
		and OrderType not in ('ZDSA', 'ZDR1', 'ZDR5')
		and 
			(
			RejectDesc is null 
			or RejectDesc in ('Stock kosong', 'Assigned by the system (Internal)')
			)
	group by
		OrderType,
		SalesOrder,
		SOItem,
			case
			when (DivDesc = 'SAPPE') and (MaterialDesc like '%GOO.N%') then 'SAPPE-GOON'
			when (DivDesc = 'PECU') and (MaterialDesc like '%Cocoday%') then 'PECU-COCODAY'
			else DivDesc
		end,
		RSMDesc
exec
(
'
truncate table smartdash.dbo.Tab_SODOGIBill_Dashboard_IIE_Breakdown
insert into smartdash.dbo.Tab_SODOGIBill_Dashboard_IIE_Breakdown
	select
		(select cast(max(SOCreation) as date) from smartdash.dbo.tab_sapsalesdetail) as DataDate, 
		isnull(DivDesc,Principal) as Principal, 
		isnull(RSMDesc, IIE_Area) as RSMDesc,
		' + @current_month_text + ' as SalesTarget,
		sum(SOAmount) as SO,
		sum(DOAmount) as DO,
		sum(GIAmount) as GI,
		sum(BillAmount) as Bill
	from 
		#value
		full outer join smartdash.dbo.Hadrian_salestarget_IIE
		on (DivDesc = 	case Principal when ''ACE FOOD'' then ''ACEFOOD'' else Principal end) 
		and (RSMDesc = IIE_Area)
	where
		[Year] = '+ @current_year_int +' 
	group by
		isnull(DivDesc,Principal), 
		isnull(RSMDesc, IIE_Area),
		' + @current_month_text +''
)

drop table #value

/*
use SMARTDash
drop table Tab_SODOGIBill_Dashboard_IIE_Breakdown
create table Tab_SODOGIBill_Dashboard_IIE_Breakdown
(
	DataDate date,
	Principal varchar(150), 
	RSMDesc varchar(150),
	SalesTarget float,
	SO float,
	DO float,
	GI float,
	Bill float
)

select * from smartdash.dbo.Tab_SODOGIBill_Dashboard_IIE_Breakdown
*/

SET NOCOUNT OFF

End