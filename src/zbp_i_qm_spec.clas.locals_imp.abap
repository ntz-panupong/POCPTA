CLASS lhc_specheader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR SpecHeader RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR SpecHeader RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE SpecHeader.

    METHODS earlynumbering_cba_item FOR NUMBERING
      IMPORTING entities FOR CREATE SpecHeader\_Item.

    METHODS validateheader FOR VALIDATE ON SAVE
      IMPORTING keys FOR SpecHeader~ValidateHeader.

    METHODS newversion FOR MODIFY
      IMPORTING keys FOR ACTION SpecHeader~NewVersion RESULT result.

    METHODS copy FOR MODIFY
      IMPORTING keys FOR ACTION SpecHeader~Copy RESULT result.

    METHODS print FOR MODIFY
      IMPORTING keys FOR ACTION SpecHeader~Print RESULT result.
ENDCLASS.

CLASS lhc_specheader IMPLEMENTATION.
  METHOD get_global_authorizations.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
    result-%action-NewVersion = if_abap_behv=>auth-allowed.
    result-%action-Copy       = if_abap_behv=>auth-allowed.
    result-%action-Print      = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zi_qm_spec IN LOCAL MODE
      ENTITY SpecHeader
      FIELDS ( DocNo Version )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_headers).

    result = VALUE #( FOR ls_hdr IN lt_headers (
      %tky                   = ls_hdr-%tky
      %action-NewVersion     = COND #( WHEN ls_hdr-%is_draft = if_abap_behv=>mk-off
                                       THEN if_abap_behv=>fc-o-enabled
                                       ELSE if_abap_behv=>fc-o-disabled )
      %action-Copy           = COND #( WHEN ls_hdr-%is_draft = if_abap_behv=>mk-off
                                       THEN if_abap_behv=>fc-o-enabled
                                       ELSE if_abap_behv=>fc-o-disabled )
      %action-Print          = COND #( WHEN ls_hdr-%is_draft = if_abap_behv=>mk-off
                                       THEN if_abap_behv=>fc-o-enabled
                                       ELSE if_abap_behv=>fc-o-disabled )
    ) ).
  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA(lo_helper) = NEW zcl_qm_spec_action( ).
    DATA(lv_next_doc) = lo_helper->get_next_doc_no( ).

    LOOP AT entities INTO DATA(ls_entity).
      IF ls_entity-DocNo IS INITIAL.
        APPEND VALUE #(
          %cid      = ls_entity-%cid
          %is_draft = ls_entity-%is_draft
          DocNo     = lv_next_doc
          Version   = '001'
        ) TO mapped-specheader.
        lv_next_doc = CONV zelm_qm_spec_docno( lv_next_doc + 1 ).
      ELSE.
        APPEND VALUE #(
          %cid      = ls_entity-%cid
          %is_draft = ls_entity-%is_draft
          DocNo     = ls_entity-DocNo
          Version   = COND #( WHEN ls_entity-Version IS INITIAL THEN '001' ELSE ls_entity-Version )
        ) TO mapped-specheader.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_item.
    DATA(lo_helper) = NEW zcl_qm_spec_action( ).

    LOOP AT entities INTO DATA(ls_parent).
      DATA(lv_next_sec)  = lo_helper->get_next_section_no( iv_doc_no = ls_parent-DocNo iv_version = ls_parent-Version ).
      DATA(lv_next_line) = lo_helper->get_next_line_no( iv_doc_no = ls_parent-DocNo iv_version = ls_parent-Version ).

      LOOP AT ls_parent-%target INTO DATA(ls_target).
        APPEND VALUE #(
          %cid      = ls_target-%cid
          %is_draft = ls_target-%is_draft
          DocNo     = ls_parent-DocNo
          Version   = ls_parent-Version
          SectionNo = COND #( WHEN ls_target-SectionNo IS INITIAL THEN lv_next_sec ELSE ls_target-SectionNo )
          LineNo    = COND #( WHEN ls_target-LineNo IS INITIAL THEN lv_next_line ELSE ls_target-LineNo )
        ) TO mapped-specitem.
        lv_next_line = CONV zelm_qm_spec_lineno( lv_next_line + 1 ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD ValidateHeader.
    READ ENTITIES OF zi_qm_spec IN LOCAL MODE
      ENTITY SpecHeader
      FIELDS ( ProductCode ProductName ImageContent )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_headers).

    LOOP AT lt_headers INTO DATA(ls_hdr).
      APPEND VALUE #( %tky = ls_hdr-%tky %state_area = 'VALIDATE_HEADER' ) TO reported-specheader.

      IF ls_hdr-ProductCode IS INITIAL OR ls_hdr-ProductName IS INITIAL.
        APPEND VALUE #( %tky = ls_hdr-%tky ) TO failed-specheader.
        APPEND VALUE #(
          %tky                 = ls_hdr-%tky
          %state_area          = 'VALIDATE_HEADER'
          %msg                 = new_message(
            id       = 'ZQM_SPEC'
            number   = '001'
            severity = if_abap_behv_message=>severity-error
          )
          %element-productcode = COND #( WHEN ls_hdr-ProductCode IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-productname = COND #( WHEN ls_hdr-ProductName IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
        ) TO reported-specheader.
      ENDIF.

      " Image size limit: 2 MB (2,097,152 bytes)
      IF ls_hdr-ImageContent IS NOT INITIAL AND xstrlen( ls_hdr-ImageContent ) > 2097152.
        APPEND VALUE #( %tky = ls_hdr-%tky ) TO failed-specheader.
        APPEND VALUE #(
          %tky                  = ls_hdr-%tky
          %state_area           = 'VALIDATE_HEADER'
          %msg                  = new_message(
            id       = 'ZQM_SPEC'
            number   = '003'
            severity = if_abap_behv_message=>severity-error
          )
          %element-imagecontent = if_abap_behv=>mk-on
        ) TO reported-specheader.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD NewVersion.
    DATA(lo_helper) = NEW zcl_qm_spec_action( ).
    lo_helper->create_new_version(
      EXPORTING
        it_keys     = CORRESPONDING #( keys )
      CHANGING
        ct_result   = result
        ct_failed   = failed-specheader
        ct_reported = reported-specheader
    ).
  ENDMETHOD.

  METHOD Copy.
    DATA(lo_helper) = NEW zcl_qm_spec_action( ).
    lo_helper->copy_specification(
      EXPORTING
        it_keys     = CORRESPONDING #( keys )
      CHANGING
        ct_result   = result
        ct_failed   = failed-specheader
        ct_reported = reported-specheader
    ).
  ENDMETHOD.

  METHOD Print.
    READ ENTITIES OF zi_qm_spec IN LOCAL MODE
      ENTITY SpecHeader
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_headers).

    LOOP AT lt_headers INTO DATA(ls_hdr).
      APPEND VALUE #( %tky = ls_hdr-%tky %param = ls_hdr ) TO result.
      APPEND VALUE #(
        %tky = ls_hdr-%tky
        %msg = new_message(
          id       = 'ZQM_SPEC'
          number   = '006'
          severity = if_abap_behv_message=>severity-success
          v1       = ls_hdr-DocNo
          v2       = ls_hdr-Version
        )
      ) TO reported-specheader.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_specitem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateitem FOR VALIDATE ON SAVE
      IMPORTING keys FOR SpecItem~ValidateItem.
ENDCLASS.

CLASS lhc_specitem IMPLEMENTATION.
  METHOD ValidateItem.
    READ ENTITIES OF zi_qm_spec IN LOCAL MODE
      ENTITY SpecItem
      FIELDS ( SectionTitle )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    LOOP AT lt_items INTO DATA(ls_item).
      APPEND VALUE #( %tky = ls_item-%tky %state_area = 'VALIDATE_ITEM' ) TO reported-specitem.

      IF ls_item-SectionTitle IS INITIAL.
        APPEND VALUE #( %tky = ls_item-%tky ) TO failed-specitem.
        APPEND VALUE #(
          %tky                  = ls_item-%tky
          %state_area           = 'VALIDATE_ITEM'
          %msg                  = new_message(
            id       = 'ZQM_SPEC'
            number   = '002'
            severity = if_abap_behv_message=>severity-error
          )
          %element-sectiontitle = if_abap_behv=>mk-on
        ) TO reported-specitem.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_qm_spec DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
    METHODS cleanup       REDEFINITION.
ENDCLASS.

CLASS lsc_zi_qm_spec IMPLEMENTATION.
  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.
ENDCLASS.
