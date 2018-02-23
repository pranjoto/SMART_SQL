-- MTD SODOGIBill LD Breakdown

use SmartDash


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--create Procedure [dbo].[Tab_SP_GetSODOGIBill_Dashboard_LD_Breakdown] 
alter Procedure [dbo].[Tab_SP_GetSODOGIBill_Dashboard_LD_Breakdown] 

as Begin

SET NOCOUNT ON


declare @current_year_int int = datepart(yy,getdate())

declare @current_month_int int = datepart(mm,getdate())

-- for TargetHeader
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


create table #LDSalesTarget
(
	Principal varchar(150),
	RMAreaCode  varchar(150),
	RMAreaName varchar(150),
	SoldToPartyName varchar(150),
	RMName varchar(150),
	ASMName varchar(150),
	Area varchar(150),
	Provinsi varchar(150),
	Kab varchar(150),
	SalesTarget float
)

exec
(
'insert into #LDSalesTarget
	select
		case Principal
			when ''ACE FOOD'' then ''ACEFOOD''
			else Principal
		end as Principal,
		RMAreaCode,
		RMAreaName,
		case 
			when SoldToPartyName like ''%Herby Pangemanan%'' then ''HERBY PANGEMANAN''
			when SoldToPartyName like ''%Maktal Jaya%'' then ''MAKTAL JAYA, CV''
			when SoldToPartyName like ''%Anugerah 5 Sempurna%'' then ''ANUGERAH 5 SEMPURNA, PT''
			when SoldToPartyName like ''%Anugerah Bina Usaha Nusantara%'' then ''PT. ANUGERAH BINA USAHA NUSANTARA''
			when SoldToPartyName like ''%Karya Prima CV%'' then ''CV. KARYA PRIMA''
			when SoldToPartyName like ''%WIJAYA, UD / WIDJAJA HERMAN%'' then ''WIDJAJA HERMAN''
			when SoldToPartyName like ''%CV. AGUNG RAYA LESTARI%'' then ''AGUNG RAYA LESTARI, CV''
			when SoldToPartyName like ''%CV. BORNEO CIPTA MANDIRI%'' then ''BORNEO CIPTA MANDIRI, CV''
			when SoldToPartyName like ''%SURYA UNGGUL SENTOSA CV%'' then ''SURYA UNGGUL SENTOSA, CV''
			when SoldToPartyName like ''%ANUGRAH JAYA PERKASA%'' then ''ANUGRAH JAYA PERKASA, CV''
			else SoldToPartyName 
		end as SoldToPartyName,
		RMName,
		ASMName,
		Area,
		Provinsi,
		Kab,
		sum('+ @current_month_text + ') as SalesTarget
	from 
		smartdash.dbo.Hadrian_SalesTarget_LD
	where
		[Year] = '+ @current_year_int +'
	group by
		Principal,
		RMAreaCode,
		RMAreaName,
		case 
			when SoldToPartyName like ''%Herby Pangemanan%'' then ''HERBY PANGEMANAN''
			when SoldToPartyName like ''%Maktal Jaya%'' then ''MAKTAL JAYA, CV''
			when SoldToPartyName like ''%Anugerah 5 Sempurna%'' then ''ANUGERAH 5 SEMPURNA, PT''
			when SoldToPartyName like ''%Anugerah Bina Usaha Nusantara%'' then ''PT. ANUGERAH BINA USAHA NUSANTARA''
			when SoldToPartyName like ''%Karya Prima CV%'' then ''CV. KARYA PRIMA''
			when SoldToPartyName like ''%WIJAYA, UD / WIDJAJA HERMAN%'' then ''WIDJAJA HERMAN''
			when SoldToPartyName like ''%CV. AGUNG RAYA LESTARI%'' then ''AGUNG RAYA LESTARI, CV''
			when SoldToPartyName like ''%CV. BORNEO CIPTA MANDIRI%'' then ''BORNEO CIPTA MANDIRI, CV''
			when SoldToPartyName like ''%SURYA UNGGUL SENTOSA CV%'' then ''SURYA UNGGUL SENTOSA, CV''
			when SoldToPartyName like ''%ANUGRAH JAYA PERKASA%'' then ''ANUGRAH JAYA PERKASA, CV''
			else SoldToPartyName 			 
		end,
		RMName,
		ASMName,
		Area,
		Provinsi,
		Kab'
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
	SoldToParty varchar(150),
	SoldToPartyName varchar(150),
	ShipToParty varchar(150),
	ShipToPartyName varchar(150),
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
					when (SoldToPartyName like '%Trijaya Niaga%') then 'IT'
					else 'FSBC'
				end
		end as RealChannel,
		DivDesc,
		case
			when (DivDesc = 'SAPPE') and (MaterialDesc like '%GOO.N%') then 'SAPPE-GOON'
			when (DivDesc = 'PECU') and (MaterialDesc like '%Cocoday%') then 'PECU-COCODAY'
			else DivDesc
		end as RealPrincipal,
		SoldToParty,
		SoldToPartyName,
		ShipToParty,
		ShipToPartyName,
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
	SoldToParty varchar(150),
	SoldToPartyName varchar(150),
	ShipToParty varchar(150),
	ShipToPartyName varchar(150),
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
		SoldToParty,
		SoldToPartyName,
		ShipToParty,
		ShipToPartyName,
		avg(SOAmount) as SO,
		sum(DOAmount) as DO,
		sum(GIAmt) as GI,
		sum(BillAmount) as Bill 
	from 
		#source
	where
		RealChannel = 'LD'
	group by
		SalesOrder,
		SOItem,
		OrderType,
		SalOffCode,
		SalOffName,
		RealChannel,
		RealPrincipal,		
		SoldToParty,
		SoldToPartyName,
		ShipToParty,
		ShipToPartyName
		
create table #value
(
	SalOffCode varchar(150),
	SalOffName varchar(150),
	Channel varchar(150),
	Principal varchar(150),
	SoldToParty varchar(150),
	SoldToPartyName varchar(150),
	ShipToParty varchar(150),
	ShipToPartyName varchar(150),
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
		SoldToParty,
		SoldToPartyName,
		ShipToParty,
		ShipToPartyName, 
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
		RealPrincipal,
		SoldToParty,
		SoldToPartyName,
		ShipToParty,
		ShipToPartyName

create table #merged
(
	Principal varchar(150),
	SoldToParty varchar(150),
	SoldToPartyName varchar(150),
	ShipToParty varchar(150),
	ShipToPartyName varchar(150),
	RMAreaCode varchar(150),
	RMAreaName varchar(150),
	RMName varchar(150),
	ASMName varchar(150),
	AREA varchar(150),
	PROVINSI varchar(150),
	KAB varchar(150),
	SO float,
	DO float,
	GI float,
	Bill float
)

insert into #merged
	select 
		Principal,
		V.SoldToParty,
		V.SoldToPartyName,
		V.ShipToParty,
		V.ShipToPartyName,
		RMAreaCode,
		RMAreaName,
		RMName,
		ASMName,
		AREA,
		PROVINSI,
		KAB,
		SO,
		DO,
		GI,
		Bill 
	from 
		#value V
		left join smartdash.dbo.Hadrian_LDMapping LDM
		on (V.SoldToParty = LDM.SoldToParty) and (V.ShipToParty = LDM.ShipToParty)

create table #CompiledValue
(
	Principal varchar(150),
	RMAreaCode varchar(150),
	RMAreaName varchar(150),
	SoldToPartyName varchar(150),
	RMName varchar(150),
	ASMName varchar(150),
	Area varchar(150),
	Provinsi varchar(150),
	Kab varchar(150),
	SO float,
	DO float,
	GI float,
	Bill float
)

insert into #CompiledValue
	select 
		Principal,
		RMAreaCode,
		RMAreaName,
		SoldToPartyName,
		RMName,
		ASMName,
		Area,
		Provinsi,
		Kab,
		sum(SO) as SO,
		sum(DO) as DO,
		sum(GI) as GI,
		sum(Bill) as Bill
	from 
		#merged M
	where 
		0=0
	group by
		M.Principal,
		M.RMAreaCode,
		M.RMAreaName,
		M.SoldToPartyName,
		M.RMName,
		M.ASMName,
		Area,
		Provinsi,
		Kab
	order by 
		Principal,
		SoldToPartyName,
		RMAreaCode

truncate table smartdash.dbo.Tab_SODOGIBill_Dashboard_LD_Breakdown
insert into smartdash.dbo.Tab_SODOGIBill_Dashboard_LD_Breakdown
select
	(select cast(max(SOCreation) as Date) from smartdash.dbo.Tab_SAPSalesDetail) as DataDate, 
	isnull(CV.Principal, ST.Principal) as Principal,
	isnull(CV.RMAreaCode, ST.RMAreaCode) as RMAreaCode,
	isnull(CV.RMAreaName, ST.RMAreaName) as RMAreaName,
	isnull(CV.SoldToPartyName, ST.SoldToPartyName) as SoldToPartyName,
	isnull(CV.RMName, ST.RMName) as RMName,
	isnull(CV.ASMName, ST.ASMName) as ASMName,
	isnull(CV.Area, ST.Area) as Area,
	isnull(CV.Provinsi, ST.Provinsi) as Provinsi,
	isnull(CV.Kab, ST.Kab) as Kab,
	isnull(SalesTarget,0) as SalesTarget,
	isnull(SO,0) as SO,
	isnull(DO,0) as DO,
	isnull(GI,0) as GI,
	isnull(Bill,0) as Bill 
from
	#CompiledValue CV
	full outer join #LDSalesTarget ST
	on 
		(CV.Principal = ST.Principal)
		and (CV.RMAreaCode = ST.RMAreaCode)
		and (CV.RMAreaName = ST.RMAreaName)
		and (CV.SoldToPartyName = ST.SoldToPartyName)
		and (CV.RMName = ST.RMName)
		and (CV.ASMName = ST.ASMName) 
		and (CV.Area = ST.Area) 
		and (CV.Provinsi = ST.Provinsi) 
		and (CV.Kab = ST.Kab) 

--select * from Tab_SODOGIBill_Dashboard_LD_Breakdown

/*
use smartdash
drop table smartdash.dbo.Tab_SODOGIBill_Dashboard_LD_Breakdown
create table Tab_SODOGIBill_Dashboard_LD_Breakdown
	(
	DataDate date,
	Principal varchar(150),
	RMAreaCode varchar(150),
	RMAreaName varchar(150),
	SoldToPartyName varchar(150),
	RMName varchar(150),
	ASMName varchar(150),
	Area varchar(150),
	Provinsi varchar(150),
	Kab varchar(150),
	SalesTarget float,
	SO float,
	DO float,    
	GI float,
	Bill float
	)
*/

drop table #LDSalesTarget
drop table #source
drop table #SOCompiled
drop table #value
drop table #merged
drop table #CompiledValue


SET NOCOUNT OFF

End