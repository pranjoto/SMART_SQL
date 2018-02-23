use SmartDash

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--create Procedure [dbo].[Tab_SP_GetLogisticsSL] 
alter Procedure [dbo].[Tab_SP_GetLogisticsSL] 

as Begin

SET NOCOUNT ON

-- Author: Hadrian Pranjoto (hadrian.pranjoto@sinarmas-agribusiness.com)
-- Description: service level dashboard for logistics

truncate table SmartDash.dbo.Tab_LogisticsSL

--MaxDate = Data Date = Max SO Creation Date from sales report
declare @maxdate date = (select cast(max(SOCreation) as date) from smartdash.dbo.tab_sapsalesdetail)

-- Holidays, for delivery date adjustment
declare @HolidayList table (HolidayDate date)
insert into @HolidayList values 
	('2017-08-17'), -- Dirgahayu RI 
	('2017-09-01'), -- Idul Adha
	('2017-09-21'), -- Tahun Baru Hijriyah
	('2017-12-01'), -- Maulud Nabi
	('2017-12-25'), -- Natal
	('2018-01-01'), -- Tahun Baru
	('2018-02-16'), -- Imlek
	('2018-03-17'), -- Nyepi
	('2018-03-30'), -- Wafat Isa Almasih
	('2018-04-14'), -- Isra Miraj
	('2018-05-01'), -- Hari Buruh Internasional
	('2018-05-10'), -- Kenaikan Isa Almasih
	('2018-05-29'), -- Waisak
	('2018-06-01'), -- Hari Lahir Pancasila
	('2018-06-15'), -- Idul Fitri
	('2018-06-16'), -- Idul Fitri
	('2018-08-17'), -- Dirgahayu Indonesia
	('2018-08-22'), -- Idul Adha
	('2018-09-11'), -- Tahun Baru Hijriyah
	('2018-11-20'), -- Maulid Nabi
	('2018-12-25') -- Natal

create table #ProductConversion
(
	ProductID varchar(150),
	ProductName varchar(150),
	BaseUoM varchar(150), 
	Numeration1 integer,
	Conversion1 integer,
	UoM1 varchar(150),
	Numeration2 integer,
	Conversion2 integer,
	UoM2 varchar(150),
	Numeration3 integer,
	Conversion3 integer,
	UoM3 varchar(150),
	Numeration4 integer,
	Conversion4 integer,
	UoM4 varchar(150),
	Numeration5 integer,
	Conversion5 integer,
	UoM5 varchar(150)
)

insert into #ProductConversion

	select 
		szProductID as ProductID,
		szName as ProductName,

		-- i.e. [Numeration n] [BaseUoM] = [Conversion n] [UoM n]
		-- e.g. [1] [KAR] = [30] [PC]

		Base_Units_of_measurement as BaseUoM, 
		
		Numeration1,
		Conversion1,
		UoM1,
		Numeration2,
		Conversion2,
		UoM2,		
		Numeration3,
		Conversion3,
		UoM3,		
		Numeration4,
		Conversion4,
		UoM4,		
		Numeration5,
		Conversion5,
		UoM5	

	from 
		Bosnet.dbo.Bos_Inv_Product IP
		full outer join 
		Bosnet1.dbo.Product P
		on IP.szProductId = P.Product_ID collate database_default
	where
		0=0

