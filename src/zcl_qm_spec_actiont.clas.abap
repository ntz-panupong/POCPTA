*&---------------------------------------------------------------------------------------------------*
* Program ID         : ZCL_QM_SPEC_ACTIONT
* Program Title      : Business Logic for Specification Form
* Package            : ZPOCTESTTA
* Author             : ntz-panupong
* Create Date        : 2026-11-20
* Change Request No  : POCTESTTA
*&---------------------------------------------------------------------------------------------------*
* Copied from        :
* Other Related Obj  : ZI_QM_SPECT, ZBP_I_QM_SPECT
*&---------------------------------------------------------------------------------------------------*
* Change History Log
*----------------------------------------------------------------------------------------------------*
* Mod No | Date       | Author          | Change Req No | Change Detail
*----------------------------------------------------------------------------------------------------*
* 0001   | 2026-11-20 | ntz-panupong    | POCTESTTA     | Created
*----------------------------------------------------------------------------------------------------*

"! <p class="shorttext synchronized">Spec Form Business Logic Helper</p>
"!
"! <h3>Functional Responsibility</h3>
"! Encapsulates running document numbering, section/line sequencing, and EML-based
"! cloning for NewVersion and Copy actions on ZI_QM_SPECT.
"!
"! <h3>Business Process Flow</h3>
"! <ol>
"!   <li><strong>Step 1: Input &amp; Data Retrieval</strong> - Query max DocNo/Version/SectionNo/LineNo from ZI_QM_SPECT and ZI_QM_SPECITEMT</li>
"!   <li><strong>Step 2: Configuration &amp; Validation</strong> - Validate source keys before cloning</li>
"!   <li><strong>Step 3: Core Business Processing</strong> - Compute next DocNo or Version + 1</li>
"!   <li><strong>Step 4: Persistence / EML Execution</strong> - Create cloned header and child items via EML MODIFY ENTITIES</li>
"!   <li><strong>Step 5: Logging &amp; Error Handling</strong> - Populate action result and reported success/error messages</li>
"! </ol>
"!
"! <h3>Variable Configuration (VarConfig) Dependencies</h3>
"! <p>None. This class operates independently of runtime VarConfig tables.</p>
CLASS zcl_qm_spec_actiont DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      tt_action_keys   TYPE TABLE FOR ACTION IMPORT zi_qm_spect~NewVersion,
      tt_action_result TYPE TABLE FOR ACTION RESULT zi_qm_spect~NewVersion,
      tt_failed_hdr    TYPE TABLE FOR FAILED LATE zi_qm_spect,
      tt_reported_hdr  TYPE TABLE FOR REPORTED LATE zi_qm_spect.

    "! <p class="shorttext synchronized">Get next 10-digit Document No.</p>
    "!
    "! @parameter rv_doc_no | Next sequential document number
    METHODS get_next_doc_no
      RETURNING VALUE(rv_doc_no) TYPE zelm_qm_spec_docnot.

    "! <p class="shorttext synchronized">Get next Section No. for document</p>
    "!
    "! @parameter iv_doc_no     | Document number
    "! @parameter iv_version    | Version number
    "! @parameter rv_section_no | Next section number
    METHODS get_next_section_no
      IMPORTING iv_doc_no            TYPE zelm_qm_spec_docnot
                iv_version           TYPE zelm_qm_spec_versiont
      RETURNING VALUE(rv_section_no) TYPE zelm_qm_spec_secnot.

    "! <p class="shorttext synchronized">Get next Line No. for document</p>
    "!
    "! @parameter iv_doc_no  | Document number
    "! @parameter iv_version | Version number
    "! @parameter rv_line_no | Next line number
    METHODS get_next_line_no
      IMPORTING iv_doc_no         TYPE zelm_qm_spec_docnot
                iv_version        TYPE zelm_qm_spec_versiont
      RETURNING VALUE(rv_line_no) TYPE zelm_qm_spec_linenot.

    "! <p class="shorttext synchronized">Clone spec to next Version</p>
    "!
    "! @parameter it_keys     | Source instance keys
    "! @parameter ct_result   | Action result table
    "! @parameter ct_failed   | Failed keys
    "! @parameter ct_reported | Reported messages
    METHODS create_new_version
      IMPORTING it_keys     TYPE tt_action_keys
      CHANGING  ct_result   TYPE tt_action_result
                ct_failed   TYPE tt_failed_hdr
                ct_reported TYPE tt_reported_hdr.

    "! <p class="shorttext synchronized">Copy spec to new Document No.</p>
    "!
    "! @parameter it_keys     | Source instance keys
    "! @parameter ct_result   | Action result table
    "! @parameter ct_failed   | Failed keys
    "! @parameter ct_reported | Reported messages
    METHODS copy_specification
      IMPORTING it_keys     TYPE tt_action_keys
      CHANGING  ct_result   TYPE tt_action_result
                ct_failed   TYPE tt_failed_hdr
                ct_reported TYPE tt_reported_hdr.

  PRIVATE SECTION.
    METHODS clone_entity
      IMPORTING it_keys       TYPE tt_action_keys
                iv_is_new_doc TYPE abap_bool
      CHANGING  ct_result     TYPE tt_action_result
                ct_failed     TYPE tt_failed_hdr
                ct_reported   TYPE tt_reported_hdr.
