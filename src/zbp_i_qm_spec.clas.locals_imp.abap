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

    METHODS addsection FOR MODIFY
      IMPORTING keys FOR ACTION SpecHeader~AddSection RESULT result.
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
      %action-AddSection     = COND #( WHEN ls_hdr-%is_draft = if_abap_behv=>mk-on
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
    LOOP AT entities INTO DATA(ls_parent).
      READ ENTITIES OF zi_qm_spec IN LOCAL MODE
        ENTITY SpecHeader BY \_Item
        FIELDS ( SectionNo LineNo )
        WITH VALUE #( ( %tky = ls_parent-%tky ) )
        RESULT DATA(lt_existing_items).

      DATA lv_max_sec TYPE zelm_qm_spec_secno.
      CLEAR lv_max_sec.
      LOOP AT lt_existing_items INTO DATA(ls_exist).
        IF ls_exist-SectionNo > lv_max_sec.
          lv_max_sec = ls_exist-SectionNo.
        ENDIF.
      ENDLOOP.
      DATA(lv_next_sec) = COND zelm_qm_spec_secno(
        WHEN lv_max_sec IS INITIAL THEN '001'
        ELSE CONV zelm_qm_spec_secno( lv_max_sec + 1 ) ).

      LOOP AT ls_parent-%target INTO DATA(ls_target).
        DATA(lv_sec) = COND zelm_qm_spec_secno(
          WHEN ls_target-SectionNo IS INITIAL THEN lv_next_sec
          ELSE ls_target-SectionNo ).

        DATA(lv_line) = ls_target-LineNo.
        IF lv_line IS INITIAL.
          DATA lv_max_line TYPE zelm_qm_spec_lineno.
          CLEAR lv_max_line.
          LOOP AT lt_existing_items INTO ls_exist WHERE SectionNo = lv_sec.
            IF ls_exist-LineNo > lv_max_line.
              lv_max_line = ls_exist-LineNo.
            ENDIF.
          ENDLOOP.
          LOOP AT mapped-specitem INTO DATA(ls_mapped_itm)
               WHERE DocNo = ls_parent-DocNo AND Version = ls_parent-Version AND SectionNo = lv_sec.
            IF ls_mapped_itm-LineNo > lv_max_line.
              lv_max_line = ls_mapped_itm-LineNo.
            ENDIF.
          ENDLOOP.
          lv_line = COND zelm_qm_spec_lineno(
            WHEN lv_max_line IS INITIAL THEN '0001'
            ELSE CONV zelm_qm_spec_lineno( lv_max_line + 1 ) ).
        ENDIF.

        APPEND VALUE #(
          %cid      = ls_target-%cid
          %is_draft = ls_target-%is_draft
          DocNo     = ls_parent-DocNo
          Version   = ls_parent-Version
          SectionNo = lv_sec
          LineNo    = lv_line
        ) TO mapped-specitem.
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

      " Image MIME type check (must be image/*)
      IF ls_hdr-ImageContent IS NOT INITIAL AND NOT ( to_lower( ls_hdr-ImageMimetype ) CP 'image/*' ).
        APPEND VALUE #( %tky = ls_hdr-%tky ) TO failed-specheader.
        APPEND VALUE #(
          %tky                  = ls_hdr-%tky
          %state_area           = 'VALIDATE_HEADER'
          %msg                  = new_message(
            id       = 'ZQM_SPEC'
            number   = '007'
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

  METHOD AddSection.
    READ ENTITIES OF zi_qm_spec IN LOCAL MODE
      ENTITY SpecHeader
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_headers).

    LOOP AT keys INTO DATA(ls_key).
      IF ls_key-%param-SectionTitle IS INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-specheader.
        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message(
            id       = 'ZQM_SPEC'
            number   = '002'
            severity = if_abap_behv_message=>severity-error
          )
        ) TO reported-specheader.
        CONTINUE.
      ENDIF.

      READ ENTITIES OF zi_qm_spec IN LOCAL MODE
        ENTITY SpecHeader BY \_Item
        FIELDS ( SectionNo )
        WITH VALUE #( ( %tky = ls_key-%tky ) )
        RESULT DATA(lt_items).

      DATA lv_max_sec TYPE zelm_qm_spec_secno.
      CLEAR lv_max_sec.
      LOOP AT lt_items INTO DATA(ls_itm).
        IF ls_itm-SectionNo > lv_max_sec.
          lv_max_sec = ls_itm-SectionNo.
        ENDIF.
      ENDLOOP.
      DATA(lv_new_sec) = COND zelm_qm_spec_secno(
        WHEN lv_max_sec IS INITIAL THEN '001'
        ELSE CONV zelm_qm_spec_secno( lv_max_sec + 1 ) ).

      MODIFY ENTITIES OF zi_qm_spec IN LOCAL MODE
        ENTITY SpecHeader
        CREATE BY \_Item
        FIELDS ( SectionNo LineNo SectionTitle Col2Label Col3Label )
        WITH VALUE #( (
          %tky    = ls_key-%tky
          %target = VALUE #( (
            %cid         = |SEC_{ lv_new_sec }_0001|
            %is_draft    = ls_key-%is_draft
            SectionNo    = lv_new_sec
            LineNo       = '0001'
            SectionTitle = ls_key-%param-SectionTitle
            Col2Label    = ls_key-%param-Col2Label
            Col3Label    = ls_key-%param-Col3Label
          ) )
        ) ).

      READ TABLE lt_headers INTO DATA(ls_hdr) WITH KEY %tky = ls_key-%tky.
      IF sy-subrc = 0.
        APPEND VALUE #( %tky = ls_key-%tky %param = ls_hdr ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_specitem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR SpecItem RESULT result.

    METHODS validateitem FOR VALIDATE ON SAVE
      IMPORTING keys FOR SpecItem~ValidateItem.

    METHODS addrow FOR MODIFY
      IMPORTING keys FOR ACTION SpecItem~AddRow RESULT result.

    METHODS moveup FOR MODIFY
      IMPORTING keys FOR ACTION SpecItem~MoveUp RESULT result.

    METHODS movedown FOR MODIFY
      IMPORTING keys FOR ACTION SpecItem~MoveDown RESULT result.

    METHODS move_row
      IMPORTING it_keys   TYPE TABLE FOR ACTION IMPORT zi_qm_specitem~MoveUp
                iv_dir    TYPE i
      CHANGING  ct_result TYPE TABLE FOR ACTION RESULT zi_qm_specitem~MoveUp.