create table #baseUoM
(
	MaxDate date,
	SalesOrder varchar(150),
	SOCreation date,
	RejectDesc varchar(150),
	OrderType varchar(150),
	C varchar(150), 
	CredStatTxt varchar(150),
	CustGrp2Desc varchar(150),
	PO_Date date,
	PO_Day varchar(150),
	Inc varchar(150),
	SalOffName varchar(150),
	ChannelSO varchar(150),
	RealChannel varchar(150),
	Principal varchar(150),
	SoldToParty varchar(150),
	SoldToPartyName varchar(150),
	ShipToParty varchar(150),
	ShipToPartyName varchar(150),
	SOItem varchar(150),
	DONumber varchar(150), 
	MaterialCode varchar(150),
	MaterialDesc varchar(150),
	SOAmount float, 
	SOQty float,
	SOUnit varchar(150),
	DOAmount float,
	DOQty float,
	DOUnit varchar(150),
	GIAmount float,
	GIQty float,
	GIUnit varchar(150),
	BillAmount float,
	BillQty float,
	BillUnit varchar(150),
	BillingDate date,
	BillCreated date,
	ReqDlvDt date,
	ReqDlvDay varchar(150),
	Numeration1 integer,
	Conversion1 integer,
	UoM1 varchar(150),
	Numeration2 integer,
	Conversion2 integer,
	UoM2 varchar(150),
	Numeration3 integer,
	Conversion3 integer,
	UoM3 varchar(150),
	Numeration4 integer,
	Conversion4 integer,
	UoM4 varchar(150),
	Numeration5 integer,
	Conversion5 integer,
	UoM5 varchar(150),
	BaseUoM varchar(150),
	SOQtyBaseUoM float,
	DOQtyBaseUoM float,
	GIQtyBaseUoM float,
	BillQtyBaseUoM float
)

insert into #baseUoM
	select
		@MaxDate as MaxDate, 
		SalesOrder,
		SOCreation,
		RejectDesc,
		OrderType,
		C,
		CredStatTxt,
		CustGrp2Desc,
		PO_Date,
		datename(dw, PO_Date) as PO_Day,
		Inc,
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
			when 'MT' then 'MT-NKA'
			when 'IT' then
				case 
					when (SalOffName = 'Jakarta 2') and (ShipToPartyName like '%Mitra Abadijaya%') and (DivDesc = 'Branded') then 'LD'
					when (SalOffName = 'Jakarta 2') and (DivDesc = 'Branded Industry') then 'IT'
					else 'FSBC'
				end
		end as RealChannel,
		DivDesc as Principal,
		SoldToParty,
		SoldToPartyName,
		ShipToParty,
		ShipToPartyName,
		SOItem,
		DONumber, 
		MaterialCode,
		MaterialDesc,
		SOAmount, 
		cast(SOQty as float) as SOQty,
		SOUnit,
		DOAmount,
		cast(DOQty as float) as DOQty,
		case
			when DOUnit is null then SOUnit
			else DOUnit
		end as DOUnit,
		GIAmt as GIAmount,
		cast(GIQty as float) as GIQty,
		case
			when GIUoM is null then SOUnit
			else GIUoM
		end as GIUnit,
		BillAmount,
		cast(BillQty as float) as BillQty,
		case
			when BillUnit is null then SOUnit
			else BillUnit
		end as BillUnit,
		BillingDate, -- manual input by sales admin
		BillCreated,
		ReqDlvDt, -- manual input by sales admin
		datename(dw,ReqDlvDt) as ReqDlvDay, 
		Numeration1,
		Conversion1,
		UoM1,
		Numeration2,
		Conversion2,
		UoM2,
		Numeration3,
		Conversion3,
		UoM3,
		Numeration4,
		Conversion4,
		UoM4,
		Numeration5,
		Conversion5,
		UoM5,
		BaseUoM,

		case
			when SOUnit is null then null
			when (SOUnit = BaseUoM collate database_default) then cast(SOQty as float) 
			when (SOUnit = UoM1 collate database_default) then cast(SOQty as float) * cast(Numeration1 as float) / cast(Conversion1 as float)
			when (SOUnit = UoM2 collate database_default) then cast(SOQty as float) * cast(Numeration2 as float) / cast(Conversion2 as float)
			when (SOUnit = UoM3 collate database_default) then cast(SOQty as float) * cast(Numeration3 as float) / cast(Conversion3 as float)
			when (SOUnit = UoM4 collate database_default) then cast(SOQty as float) * cast(Numeration4 as float) / cast(Conversion4 as float)
			when (SOUnit = UoM5 collate database_default) then cast(SOQty as float) * cast(Numeration5 as float) / cast(Conversion5 as float)
			else null --SO Unit cannot be converted
		end as SOQtyBaseUoM,
		case
			when DOUnit is null then null
			when (DOUnit = BaseUoM collate database_default) then cast(DOQty as float) 
			when (DOUnit = UoM1 collate database_default) then cast(DOQty as float) * cast(Numeration1 as float) / cast(Conversion1 as float)
			when (DOUnit = UoM2 collate database_default) then cast(DOQty as float) * cast(Numeration2 as float) / cast(Conversion2 as float)
			when (DOUnit = UoM3 collate database_default) then cast(DOQty as float) * cast(Numeration3 as float) / cast(Conversion3 as float)
			when (DOUnit = UoM4 collate database_default) then cast(DOQty as float) * cast(Numeration4 as float) / cast(Conversion4 as float)
			when (DOUnit = UoM5 collate database_default) then cast(DOQty as float) * cast(Numeration5 as float) / cast(Conversion5 as float)
			else null --DO Unit cannot be converted
		end as DOQtyBaseUoM,
		case
			when GIUoM is null then null
			when (GIUoM = BaseUoM collate database_default) then cast(GIQty as float) 
			when (GIUoM = UoM1 collate database_default) then cast(GIQty as float) * cast(Numeration1 as float) / cast(Conversion1 as float)
			when (GIUoM = UoM2 collate database_default) then cast(GIQty as float) * cast(Numeration2 as float) / cast(Conversion2 as float)
			when (GIUoM = UoM3 collate database_default) then cast(GIQty as float) * cast(Numeration3 as float) / cast(Conversion3 as float)
			when (GIUoM = UoM4 collate database_default) then cast(GIQty as float) * cast(Numeration4 as float) / cast(Conversion4 as float)
			when (GIUoM = UoM5 collate database_default) then cast(GIQty as float) * cast(Numeration5 as float) / cast(Conversion5 as float)
			else null --GI Unit cannot be converted
		end as GIQtyBaseUoM,
		case
			when (BillUnit is null) then null
			when (BillUnit = BaseUoM collate database_default) then cast(BillQty as float) 
			when (BillUnit = UoM1 collate database_default) then cast(BillQty as float) * cast(Numeration1 as float) / cast(Conversion1 as float)
			when (BillUnit = UoM2 collate database_default) then cast(BillQty as float) * cast(Numeration2 as float) / cast(Conversion2 as float)
			when (BillUnit = UoM3 collate database_default) then cast(BillQty as float) * cast(Numeration3 as float) / cast(Conversion3 as float)
			when (BillUnit = UoM4 collate database_default) then cast(BillQty as float) * cast(Numeration4 as float) / cast(Conversion4 as float)
			when (BillUnit = UoM5 collate database_default) then cast(BillQty as float) * cast(Numeration5 as float) / cast(Conversion5 as float)
			else null --Bill Unit cannot be converted
		end as BillQtyBaseUoM

	from 
		smartdash.dbo.tab_sapsalesdetail SSD
		left join #ProductConversion PC
		on SSD.MaterialCode = PC.ProductID collate database_default

	where
		0=0

