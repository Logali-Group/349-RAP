class lhc_Travel definition inheriting from cl_abap_behavior_handler.
  private section.

    constants:
      begin of travel_status,
        open     type c length 1 value 'O',
        accepted type c length 1 value 'A',
        rejected type c length 1 value 'X',
      end of travel_status.

    methods get_instance_features for instance features
      importing keys request requested_features for Travel result result.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for Travel result result.

    methods get_global_authorizations for global authorization
      importing request requested_authorizations for Travel result result.

    methods precheck_create for precheck
      importing entities for create Travel.

    methods deductDiscount for modify
      importing keys for action Travel~deductDiscount result result.

    methods reCalcTotalPrice for modify
      importing keys for action Travel~reCalcTotalPrice.

    methods acceptTravel for modify
      importing keys for action Travel~acceptTravel result result.

    methods rejectTravel for modify
      importing keys for action Travel~rejectTravel result result.

    methods Resume for modify
      importing keys for action Travel~Resume.

    methods calculateTotalPrice for determine on modify
      importing keys for Travel~calculateTotalPrice.

    methods setStatusToOpen for determine on modify
      importing keys for Travel~setStatusToOpen.

    methods setTravelNumber for determine on save
      importing keys for Travel~setTravelNumber.

    methods validateAgency for validate on save
      importing keys for Travel~validateAgency.

    methods validateBookingFee for validate on save
      importing keys for Travel~validateBookingFee.

    methods validateCurrency for validate on save
      importing keys for Travel~validateCurrency.

    methods validateCustomer for validate on save
      importing keys for Travel~validateCustomer.

    methods validateDates for validate on save
      importing keys for Travel~validateDates.



endclass.

class lhc_Travel implementation.

  method get_instance_features.

    read entities of z349_r_travel_lgl in local mode
           entity Travel
           fields ( OverallStatus )
           with corresponding #( keys )
           result data(travels).

    result = value #( for travel in travels ( %tky              =  travel-%tky
                                              %field-BookingFee = cond #( when travel-OverallStatus = travel_status-accepted
                                                                          then if_abap_behv=>fc-f-read_only
                                                                          else if_abap_behv=>fc-f-unrestricted )
                                              %action-acceptTravel = cond #( when travel-OverallStatus = travel_status-accepted
                                                                          then if_abap_behv=>fc-o-disabled
                                                                          else if_abap_behv=>fc-o-enabled )
                                              %action-rejectTravel = cond #( when travel-OverallStatus = travel_status-rejected
                                                                          then if_abap_behv=>fc-o-disabled
                                                                          else if_abap_behv=>fc-o-enabled )
                                              %action-deductDiscount = cond #( when travel-OverallStatus = travel_status-accepted
                                                                          then if_abap_behv=>fc-o-disabled
                                                                          else if_abap_behv=>fc-o-enabled )
                                              %assoc-_Booking = cond #( when travel-OverallStatus = travel_status-rejected
                                                                          then if_abap_behv=>fc-o-disabled
                                                                          else if_abap_behv=>fc-o-enabled ) ) ).


  endmethod.

  method get_instance_authorizations.

    " NOTHING to do with the CREATE operation
    data: update_requested type abap_bool,
          update_granted   type abap_bool,
          delete_requested type abap_bool,
          delete_granted   type abap_bool.

    read entities of z349_r_travel_lgl in local mode
          entity Travel
          fields ( AgencyID )
          with corresponding #( keys )
          result data(travels).

    update_requested  = cond #( when requested_authorizations-%update      = if_abap_behv=>mk-on
                                  or requested_authorizations-%action-Edit = if_abap_behv=>mk-on
                                then abap_true
                                else abap_false ).


    delete_requested  = cond #( when requested_authorizations-%delete = if_abap_behv=>mk-on
                                then abap_true
                                else abap_false ).

    data(lv_technical_name) = cl_abap_context_info=>get_user_technical_name(  ).

    loop at travels into data(travel). "70014


      if travel-AgencyID is not initial.

        if update_requested eq abap_true.

          if lv_technical_name = 'CB9980000785' and travel-AgencyID ne '70014'.
            update_granted = abap_true.
          else .

            update_granted = abap_false.

            append value #( %tky = travel-%tky
                            %msg = new /dmo/cm_flight_messages( textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                                agency_id = travel-AgencyID
                                                                severity  = if_abap_behv_message=>severity-error )
                            %element-AgencyID = if_abap_behv=>mk-on ) to reported-travel.

          endif.
        endif.

        if delete_requested eq abap_true.

          if lv_technical_name = 'CB9980000785' and travel-AgencyID ne '70014'.
            delete_granted = abap_true.
          else .

            delete_granted = abap_false.

            append value #( %tky = travel-%tky
                            %msg = new /dmo/cm_flight_messages( textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                                agency_id = travel-AgencyID
                                                                severity  = if_abap_behv_message=>severity-error )
                            %element-AgencyID = if_abap_behv=>mk-on ) to reported-travel.

          endif.
        endif.

