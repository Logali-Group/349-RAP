class lhc_Booking definition inheriting from cl_abap_behavior_handler.
  private section.

    constants:
      begin of booking_status,
        new    type c length 1 value 'N', "New
        booked type c length 1 value 'B', "Booked
      end of booking_status.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for Booking result result.

    methods get_global_authorizations for global authorization
      importing request requested_authorizations for Booking result result.

    methods calculateTotalPrice for determine on modify
      importing keys for Booking~calculateTotalPrice.

    methods setBookingDate for determine on modify
      importing keys for Booking~setBookingDate.

    methods setBookingNumber for determine on save
      importing keys for Booking~setBookingNumber.

    methods validateConnection for validate on save
      importing keys for Booking~validateConnection.

    methods validateCurrency for validate on save
      importing keys for Booking~validateCurrency.

    methods validateCustomer for validate on save
      importing keys for Booking~validateCustomer.

    methods validateFlightPrice for validate on save
      importing keys for Booking~validateFlightPrice.

    methods validateStatus for validate on save
      importing keys for Booking~validateStatus.

endclass.

class lhc_Booking implementation.

  method get_instance_authorizations.
  endmethod.

  method get_global_authorizations.
  endmethod.

  method calculateTotalPrice.

    " Parent UUIDs
    read entities of z349_r_travel_lgl in local mode
         entity Booking by \_Travel
         fields ( TravelUUID  )
         with corresponding #(  keys  )
         result data(travels).

    " Trigger Re-Calculation on Root Node
    modify entities of z349_r_travel_lgl in local mode
      entity Travel
        execute reCalcTotalPrice
          from corresponding  #( travels ).

  endmethod.

  method setBookingDate.

    read entities of z349_r_travel_lgl in local mode
       entity Booking
         fields ( BookingDate )
         with corresponding #( keys )
       result data(bookings).

    delete bookings where BookingDate is not initial.
    check bookings is not initial.

    loop at bookings assigning field-symbol(<booking>).
      <booking>-BookingDate = cl_abap_context_info=>get_system_date( ).
    endloop.

    modify entities of z349_r_travel_lgl in local mode
      entity Booking
        update  fields ( BookingDate )
        with corresponding #( bookings ).

  endmethod.

  method setBookingNumber.

    data: bookinks_u  type table for update z349_r_travel_lgl\\Booking,
          max_book_id type /dmo/booking_id.

    read entities of z349_r_travel_lgl in local mode
         entity Booking by \_Travel
         fields ( TravelUUID )
         with corresponding #( keys )
         result data(travels).

    loop at travels into data(travel).

      read entities of z349_r_travel_lgl in local mode
           entity Travel by \_Booking
           fields ( BookingID )
           with value #( ( %tky = travel-%tky ) )
           result data(bookings).

      max_book_id = '0000'.

      loop at bookings into data(booking).
        if booking-BookingID > max_book_id.
          max_book_id = booking-BookingID.
        endif.
      endloop.

      loop at bookings into booking where BookingID is initial.
        max_book_id += 1.
        append value #( %tky     = booking-%tky
                        BookingID = max_book_id ) to bookinks_u.
      endloop.
    endloop.

    modify entities of z349_r_travel_lgl in local mode
           entity Booking
           update fields ( BookingID )
           with bookinks_u.

  endmethod.

  method validateConnection.
  endmethod.

  method validateCurrency.
  endmethod.

  method validateCustomer.

    data customers type sorted table of /dmo/customer with unique key client customer_id.

    read entities of z349_r_travel_lgl in local mode
         entity Booking
         fields (  CustomerID )
         with corresponding #( keys )
         result data(bookings).

    read entities of z349_r_travel_lgl in local mode
         entity Booking by \_Travel
         from corresponding #( bookings )
         link data(travel_booking_links).

    customers = corresponding #( bookings discarding duplicates mapping customer_id = CustomerID except * ).
    delete customers where customer_id is initial.


    if customers is not initial.

      select from /dmo/customer as db
             inner join @customers as it on db~customer_id = it~customer_id
             fields db~customer_id
             into table @data(valid_customers).

    endif.

    loop at bookings into data(booking).

      append value #( %tky        = booking-%tky
                      %state_area = 'VALIDATE_CUSTOMER' ) to reported-booking.

      if booking-CustomerID is initial.

        append value #( %tky = booking-%tky ) to failed-booking.

        append value #( %tky                = booking-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = new /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                                           severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on ) to reported-booking.

      elseif not line_exists( valid_customers[ customer_id = booking-CustomerID ] ).

        append value #( %tky = booking-%tky ) to failed-booking.

        append value #( %tky                = booking-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = new /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>customer_unkown
                                                                           customer_id = booking-CustomerID
                                                                           severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on ) to reported-booking.

      endif.

    endloop.


  endmethod.

  method validateFlightPrice.
  endmethod.

  method validateStatus.
  endmethod.

endclass.