create table #BoxEquivalent
(
	MaxDate date,
	SalesOrder varchar(150),
	SOCreation date,
	RejectDesc varchar(150),
	OrderType varchar(150),
	C varchar(150), 
	CredStatTxt varchar(150),
	CustGrp2Desc varchar(150),
	PO_Date date,
	PO_Day varchar(150),
	Inc varchar(150),
	SalOffName varchar(150),
	ChannelSO varchar(150),
	RealChannel varchar(150),
	Principal varchar(150),
	SoldToParty varchar(150),
	SoldToPartyName varchar(150),
	ShipToParty varchar(150),
	ShipToPartyName varchar(150),
	SOItem varchar(150),
	DONumber varchar(150), 
	MaterialCode varchar(150),
	MaterialDesc varchar(150),
	SOAmount float, 
	SOQty float,
	SOUnit varchar(150),
	DOAmount float,
	DOQty float,
	DOUnit varchar(150),
	GIAmount float,
	GIQty float,
	GIUnit varchar(150),
	BillAmount float,
	BillQty float,
	BillUnit varchar(150),
	BillingDate date,
	BillCreated date,
	ReqDlvDt date,
	ReqDlvDay varchar(150),
	Numeration1 float,
	Conversion1 float,
	UoM1 varchar(150),
	Numeration2 float,
	Conversion2 float,
	UoM2 varchar(150),
	Numeration3 float,
	Conversion3 float,
	UoM3 varchar(150),
	Numeration4 float,
	Conversion4 float,
	UoM4 varchar(150),
	Numeration5 float,
	Conversion5 float,
	UoM5 varchar(150),
	BaseUoM varchar(150),
	SOQtyBaseUoM float,
	DOQtyBaseUoM float,
	GIQtyBaseUoM float,
	BillQtyBaseUoM float,
	SOCleared varchar(150),
	RealReqDlvDt date,
	BoxEquivalentUoM varchar(150),
	SOQtyBoxEquivalent float,
	DOQtyBoxEquivalent float,
	GIQtyBoxEquivalent float,
	BillQtyBoxEquivalent float
)