ENDCLASS.

CLASS lhc_specitem IMPLEMENTATION.
  METHOD get_instance_features.
    READ ENTITIES OF zi_qm_spec IN LOCAL MODE
      ENTITY SpecItem
      FIELDS ( DocNo Version SectionNo LineNo )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    result = VALUE #( FOR ls_itm IN lt_items (
      %tky             = ls_itm-%tky
      %action-AddRow   = COND #( WHEN ls_itm-%is_draft = if_abap_behv=>mk-on
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )
      %action-MoveUp   = COND #( WHEN ls_itm-%is_draft = if_abap_behv=>mk-on
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )
      %action-MoveDown = COND #( WHEN ls_itm-%is_draft = if_abap_behv=>mk-on
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled )
    ) ).
  ENDMETHOD.

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

  METHOD AddRow.
    READ ENTITIES OF zi_qm_spec IN LOCAL MODE
      ENTITY SpecItem
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_sel).

    LOOP AT lt_sel INTO DATA(ls_sel).
      READ ENTITIES OF zi_qm_spec IN LOCAL MODE
        ENTITY SpecHeader BY \_Item
        FIELDS ( SectionNo LineNo )
        WITH VALUE #( ( %is_draft = ls_sel-%is_draft DocNo = ls_sel-DocNo Version = ls_sel-Version ) )
        RESULT DATA(lt_all_items).

      DATA lv_max_line TYPE zelm_qm_spec_lineno.
      CLEAR lv_max_line.
      LOOP AT lt_all_items INTO DATA(ls_all) WHERE SectionNo = ls_sel-SectionNo.
        IF ls_all-LineNo > lv_max_line.
          lv_max_line = ls_all-LineNo.
        ENDIF.
      ENDLOOP.
      DATA(lv_new_line) = CONV zelm_qm_spec_lineno( lv_max_line + 1 ).

      MODIFY ENTITIES OF zi_qm_spec IN LOCAL MODE
        ENTITY SpecHeader
        CREATE BY \_Item
        FIELDS ( SectionNo LineNo SectionTitle Col2Label Col3Label )
        WITH VALUE #( (
          %is_draft = ls_sel-%is_draft
          DocNo     = ls_sel-DocNo
          Version   = ls_sel-Version
          %target   = VALUE #( (
            %cid         = |ROW_{ ls_sel-SectionNo }_{ lv_new_line }|
            %is_draft    = ls_sel-%is_draft
            SectionNo    = ls_sel-SectionNo
            LineNo       = lv_new_line
            SectionTitle = ls_sel-SectionTitle
            Col2Label    = ls_sel-Col2Label
            Col3Label    = ls_sel-Col3Label
          ) )
        ) ).

      APPEND VALUE #( %tky = ls_sel-%tky %param = ls_sel ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD MoveUp.
    move_row(
      EXPORTING it_keys   = keys
                iv_dir    = -1
      CHANGING  ct_result = result ).
  ENDMETHOD.

  METHOD MoveDown.
    move_row(
      EXPORTING it_keys   = keys
                iv_dir    = 1
      CHANGING  ct_result = result ).
  ENDMETHOD.

  METHOD move_row.
    READ ENTITIES OF zi_qm_spec IN LOCAL MODE
      ENTITY SpecItem
      ALL FIELDS
      WITH CORRESPONDING #( it_keys )
      RESULT DATA(lt_sel).

    LOOP AT lt_sel INTO DATA(ls_cur).
      READ ENTITIES OF zi_qm_spec IN LOCAL MODE
        ENTITY SpecHeader BY \_Item
        ALL FIELDS
        WITH VALUE #( ( %is_draft = ls_cur-%is_draft DocNo = ls_cur-DocNo Version = ls_cur-Version ) )
        RESULT DATA(lt_all_items).

      DELETE lt_all_items WHERE SectionNo <> ls_cur-SectionNo.
      SORT lt_all_items BY LineNo ASCENDING.

      READ TABLE lt_all_items TRANSPORTING NO FIELDS WITH KEY LineNo = ls_cur-LineNo.
      DATA(lv_adj_idx) = sy-tabix + iv_dir.

      IF lv_adj_idx < 1 OR lv_adj_idx > lines( lt_all_items ).
        APPEND VALUE #(
          %tky = ls_cur-%tky
          %msg = new_message(
            id       = 'ZQM_SPEC'
            number   = '008'
            severity = if_abap_behv_message=>severity-warning
          )
        ) TO reported-specitem.
        APPEND VALUE #( %tky = ls_cur-%tky %param = ls_cur ) TO ct_result.
        CONTINUE.
      ENDIF.

      DATA(ls_adj) = lt_all_items[ lv_adj_idx ].

      MODIFY ENTITIES OF zi_qm_spec IN LOCAL MODE
        ENTITY SpecItem
        UPDATE FIELDS ( Topic TopicBold TopicItalic Description DescBold DescItalic Method MethodBold MethodItalic )
        WITH VALUE #(
          ( %tky         = ls_cur-%tky
            Topic        = ls_adj-Topic
            TopicBold    = ls_adj-TopicBold
            TopicItalic  = ls_adj-TopicItalic
            Description  = ls_adj-Description
            DescBold     = ls_adj-DescBold
            DescItalic   = ls_adj-DescItalic
            Method       = ls_adj-Method
            MethodBold   = ls_adj-MethodBold
            MethodItalic = ls_adj-MethodItalic )
          ( %tky         = ls_adj-%tky
            Topic        = ls_cur-Topic
            TopicBold    = ls_cur-TopicBold
            TopicItalic  = ls_cur-TopicItalic
            Description  = ls_cur-Description
            DescBold     = ls_cur-DescBold
            DescItalic   = ls_cur-DescItalic
            Method       = ls_cur-Method
            MethodBold   = ls_cur-MethodBold
            MethodItalic = ls_cur-MethodItalic )
        ).

      READ ENTITIES OF zi_qm_spec IN LOCAL MODE
        ENTITY SpecItem
        ALL FIELDS
        WITH VALUE #( ( %tky = ls_cur-%tky ) )
        RESULT DATA(lt_updated).

      IF lt_updated IS NOT INITIAL.
        APPEND VALUE #( %tky = ls_cur-%tky %param = lt_updated[ 1 ] ) TO ct_result.
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
