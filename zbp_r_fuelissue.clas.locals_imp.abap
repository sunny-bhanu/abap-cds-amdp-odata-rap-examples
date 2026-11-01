"! Local handler class of behavior pool ZBP_R_FUELISSUE
"! (file: zbp_r_fuelissue.clas.locals_imp.abap)
CLASS lhc_fuelissue DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF gc_status,
        new    TYPE c LENGTH 1 VALUE 'N',
        posted TYPE c LENGTH 1 VALUE 'P',
      END OF gc_status.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR FuelIssue RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR FuelIssue RESULT result.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE FuelIssue.

    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR FuelIssue~setInitialStatus.
    METHODS validatePlant FOR VALIDATE ON SAVE
      IMPORTING keys FOR FuelIssue~validatePlant.
    METHODS validateQuantity FOR VALIDATE ON SAVE
      IMPORTING keys FOR FuelIssue~validateQuantity.

    METHODS post FOR MODIFY
      IMPORTING keys FOR ACTION FuelIssue~post RESULT result.
ENDCLASS.


CLASS lhc_fuelissue IMPLEMENTATION.

  METHOD get_instance_authorizations.
    " Authorisation object check per plant, e.g. M_MSEG_WWA
    " (left generic in this reference implementation)
  ENDMETHOD.


  METHOD get_instance_features.
    READ ENTITIES OF zr_fuelissue IN LOCAL MODE
      ENTITY FuelIssue
        FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr).

    result = VALUE #( FOR ls_hdr IN lt_hdr
                      ( %tky = ls_hdr-%tky
                        %action-post = COND #( WHEN ls_hdr-Status = gc_status-new
                                               THEN if_abap_behv=>fc-o-enabled
                                               ELSE if_abap_behv=>fc-o-disabled ) ) ).
  ENDMETHOD.


  METHOD earlynumbering_create.
    " Number range object ZFUEL, interval 01 — read through the released
    " API cl_numberrange_runtime rather than NUMBER_GET_NEXT.
    LOOP AT entities INTO DATA(ls_entity) WHERE FuelIssueId IS INITIAL.
      TRY.
          cl_numberrange_runtime=>number_get(
            EXPORTING nr_range_nr = '01'
                      object      = 'ZFUEL'
            IMPORTING number      = DATA(lv_number) ).
          APPEND VALUE #( %cid        = ls_entity-%cid
                          %is_draft   = ls_entity-%is_draft
                          FuelIssueId = lv_number ) TO mapped-fuelissue.
        CATCH cx_number_ranges INTO DATA(lx_nr).
          APPEND VALUE #( %cid = ls_entity-%cid %is_draft = ls_entity-%is_draft )
                 TO failed-fuelissue.
          APPEND VALUE #( %cid = ls_entity-%cid %is_draft = ls_entity-%is_draft
                          %msg = lx_nr ) TO reported-fuelissue.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD setInitialStatus.
    READ ENTITIES OF zr_fuelissue IN LOCAL MODE
      ENTITY FuelIssue FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr).

    DELETE lt_hdr WHERE Status IS NOT INITIAL.
    IF lt_hdr IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_fuelissue IN LOCAL MODE
      ENTITY FuelIssue
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR ls_hdr IN lt_hdr
                      ( %tky = ls_hdr-%tky Status = gc_status-new ) ).
  ENDMETHOD.


  METHOD validatePlant.
    READ ENTITIES OF zr_fuelissue IN LOCAL MODE
      ENTITY FuelIssue FIELDS ( Plant ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr).

    SELECT plant FROM i_plant
      FOR ALL ENTRIES IN @lt_hdr
      WHERE plant = @lt_hdr-Plant
      INTO TABLE @DATA(lt_plant).

    LOOP AT lt_hdr INTO DATA(ls_hdr).
      IF NOT line_exists( lt_plant[ plant = ls_hdr-Plant ] ).
        APPEND VALUE #( %tky = ls_hdr-%tky ) TO failed-fuelissue.
        APPEND VALUE #( %tky = ls_hdr-%tky
                        %msg = new_message( id       = 'ZPM'
                                            number   = '010'
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = ls_hdr-Plant )
                        %element-Plant = if_abap_behv=>mk-on ) TO reported-fuelissue.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateQuantity.
    READ ENTITIES OF zr_fuelissue IN LOCAL MODE
      ENTITY FuelIssue FIELDS ( TotalQuantity ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr).

    LOOP AT lt_hdr INTO DATA(ls_hdr) WHERE TotalQuantity <= 0.
      APPEND VALUE #( %tky = ls_hdr-%tky ) TO failed-fuelissue.
      APPEND VALUE #( %tky = ls_hdr-%tky
                      %msg = new_message( id       = 'ZPM'
                                          number   = '011'
                                          severity = if_abap_behv_message=>severity-error )
                      %element-TotalQuantity = if_abap_behv=>mk-on ) TO reported-fuelissue.
    ENDLOOP.
  ENDMETHOD.


  METHOD post.
    " Goods issue (movement type 261) against the maintenance order.
    " In a RAP managed scenario the actual BAPI call belongs in the
    " SAVE sequence (unmanaged save / additional save) so that it runs
    " inside the RAP LUW. Here the action only flips the status and
    " records the intent; see zbp_r_fuelissue.clas.locals_imp.abap
    " (lsc_fuelissue=>save_modified) in the full implementation.
    MODIFY ENTITIES OF zr_fuelissue IN LOCAL MODE
      ENTITY FuelIssue
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR ls_key IN keys
                      ( %tky = ls_key-%tky Status = gc_status-posted ) ).

    READ ENTITIES OF zr_fuelissue IN LOCAL MODE
      ENTITY FuelIssue ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_hdr).

    result = VALUE #( FOR ls_hdr IN lt_hdr
                      ( %tky = ls_hdr-%tky %param = ls_hdr ) ).
  ENDMETHOD.

ENDCLASS.