insert into #BoxEquivalent
	select 
		*,
		case
			when RealChannel in ('MT-NKA', 'MT-Branch', 'LD', 'FSBC', 'FS-Branch', 'IT','Others') then 'Yes'
			when RealChannel in ('GT-Branch') then
				case
					when 	
						(
						(RejectDesc is Null) 
						or (RejectDesc in ('Stock kosong', 'Assigned by the system (Internal)'))
						) 
					then 'Yes'
					else 'No'
				end
			else null
		end as SOCleared,
		case
			when RealChannel in ('MT-Branch', 'MT-NKA', 'LD', 'FSBC', 'FS-Branch', 'IT', 'Others') then
				case
					when ReqDlvDay = 'Sunday' then dateadd(day,1,ReqDlvDt)
					when ReqDlvDt in (select * from @HolidayList) then dateadd(day,1,ReqDlvDt)
					else ReqDlvDt
				end
			when RealChannel = 'GT-Branch' then
				case
					when PO_Day in ('Friday', 'Saturday') then 
						case
							when dateadd(day,3,PO_Date) in (select * from @HolidayList) then dateadd(day,4,PO_Date)
							else dateadd(day,3,PO_Date)
						end
					when dateadd(day,2,PO_Date) in (select * from @HolidayList) then dateadd(day,3,PO_Date)
					else dateadd(day,2,PO_Date)
				end
			else ReqDlvDt 
		end as RealReqDlvDt,
		case
			when SOQtyBaseUoM is not null then
				case
					when BaseUoM in ('BOX', 'KAR', 'ZAK', 'KG') then BaseUoM
					when UoM1 in ('BOX', 'KAR', 'ZAK', 'KG') then UoM1
					when UoM2 in ('BOX', 'KAR', 'ZAK', 'KG') then UoM2
					when UoM3 in ('BOX', 'KAR', 'ZAK', 'KG') then UoM3
					when UoM4 in ('BOX', 'KAR', 'ZAK', 'KG') then UoM4
					when UoM5 in ('BOX', 'KAR', 'ZAK', 'KG') then UoM5
				end
			else --cannot be converted into Base UoM
				case
					when SOUnit in ('BOX', 'KAR', 'ZAK', 'KG') then SOUnit
					when UoM1 in ('BOX', 'KAR', 'ZAK', 'KG') then UoM1
					when UoM2 in ('BOX', 'KAR', 'ZAK', 'KG') then UoM2
					when UoM3 in ('BOX', 'KAR', 'ZAK', 'KG') then UoM3
					when UoM4 in ('BOX', 'KAR', 'ZAK', 'KG') then UoM4
					when UoM5 in ('BOX', 'KAR', 'ZAK', 'KG') then UoM5
				end
		end as BoxEquivalentUoM,
		case
			when SOQtyBaseUoM is not null then
				case
					when BaseUoM in ('BOX', 'KAR', 'ZAK', 'KG') then cast(SOQtyBaseUoM as float)
					when UoM1 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(SOQtyBaseUoM as float) * cast(Conversion1 as float) / cast(Numeration1 as float)
					when UoM2 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(SOQtyBaseUoM as float) * cast(Conversion2 as float) / cast(Numeration2 as float)
					when UoM3 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(SOQtyBaseUoM as float) * cast(Conversion3 as float) / cast(Numeration3 as float)
					when UoM4 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(SOQtyBaseUoM as float) * cast(Conversion4 as float) / cast(Numeration4 as float)
					when UoM5 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(SOQtyBaseUoM as float) * cast(Conversion5 as float) / cast(Numeration5 as float)
				end
			else --cannot be converted into Base UoM
				case
					when SOUnit in ('BOX', 'KAR', 'ZAK', 'KG') then cast(SOQty as float)
					when UoM1 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(SOQty as float) * cast(Conversion1 as float) / cast(Numeration1 as float)
					when UoM2 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(SOQty as float) * cast(Conversion2 as float) / cast(Numeration2 as float)
					when UoM3 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(SOQty as float) * cast(Conversion3 as float) / cast(Numeration3 as float)
					when UoM4 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(SOQty as float) * cast(Conversion4 as float) / cast(Numeration4 as float)
					when UoM5 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(SOQty as float) * cast(Conversion5 as float) / cast(Numeration5 as float)
				end
		end as SOQtyBoxEquivalent,
		case
			when DOQtyBaseUoM is not null then
				case
					when BaseUoM in ('BOX', 'KAR', 'ZAK', 'KG') then cast(DOQtyBaseUoM as float)
					when UoM1 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(DOQtyBaseUoM as float) * cast(Conversion1 as float) / cast(Numeration1 as float)
					when UoM2 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(DOQtyBaseUoM as float) * cast(Conversion2 as float) / cast(Numeration2 as float)
					when UoM3 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(DOQtyBaseUoM as float) * cast(Conversion3 as float) / cast(Numeration3 as float)
					when UoM4 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(DOQtyBaseUoM as float) * cast(Conversion4 as float) / cast(Numeration4 as float)
					when UoM5 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(DOQtyBaseUoM as float) * cast(Conversion5 as float) / cast(Numeration5 as float)
				end
			else --cannot be converted into Base UoM
				case
					when DOUnit in ('BOX', 'KAR', 'ZAK', 'KG') then cast(DOQty as float)
					when UoM1 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(DOQty as float) * cast(Conversion1 as float) / cast(Numeration1 as float)
					when UoM2 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(DOQty as float) * cast(Conversion2 as float) / cast(Numeration2 as float)
					when UoM3 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(DOQty as float) * cast(Conversion3 as float) / cast(Numeration3 as float)
					when UoM4 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(DOQty as float) * cast(Conversion4 as float) / cast(Numeration4 as float)
					when UoM5 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(DOQty as float) * cast(Conversion5 as float) / cast(Numeration5 as float)
				end
		end as DOQtyBoxEquivalent,
		case
			when GIQtyBaseUoM is not null then
				case
					when BaseUoM in ('BOX', 'KAR', 'ZAK', 'KG') then cast(GIQtyBaseUoM as float)
					when UoM1 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(GIQtyBaseUoM as float) * cast(Conversion1 as float) / cast(Numeration1 as float)
					when UoM2 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(GIQtyBaseUoM as float) * cast(Conversion2 as float) / cast(Numeration2 as float)
					when UoM3 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(GIQtyBaseUoM as float) * cast(Conversion3 as float) / cast(Numeration3 as float)
					when UoM4 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(GIQtyBaseUoM as float) * cast(Conversion4 as float) / cast(Numeration4 as float)
					when UoM5 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(GIQtyBaseUoM as float) * cast(Conversion5 as float) / cast(Numeration5 as float)		
				end
			else --cannot be converted into Base UoM
				case
					when GIUnit in ('BOX', 'KAR', 'ZAK', 'KG') then cast(GIQty as float)
					when UoM1 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(GIQty as float) * cast(Conversion1 as float) / cast(Numeration1 as float)
					when UoM2 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(GIQty as float) * cast(Conversion2 as float) / cast(Numeration2 as float)
					when UoM3 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(GIQty as float) * cast(Conversion3 as float) / cast(Numeration3 as float)
					when UoM4 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(GIQty as float) * cast(Conversion4 as float) / cast(Numeration4 as float)
					when UoM5 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(GIQty as float) * cast(Conversion5 as float) / cast(Numeration5 as float)
				end	
		end as GIQtyBoxEquivalent,
		case
			when BillQtyBaseUoM is not null then
				case
					when BaseUoM in ('BOX', 'KAR', 'ZAK', 'KG') then cast(BillQtyBaseUoM as float)
					when UoM1 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(BillQtyBaseUoM as float) * cast(Conversion1 as float) / cast(Numeration1 as float)
					when UoM2 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(BillQtyBaseUoM as float) * cast(Conversion2 as float) / cast(Numeration2 as float)
					when UoM3 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(BillQtyBaseUoM as float) * cast(Conversion3 as float) / cast(Numeration3 as float)
					when UoM4 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(BillQtyBaseUoM as float) * cast(Conversion4 as float) / cast(Numeration4 as float)
					when UoM5 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(BillQtyBaseUoM as float) * cast(Conversion5 as float) / cast(Numeration5 as float)
				end
			else --cannot be converted into Base UoM
				case
					when BillUnit in ('BOX', 'KAR', 'ZAK', 'KG') then cast(BillQty as float)
					when UoM1 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(BillQty as float) * cast(Conversion1 as float) / cast(Numeration1 as float)
					when UoM2 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(BillQty as float) * cast(Conversion2 as float) / cast(Numeration2 as float)
					when UoM3 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(BillQty as float) * cast(Conversion3 as float) / cast(Numeration3 as float)
					when UoM4 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(BillQty as float) * cast(Conversion4 as float) / cast(Numeration4 as float)
					when UoM5 in ('BOX', 'KAR', 'ZAK', 'KG') then cast(BillQty as float) * cast(Conversion5 as float) / cast(Numeration5 as float)
				end		
		end as BillQtyBoxEquivalent
	from #baseUoM

