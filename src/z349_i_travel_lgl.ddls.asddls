@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel - Interface Entity'
@Metadata.ignorePropagatedAnnotations: true
define root view entity z349_i_travel_lgl
  provider contract transactional_interface
  as projection on z349_r_travel_lgl
{
  key TravelUUID,
      TravelID,
      AgencyID,
      CustomerID,
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      CurrencyCode,
      Description,
      OverallStatus,
      
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      LastChangedAt,
      
      /* Associations */
      _Agency,
      _Booking : redirected to composition child z349_i_booking_lgl,
      _Currency,
      _Customer,
      _OverallStatus
}