ENDCLASS.

CLASS zcl_qm_spec_actiont IMPLEMENTATION.
  METHOD get_next_doc_no.
    SELECT FROM zi_qm_spect WITH PRIVILEGED ACCESS
      FIELDS MAX( DocNo ) AS max_doc
      INTO @DATA(lv_max_doc).

    IF lv_max_doc IS INITIAL.
      rv_doc_no = '0000000001'.
    ELSE.
      rv_doc_no = CONV zelm_qm_spec_docnot( lv_max_doc + 1 ).
    ENDIF.
  ENDMETHOD.

  METHOD get_next_section_no.
    SELECT FROM zi_qm_specitemt WITH PRIVILEGED ACCESS
      FIELDS MAX( SectionNo ) AS max_sec
      WHERE DocNo   = @iv_doc_no
        AND Version = @iv_version
      INTO @DATA(lv_max_sec).

    IF lv_max_sec IS INITIAL.
      rv_section_no = '001'.
    ELSE.
      rv_section_no = CONV zelm_qm_spec_secnot( lv_max_sec + 1 ).
    ENDIF.
  ENDMETHOD.

  METHOD get_next_line_no.
    SELECT FROM zi_qm_specitemt WITH PRIVILEGED ACCESS
      FIELDS MAX( LineNo ) AS max_line
      WHERE DocNo   = @iv_doc_no
        AND Version = @iv_version
      INTO @DATA(lv_max_line).

    IF lv_max_line IS INITIAL.
      rv_line_no = '0001'.
    ELSE.
      rv_line_no = CONV zelm_qm_spec_linenot( lv_max_line + 1 ).
    ENDIF.
  ENDMETHOD.

  METHOD create_new_version.
    clone_entity(
      EXPORTING
        it_keys       = it_keys
        iv_is_new_doc = abap_false
      CHANGING
        ct_result     = ct_result
        ct_failed     = ct_failed
        ct_reported   = ct_reported
    ).
  ENDMETHOD.

  METHOD copy_specification.
    clone_entity(
      EXPORTING
        it_keys       = it_keys
        iv_is_new_doc = abap_true
      CHANGING
        ct_result     = ct_result
        ct_failed     = ct_failed
        ct_reported   = ct_reported
    ).
  ENDMETHOD.

  METHOD clone_entity.
    READ ENTITIES OF zi_qm_spect IN LOCAL MODE
      ENTITY SpecHeader
      ALL FIELDS
      WITH CORRESPONDING #( it_keys )
      RESULT DATA(lt_headers).

    READ ENTITIES OF zi_qm_spect IN LOCAL MODE
      ENTITY SpecHeader BY \_Item
      ALL FIELDS
      WITH CORRESPONDING #( it_keys )
      RESULT DATA(lt_items).

    DATA(lv_next_doc) = COND zelm_qm_spec_docnot( WHEN iv_is_new_doc = abap_true THEN get_next_doc_no( ) ELSE '' ).

    LOOP AT lt_headers INTO DATA(ls_hdr).
      DATA lv_target_doc TYPE zelm_qm_spec_docnot.
      DATA lv_target_ver TYPE zelm_qm_spec_versiont.

      IF iv_is_new_doc = abap_true.
        lv_target_doc = lv_next_doc.
        lv_target_ver = '001'.
        lv_next_doc   = CONV zelm_qm_spec_docnot( lv_next_doc + 1 ).
      ELSE.
        lv_target_doc = ls_hdr-DocNo.
        SELECT FROM zi_qm_spect WITH PRIVILEGED ACCESS
          FIELDS MAX( Version ) AS max_ver
          WHERE DocNo = @ls_hdr-DocNo
          INTO @DATA(lv_max_ver).
        SELECT FROM zqmtsphdt
          FIELDS MAX( version ) AS max_draft_ver
          WHERE doc_no = @ls_hdr-DocNo
          INTO @DATA(lv_max_draft_ver).
        IF lv_max_draft_ver > lv_max_ver.
          lv_max_ver = lv_max_draft_ver.
        ENDIF.
        lv_target_ver = CONV zelm_qm_spec_versiont( lv_max_ver + 1 ).
      ENDIF.

      DATA(lt_create_hdr) = VALUE TABLE FOR CREATE zi_qm_spect(
        ( %cid          = |HDR_{ sy-tabix }|
          %is_draft     = if_abap_behv=>mk-on
          DocNo         = lv_target_doc
          Version       = lv_target_ver
          ProductCode   = ls_hdr-ProductCode
          ProductName   = ls_hdr-ProductName
          LongText      = ls_hdr-LongText
          ImageFilename = ls_hdr-ImageFilename
          ImageMimetype = ls_hdr-ImageMimetype
          ImageContent  = ls_hdr-ImageContent )
      ).

      MODIFY ENTITIES OF zi_qm_spect IN LOCAL MODE
        ENTITY SpecHeader
        CREATE FIELDS ( DocNo Version ProductCode ProductName LongText ImageFilename ImageMimetype ImageContent )
        WITH lt_create_hdr
        MAPPED   DATA(ls_mapped)
        FAILED   DATA(ls_failed)
        REPORTED DATA(ls_reported).

      IF ls_mapped-specheader IS NOT INITIAL.
        DATA(ls_new_hdr) = ls_mapped-specheader[ 1 ].
        DATA(lt_create_itm) = VALUE TABLE FOR CREATE zi_qm_spect\_Item(
          ( %tky    = ls_new_hdr-%tky
            %target = VALUE #(
              FOR ls_itm IN lt_items WHERE ( DocNo = ls_hdr-DocNo AND Version = ls_hdr-Version )
              ( %cid         = |ITM_{ ls_itm-SectionNo }_{ ls_itm-LineNo }|
                %is_draft    = if_abap_behv=>mk-on
                SectionNo    = ls_itm-SectionNo
                LineNo       = ls_itm-LineNo
                SectionTitle = ls_itm-SectionTitle
                Col2Label    = ls_itm-Col2Label
                Col3Label    = ls_itm-Col3Label
                Topic        = ls_itm-Topic
                TopicBold    = ls_itm-TopicBold
                TopicItalic  = ls_itm-TopicItalic
                Description  = ls_itm-Description
                DescBold     = ls_itm-DescBold
                DescItalic   = ls_itm-DescItalic
                Method       = ls_itm-Method
                MethodBold   = ls_itm-MethodBold
                MethodItalic = ls_itm-MethodItalic )
            ) )
        ).

        IF lt_create_itm[ 1 ]-%target IS NOT INITIAL.
          MODIFY ENTITIES OF zi_qm_spect IN LOCAL MODE
            ENTITY SpecHeader
            CREATE BY \_Item
            FIELDS ( SectionNo LineNo SectionTitle Col2Label Col3Label Topic TopicBold TopicItalic
                     Description DescBold DescItalic Method MethodBold MethodItalic )
            WITH lt_create_itm
            FAILED   DATA(ls_itm_failed)
            REPORTED DATA(ls_itm_reported).
        ENDIF.
        READ ENTITIES OF zi_qm_spect IN LOCAL MODE
          ENTITY SpecHeader
          ALL FIELDS
          WITH VALUE #( ( %tky = ls_mapped-specheader[ 1 ]-%tky ) )
          RESULT DATA(lt_new_headers).

        IF lt_new_headers IS NOT INITIAL.
          APPEND VALUE #( %tky = ls_hdr-%tky %param = lt_new_headers[ 1 ] ) TO ct_result.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