create table #Timing
(
	MaxDate date,
	SalesOrder varchar(150),
	SOCreation date,
	RejectDesc varchar(150),
	OrderType varchar(150),
	C varchar(150), 
	CredStatTxt varchar(150),
	CustGrp2Desc varchar(150),
	PO_Date date,
	PO_Day varchar(150),
	Inc varchar(150),
	SalOffName varchar(150),
	ChannelSO varchar(150),
	RealChannel varchar(150),
	Principal varchar(150),
	SoldToParty varchar(150),
	SoldToPartyName varchar(150),
	ShipToParty varchar(150),
	ShipToPartyName varchar(150),
	SOItem varchar(150),
	DONumber varchar(150), 
	MaterialCode varchar(150),
	MaterialDesc varchar(150),
	SOAmount float, 
	SOQty float,
	SOUnit varchar(150),
	DOAmount float,
	DOQty float,
	DOUnit varchar(150),
	GIAmount float,
	GIQty float,
	GIUnit varchar(150),
	BillAmount float,
	BillQty float,
	BillUnit varchar(150),
	BillingDate date,
	BillCreated date,
	ReqDlvDt date,
	ReqDlvDay varchar(150),
	Numeration1 integer,
	Conversion1 integer,
	UoM1 varchar(150),
	Numeration2 integer,
	Conversion2 integer,
	UoM2 varchar(150),
	Numeration3 integer,
	Conversion3 integer,
	UoM3 varchar(150),
	Numeration4 integer,
	Conversion4 integer,
	UoM4 varchar(150),
	Numeration5 integer,
	Conversion5 integer,
	UoM5 varchar(150),
	BaseUoM varchar(150),
	SOQtyBaseUoM float,
	DOQtyBaseUoM float,
	GIQtyBaseUoM float,
	BillQtyBaseUoM float,
	SOCleared varchar(150),
	RealReqDlvDt date,
	BoxEquivalentUoM varchar(150),
	SOQtyBoxEquivalent float,
	DOQtyBoxEquivalent float,
	GIQtyBoxEquivalent float,
	BillQtyBoxEquivalent float,
	OnTime varchar(150),
	TimingStatus varchar(150)
)