*      else.
*
*        if lv_technical_name = 'CB9980000785'.
*           update_granted = abap_true.
*        endif.

      endif.

      append value #( let upd_auth = cond #( when update_granted eq abap_true
                                             then if_abap_behv=>auth-allowed
                                             else if_abap_behv=>auth-unauthorized )
                          del_auth = cond #( when delete_granted eq abap_true
                                             then if_abap_behv=>auth-allowed
                                             else if_abap_behv=>auth-unauthorized )
                      in
                          %tky         = travel-%tky
                          %update      = upd_auth
                          %action-Edit = upd_auth
                          %delete      = del_auth ) to result.

    endloop.

  endmethod.

  method get_global_authorizations.

    check 1 = 2. "DELETE ME

    data(lv_technical_name) = cl_abap_context_info=>get_user_technical_name(  ).

    "lv_technical_name = 'DIFFERENT'.

    if requested_authorizations-%create eq if_abap_behv=>mk-on.

      if lv_technical_name = 'CB9980000785'.
        result-%create = if_abap_behv=>auth-allowed.
      else.
        result-%create = if_abap_behv=>auth-unauthorized.

        append value #( %msg     = new /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>not_authorized
                                                                            severity = if_abap_behv_message=>severity-error )
                         %global = if_abap_behv=>mk-on ) to reported-travel.

      endif.

    endif.

    if requested_authorizations-%update      eq if_abap_behv=>mk-on or
       requested_authorizations-%action-Edit eq if_abap_behv=>mk-on.

      if lv_technical_name = 'CB9980000785'.
        result-%update      = if_abap_behv=>auth-allowed.
        result-%action-Edit = if_abap_behv=>auth-allowed.
      else.
        result-%update      = if_abap_behv=>auth-unauthorized.
        result-%action-Edit = if_abap_behv=>auth-unauthorized.

        append value #( %msg     = new /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>not_authorized
                                                                            severity = if_abap_behv_message=>severity-error )
                         %global = if_abap_behv=>mk-on ) to reported-travel.

      endif.

    endif.

    if requested_authorizations-%delete eq if_abap_behv=>mk-on.

      if lv_technical_name = 'CB9980000785'.
        result-%delete = if_abap_behv=>auth-allowed.
      else.
        result-%delete = if_abap_behv=>auth-unauthorized.

        append value #( %msg     = new /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>not_authorized
                                                                            severity = if_abap_behv_message=>severity-error )
                         %global = if_abap_behv=>mk-on ) to reported-travel.

      endif.

    endif.


  endmethod.

  method precheck_create.
  endmethod.

  method deductDiscount.
  endmethod.

  method reCalcTotalPrice.
  endmethod.

  method rejectTravel.

    modify entities of z349_r_travel_lgl in local mode
         entity Travel
         update fields ( OverallStatus )
         with value #( for key in keys ( %tky           = key-%tky
                                          OverallStatus = travel_status-rejected ) ).

    read entities of  z349_r_travel_lgl in local mode
         entity Travel
         all fields with
         corresponding #( keys )
         result data(travels).

    result = value #( for travel in travels ( %tky   = travel-%tky
                                              %param = travel ) ).

  endmethod.

  method Resume.
  endmethod.

  method calculateTotalPrice.
  endmethod.

  method setStatusToOpen.

    read entities of z349_r_travel_lgl in local mode
          entity Travel
          fields ( OverallStatus )
          with corresponding #( keys )
          result data(travels).

    delete travels where OverallStatus is not initial.

    check travels is not initial.

    modify entities of z349_r_travel_lgl in local mode
           entity Travel
           update fields ( OverallStatus )
           with value #( for travel in travels ( %tky          = travel-%tky
                                                 OverallStatus = travel_status-open ) ).

  endmethod.

  method setTravelNumber.

    read entities of z349_r_travel_lgl in local mode
         entity Travel
         fields ( TravelID )
         with corresponding #( keys )
         result data(travels).

    delete travels where TravelID is not initial.

    check travels is not initial.

    select single from z349_travel_a
           fields max( travel_id )
           into @data(max_TravelId).

    modify entities of z349_r_travel_lgl in local mode
           entity Travel
           update fields ( TravelID )
           with value #( for travel in travels index into i ( %tky     = travel-%tky
                                                              TravelID = max_TravelId + i ) ).

  endmethod.

  method validateAgency.
  endmethod.

  method validateBookingFee.
  endmethod.

  method validateCurrency.
  endmethod.

  method validateCustomer.

    data customers type sorted table of /dmo/customer with unique key client customer_id.

    read entities of z349_r_travel_lgl in local mode
           entity Travel
           fields ( CustomerID )
           with corresponding #( keys )
           result data(travels).

    customers = corresponding #( travels discarding duplicates mapping customer_id = CustomerID except * ).
    delete customers where customer_id is initial.


    if customers is not initial.

      select from /dmo/customer as db
             inner join @customers as it on db~customer_id = it~customer_id
             fields db~customer_id
             into table @data(valid_customers).

    endif.

    loop at travels into data(travel).

      append value #( %tky        = travel-%tky
                      %state_area = 'VALIDATE_CUSTOMER' ) to reported-travel.

      if travel-CustomerID is initial.

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = new /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                                           severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on ) to reported-travel.

      elseif not line_exists( valid_customers[ customer_id = travel-CustomerID ] ).

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = new /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>customer_unkown
                                                                           customer_id = travel-CustomerID
                                                                           severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on ) to reported-travel.

      endif.

    endloop.


  endmethod.

  method validateDates.
  endmethod.

  method acceptTravel.

    modify entities of z349_r_travel_lgl in local mode
           entity Travel
           update fields ( OverallStatus )
           with value #( for key in keys ( %tky           = key-%tky
                                            OverallStatus = travel_status-accepted ) ).

    read entities of  z349_r_travel_lgl in local mode
         entity Travel
         all fields with
         corresponding #( keys )
         result data(travels).

    result = value #( for travel in travels ( %tky   = travel-%tky
                                              %param = travel ) ).

  endmethod.

endclass.
