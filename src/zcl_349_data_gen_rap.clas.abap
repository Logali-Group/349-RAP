class zcl_349_data_gen_rap definition
  public
  final
  create public .

  public section.

    interfaces if_oo_adt_classrun .
  protected section.
  private section.
ENDCLASS.



CLASS ZCL_349_DATA_GEN_RAP IMPLEMENTATION.


  method if_oo_adt_classrun~main.

    out->write( 'Adding Travel data' ).

    delete from z349_travel_a.

    insert z349_travel_a from (
    select from /dmo/travel
      fields
        " client
        uuid( ) as travel_uuid,
        travel_id,
        agency_id,
        customer_id,
        begin_date,
        end_date,
        booking_fee,
        total_price,
        currency_code,
        description,
        case status when 'B' then 'A'
                    when 'P' then 'O'
                    when 'N' then 'O'
                    else 'X' end as overall_status,
        createdby as local_created_by,
        createdat as local_created_at,
        lastchangedby as local_last_changed_by,
        lastchangedat as local_last_changed_at,
        lastchangedat as last_changed_at

    ).

    out->write( 'Adding Booking data' ).

    delete from z349_booking_a.

    insert z349_booking_a from (

        select
          from /dmo/booking
          join z349_travel_a on /dmo/booking~travel_id = z349_travel_a~travel_id
          join /dmo/travel on /dmo/travel~travel_id = /dmo/booking~travel_id
          fields  "client,
                  uuid( ) as booking_uuid,
                  z349_travel_a~travel_uuid as parent_uuid,
                  /dmo/booking~booking_id,
                  /dmo/booking~booking_date,
                  /dmo/booking~customer_id,
                  /dmo/booking~carrier_id,
                  /dmo/booking~connection_id,
                  /dmo/booking~flight_date,
                  /dmo/booking~flight_price,
                  /dmo/booking~currency_code,
                  case /dmo/travel~status when 'P' then 'N'
                                                   else /dmo/travel~status end as booking_status,
                  z349_travel_a~last_changed_at as local_last_changed_at ).


    delete from z349_bksuppl_a.

    out->write( 'Adding Booking Supplements data' ).

    insert z349_bksuppl_a from (
       select from /dmo/book_suppl as supp
              join z349_travel_a  as trvl on trvl~travel_id = supp~travel_id
              join z349_booking_a as book on book~parent_uuid = trvl~travel_uuid
                                         and book~booking_id = supp~booking_id
              fields
              uuid( )                 as booksuppl_uuid,
              trvl~travel_uuid        as root_uuid,
              book~booking_uuid       as parent_uuid,
              supp~booking_supplement_id,
              supp~supplement_id,
              supp~price,
              supp~currency_code,
              trvl~last_changed_at    as local_last_changed_at

    ).

  endmethod.
ENDCLASS.