insert into #Timing
	select 
		*,
		case
			when BillingDate is null then null 
			when BillingDate > RealReqDlvDt then 'No'
			else 'Yes'	
		end as OnTime,
		case
			when 
				(
				RealReqDlvDt <= @MaxDate --include incomplete deliveries whose RDD <= data retrieval date  
				or BillingDate is not null --include all completed deliveries regardless of the RDD
				)	
				then 'MTD'
			else 'Incoming' --all deliveries with RDD > Data retrieval date
		end as TimingStatus
	from #BoxEquivalent

insert into smartdash.dbo.Tab_LogisticsSL
	select 
		MaxDate,
		SalesOrder,
		SONo = right(SalesOrder,10),
		SOCreation,
		RejectDesc,
		OrderType,
		C, 
		CredStatTxt,
		CustGrp2Desc,
		PO_Date,
		PO_Day,
		Inc,
		SalOffName,
		ChannelSO,
		RealChannel,
		Principal,
		SoldToParty,
		SoldToPartyName,
		ShipToParty,
		ShipToPartyName,
		SOItem,
		DONumber, 
		MaterialCode,
		MaterialDesc,
		avg(SOAmount) as SOAmount, 
		avg(SOQty) as SOQty,
		SOUnit,
		sum(DOAmount) as DOAmount,
		sum(DOQty) as DOQty,
		DOUnit,
		sum(GIAmount) as GIAmount,
		sum(GIQty) as GIQty,
		GIUnit,
		sum(BillAmount) as BillAmount,
		sum(BillQty) as BillQty,
		BillUnit,
		BillingDate,
		BillCreated,
		ReqDlvDt,
		ReqDlvDay,
		Numeration1,
		Conversion1,
		UoM1,
		Numeration2,
		Conversion2,
		UoM2,
		Numeration3,
		Conversion3,
		UoM3,
		Numeration4,
		Conversion4,
		UoM4,
		Numeration5,
		Conversion5,
		UoM5,
		BaseUoM,
		avg(SOQtyBaseUoM) as SOQtyBaseUoM,
		sum(DOQtyBaseUoM) as DOQtyBaseUoM,
		sum(GIQtyBaseUoM) as GIQtyBaseUoM,
		sum(BillQtyBaseUoM) as BillQtyBaseUoM,
		SOCleared,
		RealReqDlvDt,
		BoxEquivalentUoM,
		avg(SOQtyBoxEquivalent) as SOQtyBoxEquivalent,
		sum(DOQtyBoxEquivalent) as DOQtyBoxEquivalent,
		sum(GIQtyBoxEquivalent) as GIQtyBoxEquivalent,
		sum(BillQtyBoxEquivalent) as BillQtyBoxEquivalent,
		OnTime,
		TimingStatus
	from 
		#Timing
	where
		0=0
		and OrderType not in ('ZDR5','ZDR1','ZDSA','ZDCV')
	group by
		MaxDate,
		SOCreation,
		SalesOrder,
		RejectDesc,
		OrderType,
		C, 
		CredStatTxt,
		CustGrp2Desc,
		PO_Date,
		PO_Day,
		Inc,
		SalOffName,
		ChannelSO,
		RealChannel,
		Principal,
		SoldToParty,
		SoldToPartyName,
		ShipToParty,
		ShipToPartyName,
		SOItem,
		DONumber, 
		MaterialCode,
		MaterialDesc, 
		SOUnit,
		DOUnit,
		GIUnit,
		BillUnit,
		BillingDate,
		BillCreated,
		ReqDlvDt,
		ReqDlvDay,
		Numeration1,
		Conversion1,
		UoM1,
		Numeration2,
		Conversion2,
		UoM2,
		Numeration3,
		Conversion3,
		UoM3,
		Numeration4,
		Conversion4,
		UoM4,
		Numeration5,
		Conversion5,
		UoM5,
		BaseUoM,
		SOCleared,
		RealReqDlvDt,
		BoxEquivalentUoM,
		OnTime,
		TimingStatus

drop table #productconversion
drop table #baseUoM
drop table #BoxEquivalent
drop table #Timing 


SET NOCOUNT OFF

End