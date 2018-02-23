use SmartDash

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--create Procedure [dbo].[Tab_SP_GetSODOGIBill_Dashboard_NKAM_Breakdown] 
alter Procedure [dbo].[Tab_SP_GetSODOGIBill_Dashboard_NKAM_Breakdown] 

as Begin

SET NOCOUNT ON

-- MTD SODOGIBill, Breakdown NKAM, internal principals, MT Channel, only principals handled by KAMs

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
	BranchID Varchar(50),
	BranchName  varchar(150),
	PrincipalShortName Varchar(150),
	SubChannelName Varchar(150),
	TargetCustGroup varchar(150),
	TargetCustSubGroup varchar(150),
	SalesTarget Float
)

exec
(
'insert into #ThisMonthTarget 
	select
		BranchId,
		BranchName,
		PrincipalShortName,
		SubChannelName,
		CustGroup1 as TargetCustGroup,
		case CustGroup4 
			when ''SDN-JD ID'' then ''SDN-JD.ID''
			else CustGroup4
		end as TargetCustSubGroup, 
		'+ @current_month_text + ' as SalesTarget
	from 
		smartdash.dbo.Hadrian_SalesTarget
	where
		BranchID = ''999''
		and PrincipalShortName in (''SCP - Boemboe'', ''Branded'', ''Branded Industry'', ''Kreasi Mas Indah Bv'', ''Super Wahana Tehno'')
		and [Year] = '+ @current_year_int
)

