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

    methods precheck_update for precheck
      importing entities for update Travel.

    methods deductDiscount for modify
      importing keys for action Travel~deductDiscount result result.

    methods reCalcTotalPrice for modify
      importing keys for action Travel~reCalcTotalPrice.

    methods acceptTravel for modify
      importing keys for action Travel~acceptTravel result result.

    methods rejectTravel for modify
      importing keys for action Travel~rejectTravel result result.

    types:
      t_keys_accept   type table for action import z349_r_travel_lgl\\travel~acceptTravel,
      t_keys_reject   type table for action import z349_r_travel_lgl\\travel~rejectTravel,

      t_result_accept type table for action result z349_r_travel_lgl\\travel~acceptTravel,
      t_result_reject type table for action result z349_r_travel_lgl\\travel~rejectTravel.

    methods changeTravelStatus importing keys_accept   type t_keys_accept optional
                                         keys_reject   type t_keys_reject optional
                               exporting result_accept type t_result_accept
                                         result_reject type t_result_reject.

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

    types:
      t_entities_create type table for create z349_r_travel_lgl\\travel,
      t_entities_update type table for update z349_r_travel_lgl\\travel,
      t_failed_travel   type table for failed   early z349_r_travel_lgl\\travel,
      t_reported_travel type table for reported early z349_r_travel_lgl\\travel.

    methods precheck_auth
      importing
        entities_create type t_entities_create optional
        entities_update type t_entities_update optional
      changing
        failed          type t_failed_travel
        reported        type t_reported_travel.

    methods is_create_granted
      importing country_code          type land1 optional
      returning value(create_granted) type abap_bool.

    methods is_update_granted
      importing country_code          type land1 optional
      returning value(update_granted) type abap_bool.

    methods is_delete_granted
      importing country_code          type land1 optional
      returning value(delete_granted) type abap_bool.

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

    me->precheck_auth( exporting entities_create = entities
                       changing  failed          = failed-travel
                                 reported        = reported-travel ).

  endmethod.

  method precheck_update.

    me->precheck_auth( exporting entities_update = entities
                       changing  failed          = failed-travel
                                 reported        = reported-travel ).

  endmethod.

  method deductDiscount.

    data travels_for_update type table for update z349_r_travel_lgl.
    data(keys_with_valid_discount) = keys.

    loop at keys_with_valid_discount assigning field-symbol(<key_with_valid_discount>)
            where %param-discount_percent is initial
               or %param-discount_percent > 100
               or %param-discount_percent <= 0.

      append value #( %tky = <key_with_valid_discount>-%tky ) to failed-travel.

      append value #( %tky                       = <key_with_valid_discount>-%tky
                      %msg                       = new /dmo/cm_flight_messages(
                                                       textid = /dmo/cm_flight_messages=>discount_invalid
                                                       severity = if_abap_behv_message=>severity-error )
                      %element-TotalPrice        = if_abap_behv=>mk-on
                      %op-%action-deductDiscount = if_abap_behv=>mk-on
                    ) to reported-travel.

      delete keys_with_valid_discount.
    endloop.

    check keys_with_valid_discount is not initial.

    "get total price
    read entities of z349_r_travel_lgl in local mode
         entity Travel
         fields ( BookingFee )
         with corresponding #( keys_with_valid_discount )
         result data(travels).

    loop at travels assigning field-symbol(<travel>).
      data percentage type decfloat16.
      data(discount_percent) = keys_with_valid_discount[ key id  %tky = <travel>-%tky ]-%param-discount_percent.
      percentage =  discount_percent / 100 .
      data(reduced_fee) = <travel>-BookingFee * ( 1 - percentage ) .

      append value #( %tky       = <travel>-%tky
                      BookingFee = reduced_fee
                    ) to travels_for_update.
    endloop.

    "update total price with reduced price
    modify entities of z349_r_travel_lgl in local mode
      entity Travel
       update fields ( BookingFee )
       with travels_for_update.

    "Read changed data for action result
    read entities of z349_r_travel_lgl in local mode
      entity Travel
        all fields with
        corresponding #( travels )
      result data(travels_with_discount).

    result = value #( for travel in travels_with_discount ( %tky   = travel-%tky
                                                            %param = travel ) ).


  endmethod.

  method reCalcTotalPrice.

    types: begin of ty_amount_per_currencycode,
             amount        type /dmo/total_price,
             currency_code type /dmo/currency_code,
           end of ty_amount_per_currencycode.

    data: amount_per_currencycode type standard table of ty_amount_per_currencycode.

    read entities of z349_r_travel_lgl in local mode
         entity Travel
         fields ( BookingFee CurrencyCode )
         with corresponding #( keys )
         result data(travels).

    delete travels where CurrencyCode is initial.

    loop at travels assigning field-symbol(<travel>).

      " Set the start for the calculation by adding the booking fee.
      amount_per_currencycode = value #( ( amount        = <travel>-BookingFee
                                           currency_code = <travel>-CurrencyCode ) ).

      " Read all associated bookings
      read entities of z349_r_travel_lgl in local mode
           entity Travel by \_Booking
           fields ( FlightPrice CurrencyCode )
           with value #( ( %tky = <travel>-%tky ) )
           result data(bookings).

      " Add bookings to the total price.
      loop at bookings into data(booking) where CurrencyCode is not initial.
        collect value ty_amount_per_currencycode( amount        = booking-FlightPrice
                                                  currency_code = booking-CurrencyCode ) into amount_per_currencycode.
      endloop.

      " Read all associated booking supplements
      read entities of z349_r_travel_lgl in local mode
        entity Booking by \_BookingSupplement
          fields ( Price CurrencyCode )
        with value #( for rba_booking in bookings ( %tky = rba_booking-%tky ) )
        result data(bookingsupplements).

      " Add booking supplements to the total price.
      loop at bookingsupplements into data(bookingsupplement) where CurrencyCode is not initial.
        collect value ty_amount_per_currencycode( amount        = bookingsupplement-Price
                                                  currency_code = bookingsupplement-CurrencyCode ) into amount_per_currencycode.
      endloop.

      clear <travel>-TotalPrice.
      loop at amount_per_currencycode into data(single_amount_per_currencycode).
        " Currency Conversion
        if single_amount_per_currencycode-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += single_amount_per_currencycode-amount.
        else.
          /dmo/cl_flight_amdp=>convert_currency(
             exporting
               iv_amount                   =  single_amount_per_currencycode-amount
               iv_currency_code_source     =  single_amount_per_currencycode-currency_code
               iv_currency_code_target     =  <travel>-CurrencyCode
               iv_exchange_rate_date       =  cl_abap_context_info=>get_system_date( )
             importing
               ev_amount                   = data(total_booking_price_per_curr)
            ).
          <travel>-TotalPrice += total_booking_price_per_curr.
        endif.
      endloop.
    endloop.

    " update the modified total_price of travels
    modify entities of z349_r_travel_lgl in local mode
      entity travel
        update fields ( TotalPrice )
        with corresponding #( travels ).

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

  method changetravelstatus.

  endmethod.

  method Resume.

    data entities_update type t_entities_update.

    read entities of z349_r_travel_lgl in local mode
         entity Travel
         fields ( AgencyID )
         with value #( for key in keys
                        %is_draft = if_abap_behv=>mk-on
                        ( %key = key-%key )
                     )
         result data(travels).

    entities_update = corresponding #( travels changing control ).

    if entities_update is not initial.
      precheck_auth(
        exporting
          entities_update = entities_update
        changing
          failed          = failed-travel
          reported        = reported-travel
      ).
    endif.

  endmethod.

  method calculateTotalPrice.

    modify entities of z349_r_travel_lgl in local mode
           entity Travel
           execute reCalcTotalPrice
           from corresponding #( keys ).

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

    data: modification_granted type abap_boolean,
          agency_country_code  type land1.

    read entities of z349_r_travel_lgl in local mode
         entity Travel
         fields ( AgencyID
                  TravelID )
         with corresponding #( keys )
         result data(travels).

    data agencies type sorted table of /dmo/agency with unique key client agency_id.

    agencies = corresponding #( travels discarding duplicates mapping agency_id = AgencyID except * ).
    delete agencies where agency_id is initial.

    if agencies is not initial.

      select from /dmo/agency as db
             inner join @agencies as it on db~agency_id = it~agency_id
             fields db~agency_id,
                    db~country_code
             into table @data(valid_agencies).

    endif.

    loop at travels into data(travel).
      append value #(  %tky               = travel-%tky
                       %state_area        = 'VALIDATE_AGENCY'
                    ) to reported-travel.

      if travel-AgencyID is initial.
        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_AGENCY'
                        %msg                = new /dmo/cm_flight_messages(
                                                          textid   = /dmo/cm_flight_messages=>enter_agency_id
                                                          severity = if_abap_behv_message=>severity-error )
                        %element-AgencyID   = if_abap_behv=>mk-on
                       ) to reported-travel.

      elseif travel-AgencyID is not initial and not line_exists( valid_agencies[ agency_id = travel-AgencyID ] ).
        append value #(  %tky = travel-%tky ) to failed-travel.

        append value #(  %tky               = travel-%tky
                         %state_area        = 'VALIDATE_AGENCY'
                         %msg               = new /dmo/cm_flight_messages(
                                                                agency_id = travel-agencyid
                                                                textid    = /dmo/cm_flight_messages=>agency_unkown
                                                                severity  = if_abap_behv_message=>severity-error )
                         %element-AgencyID  = if_abap_behv=>mk-on
                      ) to reported-travel.
      endif.

    endloop.

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

    read entities of z349_r_travel_lgl in local mode
         entity Travel
         fields ( BeginDate
                  EndDate
                  TravelID )
         with corresponding #( keys )
         result data(travels).

    loop at travels into data(travel).

      append value #(  %tky         = travel-%tky
                       %state_area  = 'VALIDATE_DATES' ) to reported-travel.

      if travel-BeginDate is initial.
        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = new /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_begin_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) to reported-travel.
      endif.

      if travel-EndDate is initial.
        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg                = new /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_end_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-EndDate   = if_abap_behv=>mk-on ) to reported-travel.
      endif.

      if travel-EndDate < travel-BeginDate and travel-BeginDate is not initial
                                           and travel-EndDate is not initial.
        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = new /dmo/cm_flight_messages(
                                                                textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                                                begin_date = travel-BeginDate
                                                                end_date   = travel-EndDate
                                                                severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate   = if_abap_behv=>mk-on ) to reported-travel.
      endif.

      if travel-BeginDate < cl_abap_context_info=>get_system_date( ) and travel-BeginDate is not initial.
        append value #( %tky               = travel-%tky ) to failed-travel.

        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = new /dmo/cm_flight_messages(
                                                                begin_date = travel-BeginDate
                                                                textid     = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                                                severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) to reported-travel.
      endif.

    endloop.

  endmethod.

  method precheck_auth.

    data: entities          type t_entities_update,
          operation         type if_abap_behv=>t_char01,
          agencies          type sorted table of /dmo/agency with unique key client agency_id,
          is_modify_granted type abap_bool.

    " Either entities_create or entities_update is provided.  NOT both and at least one.
    assert not ( entities_create is initial equiv entities_update is initial ).

    if entities_create is not initial.
      entities = corresponding #( entities_create mapping %cid_ref = %cid ).
      operation = if_abap_behv=>op-m-create.
    else.
      entities = entities_update.
      operation = if_abap_behv=>op-m-update.
    endif.

    delete entities where %control-AgencyID = if_abap_behv=>mk-off.

    agencies = corresponding #( entities discarding duplicates mapping agency_id = AgencyID except * ).

    check agencies is not initial.

    select from /dmo/agency as db
           inner join @agencies as it on db~agency_id = it~agency_id
           fields db~agency_id,
                  db~country_code
           into table @data(agency_country_codes).

    loop at entities into data(entity).
      is_modify_granted = abap_false.

      read table agency_country_codes with key agency_id = entity-AgencyID
                   assigning field-symbol(<agency_country_code>).

      "If invalid or initial AgencyID -> validateAgency
      check sy-subrc = 0.

      case operation.

        when if_abap_behv=>op-m-create.
          is_modify_granted = is_create_granted( <agency_country_code>-country_code ).

        when if_abap_behv=>op-m-update.
          is_modify_granted = is_update_granted( <agency_country_code>-country_code ).

      endcase.

      if is_modify_granted = abap_false.
        append value #(
                         %cid      = cond #( when operation = if_abap_behv=>op-m-create then entity-%cid_ref )
                         %tky      = entity-%tky
                       ) to failed.

        append value #(
                         %cid      = cond #( when operation = if_abap_behv=>op-m-create then entity-%cid_ref )
                         %tky      = entity-%tky
                         %msg      = new /dmo/cm_flight_messages(
                                                 textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                 agency_id = entity-AgencyID
                                                 severity  = if_abap_behv_message=>severity-error )
                         %element-AgencyID   = if_abap_behv=>mk-on
                      ) to reported.
      endif.
    endloop.

  endmethod.

  method is_create_granted.

    if country_code is supplied.

      authority-check object '/DMO/TRVL'
                          id '/DMO/CNTRY' field country_code
                          id 'ACTVT'      field '01'.

      create_granted = cond #( when sy-subrc eq 0
                               then abap_true
                               else abap_false ).

    endif.

    "Giving Full Access
    create_granted = abap_true.

  endmethod.


  method is_update_granted.

    if country_code is supplied.

      authority-check object '/DMO/TRVL'
                          id '/DMO/CNTRY' field country_code
                          id 'ACTVT'      field '02'.

      update_granted = cond #( when sy-subrc eq 0
                               then abap_true
                               else abap_false ).

    endif.

    "Giving Full Access
    update_granted = abap_true.

  endmethod.

  method is_delete_granted.

    if country_code is supplied.

      authority-check object '/DMO/TRVL'
                          id '/DMO/CNTRY' field country_code
                          id 'ACTVT'      field '06'.

      delete_granted = cond #( when sy-subrc eq 0
                               then abap_true
                               else abap_false ).

    endif.

    "Giving Full Access
    delete_granted = abap_true.

  endmethod.



endclass.
