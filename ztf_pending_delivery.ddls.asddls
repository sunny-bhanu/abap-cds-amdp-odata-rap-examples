@EndUserText.label: 'Pending delivery qty per SO item (table function)'
@ClientHandling.type: #CLIENT_DEPENDENT
@ClientHandling.algorithm: #SESSION_VARIABLE
define table function ZTF_PENDING_DELIVERY
  with parameters
    @Environment.systemField: #CLIENT
    p_clnt        : abap.clnt,
    p_cutoff_date : abap.dats
returns
{
  mandt              : abap.clnt;
  salesorder         : vbeln_va;
  salesorderitem     : posnr_va;
  material           : matnr;
  plant              : werks_d;
  confirmedqty       : wmeng;
  deliveredqty       : lfimg;
  pendingqty         : wmeng;
  quantityunit       : vrkme;
  firstconfirmeddate : edatu;
}
implemented by method zcl_amdp_pending_delivery=>get_pending;