create table #source
(
		SalesOrder varchar(150),
		SOItem varchar(150),
		SODocDate date,
		RejectDesc varchar(150),
		OrderType varchar(150),
		NKACustSubGroup varchar(150),
		SalOffCode varchar(150),
		SalOffName varchar(150),
		ChannelSO varchar(150),
		RealChannel varchar(150),
		DivDesc varchar(150),
		RealPrincipal varchar(150),
		BusinessManager varchar(150),
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
		CustGrp2Desc as NKACustSubGroup,
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
		case DivDesc
			when 'ASW Food' then 'Johannes Barito'
			when 'Branded' then 'Dionisius Hartanto'
			when 'Branded Industry' then 'Dionisius Hartanto'
			when 'CMI' then 'Roni Setiawan'
			when 'EPFM' then 'Sugeng Bachtiar'
			when 'Gandum Mas Kencana' then 'Johannes Barito'
			when 'Goodman Fielder' then 'Dionisius Hartanto'
			when 'Karya Adishin Sukses' then 'Roni Setiawan'
			when 'Kiyora Tea' then 'Beta Purnama'
			when 'Kreasi Mas Indah Bv' then 'Beta Purnama'
			when 'M-150' then 'Beta Purnama'
			when 'PECU' then 'Sugeng Bachtiar'
			when 'PNL' then 'Dionisius Hartanto'
			when 'SAPPE' then
					case
						when MaterialDesc like 'GOO.N%' then 'Roni Setiawan'
						else 'Beta Purnama'
					end
			when 'SCP - Boemboe' then 'Dionisius Hartanto'
			when 'SSS' then 'Sugeng Bachtiar'
			when 'Sugar Group' then 'Sugeng Bachtiar'
			when 'Sukanda Djaya' then 'Johannes Barito'
			when 'Super Wahana Tehno' then 'Beta Purnama'
			when 'SUPRAMA' then 'Sugeng Bachtiar'
		end as BusinessManager,
		SOAmount,
		DOAmount,
		GIAmt,
		BillAmount
	from 
		smartdash.dbo.tab_sapsalesdetail
	where
		0=0
		and month(SODocDate) = @current_month_int

create table #SOItemValue
(
	SalesOrder varchar(150),
	SOItem varchar(150),
	SODocDate varchar(150),
	RejectDesc varchar(150),
	OrderType varchar(150),
	NKACustSubGroup varchar(150),
	SalOffCode varchar(150),
	SalOffName varchar(150),
	RealChannel varchar(150),
	DivDesc varchar(150),
	RealPrincipal varchar(150),
	BusinessManager varchar(150),
	TotalSO float,
	TotalDO float,
	TotalGI float,
	TotalBill float
)

insert into #SOItemValue
	select
		SalesOrder,
		SOItem,
		SODocDate,
		RejectDesc,
		OrderType,
		NKACustSubGroup,
		SalOffCode,
		SalOffName,
		RealChannel,
		DivDesc,
		RealPrincipal,
		BusinessManager,
		avg(SOAmount) as TotalSO,
		sum(DOAmount) as TotalDO,
		sum(GIAmt) as TotalGI,
		sum(BillAmount) as TotalBill
	from 
		#source
	where
		0=0
	group by
		SalesOrder,
		SOItem,
		SODocDate,
		RejectDesc,
		OrderType,
		NKACustSubGroup,
		SalOffCode,
		SalOffName,
		RealChannel,
		DivDesc,
		RealPrincipal,
		BusinessManager

create table #NKAValue
(
	RealPrincipal varchar(150),
	NKACustSubGroup varchar(150),
	SO float,
	DO float,
	GI float,
	Bill float
)

insert into #NKAValue
	select
		RealPrincipal,
		NKACustSubGroup,
		sum(TotalSO) as SO,
		sum(TotalDO) as DO,
		sum(TotalGI) as GI,
		sum(TotalBill) as Bill
	from 
		#SOItemValue
	where 
		0=0
		and OrderType not in ('ZDSA', 'ZDR1', 'ZDR5')
		and 
			(
			RejectDesc is null 
			or RejectDesc in ('Stock kosong', 'Assigned by the system (Internal)')
			)
		and RealChannel = 'MT'
		and RealPrincipal in ('SCP - Boemboe', 'Branded', 'Branded Industry', 'Kreasi Mas Indah Bv', 'Super Wahana Tehno')
	group by
		RealPrincipal,
		NKACustSubGroup

create table #CustGroupMapping
(
	CustGroup varchar(150),
	CustSubGroup varchar(150)
)

insert into #CustGroupMapping
	select 
		distinct 
			custgroup1 as CustGroup, 
			case CustGroup4 
				when 'SDN-JD ID' then 'SDN-JD.ID'
				else CustGroup4
			end as CustSubGroup
	from 
		smartdash.dbo.hadrian_salestarget

truncate table smartdash.dbo.Tab_SODOGIBill_Dashboard_NKAM_Breakdown
insert into smartdash.dbo.Tab_SODOGIBill_Dashboard_NKAM_Breakdown 
	select
		(select cast(max(SOCreation) as date) from smartdash.dbo.tab_sapsalesdetail) as DataDate, 
		isnull(PrincipalShortName, RealPrincipal) as Principal,
		isnull(TargetCustGroup, CustGroup) as CustGroup,
		isnull(NKACustSubGroup, isnull(TargetCustSubGroup, CustSubGroup)) as CustSubGroup,
		NKAM,
		KAM,
		isnull(SalesTarget,0) as SalesTarget,
		isnull(SO,0) as SO,
		isnull(DO,0) as DO,
		isnull(GI,0) as GI, 
		isnull(Bill,0) as Bill
	from 
		#ThisMonthTarget
		full outer join #NKAValue
		on (
			NKACustSubGroup = TargetCustSubGroup
			and RealPrincipal = PrincipalShortName
			)
		full outer join #CustGroupMapping
		on isnull(NKACustSubGroup, TargetCustSubGroup) = CustSubGroup
		right join smartdash.dbo.Hadrian_KAMMapping
		on AccountName = isnull(NKACustSubGroup, isnull(TargetCustSubGroup, CustSubGroup))
	where
		KAM <> '-'
	order by
		isnull(PrincipalShortName, RealPrincipal),
		isnull(TargetCustGroup, CustGroup),
		TargetCustSubGroup

-- sense check
/*
select
	NKAM,
	format(sum(SalesTarget),'#,#') TotalST,
	format(sum(SO),'#,#') TotalSO,
	format(sum(DO),'#,#') TotalDO,
	format(sum(GI),'#,#') TotalGI,
	format(sum(Bill),'#,#') TotalBill
from 
	#ThisMonthTarget
	full outer join #NKAValue
	on (
		NKACustSubGroup = TargetCustSubGroup
		and RealPrincipal = PrincipalShortName
		)
	full outer join #CustGroupMapping
	on isnull(NKACustSubGroup, TargetCustSubGroup) = CustSubGroup
	right join smartdash.dbo.Hadrian_KAMMapping
	on AccountName = isnull(NKACustSubGroup, isnull(TargetCustSubGroup, CustSubGroup))
where
	KAM <> '-'
group by
	NKAM

-- sense check
select
	NKAM,
	KAM, 
	format(sum(SalesTarget),'#,#') TotalST,
	format(sum(SO),'#,#') TotalSO,
	format(sum(DO),'#,#') TotalDO,
	format(sum(GI),'#,#') TotalGI,
	format(sum(Bill),'#,#') TotalBill
from 
	#ThisMonthTarget
	full outer join #NKAValue
	on (
		NKACustSubGroup = TargetCustSubGroup
		and RealPrincipal = PrincipalShortName
		)
	full outer join #CustGroupMapping
	on isnull(NKACustSubGroup, TargetCustSubGroup) = CustSubGroup
	right join smartdash.dbo.Hadrian_KAMMapping
	on AccountName = isnull(NKACustSubGroup, isnull(TargetCustSubGroup, CustSubGroup))
where
	KAM <> '-'
group by
	NKAM,
	KAM
*/

/*
use smartdash
drop table Tab_SODOGIBill_Dashboard_NKAM_Breakdown
create table Tab_SODOGIBill_Dashboard_NKAM_Breakdown
(
	DataDate date, 
	Principal varchar(150),
	CustGroup varchar(150),
	CustSubGroup varchar(150),
	NKAM varchar(150),
	KAM varchar(150),
	SalesTarget float,
	SO float,
	DO float,
	GI float, 
	Bill float
)
*/

drop table #ThisMonthTarget
drop table #source
drop table #SOItemValue
drop table #NKAValue
drop table #CustGroupMapping

SET NOCOUNT OFF

End