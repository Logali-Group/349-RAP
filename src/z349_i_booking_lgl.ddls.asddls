@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking - Interface Entity'
@Metadata.ignorePropagatedAnnotations: true
define view entity z349_i_booking_lgl
  as projection on z349_r_booking_lgl
{
  key BookingUUID,
      TravelUUID,
      BookingID,
      BookingDate,
      CustomerID,
      AirlineID,
      ConnectionID,
      FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,
      CurrencyCode,
      BookingStatus,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      /* Associations */
      _BookingStatus,
      _BookingSupplement : redirected to composition child z349_i_bookingsuppl_lgl,
      _Carrier,
      _Connection,
      _Customer,
      _Travel : redirected to parent z349_i_travel_lgl
}
