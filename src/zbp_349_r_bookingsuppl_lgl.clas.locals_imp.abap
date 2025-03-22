class lhc_BookingSupplement definition inheriting from cl_abap_behavior_handler.
  private section.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for BookingSupplement result result.

    methods get_global_authorizations for global authorization
      importing request requested_authorizations for BookingSupplement result result.

    methods calculateTotalPrice for determine on modify
      importing keys for BookingSupplement~calculateTotalPrice.

    methods setBookSupplNumber for determine on modify
      importing keys for BookingSupplement~setBookSupplNumber.

    methods validateCurrency for validate on save
      importing keys for BookingSupplement~validateCurrency.

    methods validatePrice for validate on save
      importing keys for BookingSupplement~validatePrice.

    methods validateSupplement for validate on save
      importing keys for BookingSupplement~validateSupplement.

endclass.

class lhc_BookingSupplement implementation.

  method get_instance_authorizations.
  endmethod.

  method get_global_authorizations.
  endmethod.

  method calculateTotalPrice.
  endmethod.

  method setBookSupplNumber.

    data: bookingsupplements_u type table for update z349_r_travel_lgl\\BookingSupplement,
          max_bookingsuppl_id  type /dmo/booking_supplement_id.

    read entities of z349_r_travel_lgl in local mode
      entity BookingSupplement by \_Booking
        fields (  BookingUUID  )
        with corresponding #( keys )
      result data(bookings).

    loop at bookings into data(ls_booking).
      read entities of z349_r_travel_lgl in local mode
        entity Booking by \_BookingSupplement
          fields ( BookingSupplementID )
          with value #( ( %tky = ls_booking-%tky ) )
        result data(bookingsupplements).

      " max bookingID
      max_bookingsuppl_id = '00'.
      loop at bookingsupplements into data(bookingsupplement).
        if bookingsupplement-BookingSupplementID > max_bookingsuppl_id.
          max_bookingsuppl_id = bookingsupplement-BookingSupplementID.
        endif.
      endloop.

      "Provide a booking supplement ID for all booking supplement of this booking that have none.
      loop at bookingsupplements into bookingsupplement where BookingSupplementID is initial.
        max_bookingsuppl_id += 1.
        append value #( %tky                = bookingsupplement-%tky
                        bookingsupplementid = max_bookingsuppl_id
                      ) to bookingsupplements_u.

      endloop.
    endloop.

    modify entities of z349_r_travel_lgl in local mode
      entity BookingSupplement
        update fields ( BookingSupplementID ) with bookingsupplements_u.

  endmethod.

  method validateCurrency.
  endmethod.

  method validatePrice.
  endmethod.

  method validateSupplement.
  endmethod.

endclass.
