@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Sales Order Net Value by Item (interface view)'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory: #L,
  dataClass: #TRANSACTIONAL
}
define view entity ZI_SalesOrder_NetValue
  as select from I_SalesOrderItem as Item

  association [1..1] to I_SalesOrder as _Header
    on $projection.SalesOrder = _Header.SalesOrder

  association [0..1] to I_Product as _Product
    on $projection.Material = _Product.Product

{
  key Item.SalesOrder,
  key Item.SalesOrderItem,
      Item.Material,
      Item.RequestedQuantity,
      Item.RequestedQuantityUnit,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      Item.NetAmount,

      @Semantics.currencyCode: true
      Item.TransactionCurrency,

      _Header.SoldToParty,
      _Header.SalesOrganization,
      _Header.CreationDate,

      // Derived classification — CASE expression
      case
        when Item.NetAmount >= 100000 then 'A'
        when Item.NetAmount >=  10000 then 'B'
        else                               'C'
      end                                   as ValueClass,

      // Arithmetic in CDS: unit price (guarded against zero quantity)
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case
        when Item.RequestedQuantity = 0 then cast( 0 as abap.curr(15,2) )
        else cast( division( Item.NetAmount,
                             Item.RequestedQuantity, 2 ) as abap.curr(15,2) )
      end                                   as UnitNetPrice,

      // Open delivery indicator from a released association
      case Item.DeliveryStatus
        when 'C' then 'Delivered'
        when 'B' then 'Partially delivered'
        else         'Open'
      end                                   as DeliveryStatusText,

      /* Associations exposed for consumers */
      _Header,
      _Product
}
