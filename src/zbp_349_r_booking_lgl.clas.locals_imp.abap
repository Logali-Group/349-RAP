class lhc_Booking definition inheriting from cl_abap_behavior_handler.
  private section.

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
  endmethod.

  method setBookingDate.
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
  endmethod.

  method validateFlightPrice.
  endmethod.

  method validateStatus.
  endmethod.

endclass.
