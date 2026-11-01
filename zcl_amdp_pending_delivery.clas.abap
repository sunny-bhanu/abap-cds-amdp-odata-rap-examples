"! <p class="shorttext synchronized">AMDP: pending delivery quantity per sales order item</p>
"! Implements CDS table function ZTF_PENDING_DELIVERY.
"! Code push-down to HANA SQLScript for logic that is awkward in CDS
"! (aggregation across header/item/schedule-line with COALESCE and a
"! parameterised cut-off date).
CLASS zcl_amdp_pending_delivery DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.

    CLASS-METHODS get_pending
      FOR TABLE FUNCTION ztf_pending_delivery.
ENDCLASS.



CLASS zcl_amdp_pending_delivery IMPLEMENTATION.

  METHOD get_pending
    BY DATABASE FUNCTION FOR HDB
    LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY
    USING vbak vbap vbep lips.

    RETURN
      SELECT
             :p_clnt                                AS mandt,
             h.vbeln                                AS salesorder,
             i.posnr                                AS salesorderitem,
             i.matnr                                AS material,
             i.werks                                AS plant,
             SUM( e.wmeng )                         AS confirmedqty,
             COALESCE( d.delivered_qty, 0 )         AS deliveredqty,
             SUM( e.wmeng ) - COALESCE( d.delivered_qty, 0 )
                                                    AS pendingqty,
             i.vrkme                                AS quantityunit,
             MIN( e.edatu )                         AS firstconfirmeddate
        FROM vbak AS h
        INNER JOIN vbap AS i
          ON  i.mandt = h.mandt
          AND i.vbeln = h.vbeln
        INNER JOIN vbep AS e
          ON  e.mandt = i.mandt
          AND e.vbeln = i.vbeln
          AND e.posnr = i.posnr
        LEFT OUTER JOIN (
               SELECT mandt, vgbel, vgpos, SUM( lfimg ) AS delivered_qty
                 FROM lips
                WHERE mandt = :p_clnt
                GROUP BY mandt, vgbel, vgpos ) AS d
          ON  d.mandt = i.mandt
          AND d.vgbel = i.vbeln
          AND d.vgpos = i.posnr
       WHERE h.mandt  = :p_clnt
         AND h.vbtyp  = 'C'                 -- standard orders only
         AND e.edatu <= :p_cutoff_date
         AND i.abgru  = ''                  -- not rejected
       GROUP BY h.vbeln, i.posnr, i.matnr, i.werks, i.vrkme, d.delivered_qty
      HAVING SUM( e.wmeng ) - COALESCE( d.delivered_qty, 0 ) > 0;

  ENDMETHOD.

ENDCLASS.
