create database hotelroombookingdb
go
use hotelroombookingdb
go
create table roomtypes
(
	roomtypeid int identity primary key,
	typename varchar(20) not null,
	standardrate money not null
)
go
create table rateperiods
(
	periodid int identity primary key,
	ratestartmonth int not null,
	rateendmonth int not null
)
go
create table roomtyprates
(
	typeid int not null references roomtypes (roomtypeid),
	periodid int not null references rateperiods (periodid),
	rate money not null,
	primary key(typeid, periodid)
)
go
create table rooms
(
	roomid int identity primary key,
	roomtypeid int not null references roomtypes (roomtypeid),
	roomno varchar(30) not null,
	floorno int not null
)
go
create table bookings
(
	bookingid int identity primary key,
	datefrom date not null,
	dateto date not null,
	customername varchar(30) not null,
	customerphone varchar(20) not null,
	customeremail varchar(30) not null
)
go
create table roombookings
(
	roomid int  not null references rooms (roomid),
	bookingid int not null references bookings (bookingid),
	datefrom date not null,
	dateto date not null,
	primary key(roomid, bookingid)

)
go
create view vRoomBookings
as
SELECT        rooms.roomno, roomtypes.typename, bookings.customername, bookings.customerphone, bookings.customeremail, roombookings.datefrom, roombookings.dateto
FROM            rooms INNER JOIN
                         roombookings ON rooms.roomid = roombookings.roomid INNER JOIN
                         bookings ON roombookings.bookingid = bookings.bookingid INNER JOIN
                         roomtypes ON rooms.roomtypeid = roomtypes.roomtypeid
go
create function fnCurrentRate(@roomid int) returns money
as
begin
declare @r money
SELECT        @r=roomtyprates.rate
FROM            rooms INNER JOIN
                         roomtypes ON rooms.roomtypeid = roomtypes.roomtypeid INNER JOIN
                         roomtyprates ON roomtypes.roomtypeid = roomtyprates.typeid INNER JOIN
                         rateperiods ON roomtyprates.periodid = rateperiods.periodid
	where month(getdate()) >= month(roomtyprates.periodid)
			and month(getdate()) <= month(roomtyprates.periodid)
return @r
end
go
create trigger trRoombookingsIn
on roombookings
for insert
as
begin
	declare @r int, @s date
	select @r=roomid, @s = datefrom from inserted
	if exists (select 1 FROM  roombookings where @s >= datefrom and @s<=dateto)
	begin
		rollback
		raiserror('Room already booked for the period specified', 10, 1)
	end
end 
go