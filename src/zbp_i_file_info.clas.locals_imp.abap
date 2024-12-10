CLASS lhc_ZI_FILE_INFO DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR file RESULT result.

    METHODS uploadExcelData FOR MODIFY
      IMPORTING keys FOR ACTION file~uploadExcelData RESULT result.

    METHODS fields FOR DETERMINE ON MODIFY
      IMPORTING keys FOR file~fields.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR file RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR file RESULT result.

ENDCLASS.

CLASS lhc_ZI_FILE_INFO IMPLEMENTATION.

  METHOD get_instance_features.

    READ ENTITIES OF zi_file_info IN LOCAL MODE
           ENTITY file
           FIELDS ( end_user )
           WITH CORRESPONDING #( keys )
           RESULT DATA(lt_file).

    result = VALUE #( FOR ls_file IN lt_file ( %key = ls_file-%key
                                               %is_draft = ls_file-%is_draft
                                               %features-%action-uploadExcelData = COND #( WHEN ls_file-%is_draft = '00'
                                                                                           THEN if_abap_behv=>fc-f-read_only
                                                                                           ELSE if_abap_behv=>fc-f-unrestricted ) ) ).

  ENDMETHOD.


  METHOD uploadExcelData.

** Check if there exist an entry with current logged in username in parent table
    SELECT SINGLE @abap_true  FROM zrap_file_info WHERE end_user = @sy-uname
    INTO @DATA(lv_valid).

** Create one entry, if it does not exist
    IF lv_valid <> abap_true.
      INSERT zrap_file_info FROM @( VALUE #( end_user = sy-uname ) ).
    ENDIF.
** Read the parent instance
    READ ENTITIES OF zi_file_info IN LOCAL MODE
      ENTITY file
      ALL FIELDS WITH
      CORRESPONDING #( keys )
      RESULT DATA(lt_inv).

** Get attachment value from the instance
    DATA(lv_attachment) = lt_inv[ 1 ]-attachment.

** Data declarations
    DATA: rows          TYPE STANDARD TABLE OF string,
          content       TYPE string,
          conv          TYPE REF TO cl_abap_conv_codepage,
          ls_excel_data TYPE zrap_file_data,
          lt_excel_data TYPE STANDARD TABLE OF zrap_file_data,
          lv_quantity   TYPE char10,
          lv_entrysheet TYPE ebeln.

    TYPES: BEGIN OF po_line_type,
             entrysheet    TYPE c LENGTH 10,
             ebeln         TYPE ebeln,
             ebelp         TYPE ebelp,
             ext_number    TYPE c LENGTH 16,
             begdate       TYPE zlzvon,
             enddate       TYPE zlzvon,
             quantity      TYPE zmengev,
             fin_entry     TYPE c LENGTH 1,
             error         TYPE abap_boolean,
             error_message TYPE c LENGTH 100,
           END OF po_line_type,
           po_tab_type TYPE TABLE OF po_line_type WITH EMPTY KEY.
    DATA po_tab TYPE po_tab_type.

** Convert excel file with CSV format into internal table of type string
*    conv = cl_abap_conv_in_ce=>create( input = lv_attachment ).
*    conv->read( IMPORTING data = content ).


    "As a first step (for reading and writing XLSX content), getting a handle to process
    "XLSX content, which is available as xstring.
    DATA(xlsx_doc) = xco_cp_xlsx=>document->for_file_content( lv_attachment ).

    "------------------------ Read access to XLSX content ------------------------

    "Getting read access
    DATA(read_xlsx) = xlsx_doc->read_access( ).

    "Reading the first worksheet of the XLSX file
    DATA(worksheet1) = read_xlsx->get_workbook( )->worksheet->at_position( 1 ).

    "You can also specify the name of the worksheet
    "DATA(worksheet1) = read_xlsx->get_workbook( )->worksheet->for_name( 'Sheet1' ).

    "Using selection patterns
    "The XCO XLSX module works with selection patterns that define how the content
    "in a worksheet is selected (i.e. whether everything or a restricted set is selected).
    "Check the documentation for further information.
    "The following selection pattern respects all values.
    DATA(pattern_all) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).

    "Note that the content is written to a reference to an internal table
    "with the write_to method.
    worksheet1->select( pattern_all
      )->row_stream(
      )->operation->write_to( REF #( po_tab )
      )->execute( ).

    MOVE-CORRESPONDING po_tab TO lt_excel_data.


*    DATA(xstring2string) = cl_abap_conv_codepage=>create_in( codepage = `UTF-8`
*                                                                            )->convert( source = lv_attachment ).
*
*** Split the string table to rows
*    SPLIT xstring2string AT cl_abap_char_utilities=>cr_lf INTO TABLE rows.
*
*** Process the rows and append to the internal table
*    LOOP AT rows INTO DATA(ls_row).
*      SPLIT ls_row AT ',' INTO ls_excel_data-entrysheet
*                               ls_excel_data-ebeln
*                               ls_excel_data-ebelp
*                               ls_excel_data-ext_number
*                               ls_excel_data-begdate
*                               ls_excel_data-enddate
*                               lv_quantity
*                               "ls_attdata-BASE_UOM
*                               ls_excel_data-fin_entry.
*
*      ls_excel_data-entrysheet = lv_entrysheet = |{ ls_excel_data-entrysheet ALPHA = IN }|.
*      ls_excel_data-ebeln      = |{ ls_excel_data-ebeln ALPHA = IN }|.
*      ls_excel_data-ebelp      = |{ ls_excel_data-ebelp ALPHA = IN }|.
*      ls_excel_data-quantity = CONV #( lv_quantity ).
*
*      APPEND ls_excel_data TO lt_excel_data.
*
*      CLEAR: ls_row, ls_excel_data.
*    ENDLOOP.

** Delete duplicate records
    DELETE ADJACENT DUPLICATES FROM lt_excel_data.
    DELETE lt_excel_data WHERE ebeln IS INITIAL.

** Prepare the datatypes to store the data from internal table lt_excel_data to child entity through EML
    DATA lt_att_create TYPE TABLE FOR CREATE zi_file_info\_ses_excel.

    lt_att_create = VALUE #( (  %cid_ref  = keys[ 1 ]-%cid_ref
                                %is_draft = keys[ 1 ]-%is_draft
                                end_user  = keys[ 1 ]-end_user
                                %target   = VALUE #( FOR ls_data IN lt_excel_data ( %cid       = |{ ls_data-ebeln }{ ls_data-ebelp }|
                                                                                   %is_draft   = keys[ 1 ]-%is_draft
                                                                                   end_user    = sy-uname
                                                                                   entrysheet  = ls_data-entrysheet
                                                                                   ebeln       = ls_data-ebeln
                                                                                   ebelp       = ls_data-ebelp
                                                                                   ext_number  = ls_data-ext_number
                                                                                   begdate     = ls_data-begdate
                                                                                   enddate     = ls_data-enddate
                                                                                   quantity    = ls_data-quantity
                                                                                  " BASE_UOM    = ls_data-
                                                                                   fin_entry   = ls_data-fin_entry
                                                                                   Error       = ls_data-error
                                                                                   Error_Message = ls_data-error_message
                                                                                  %control = VALUE #( end_user    = if_abap_behv=>mk-on
                                                                                                      entrysheet  = if_abap_behv=>mk-on
                                                                                                      ebeln       = if_abap_behv=>mk-on
                                                                                                      ebelp       = if_abap_behv=>mk-on
                                                                                                      ext_number  = if_abap_behv=>mk-on
                                                                                                      begdate     = if_abap_behv=>mk-on
                                                                                                      enddate     = if_abap_behv=>mk-on
                                                                                                      quantity    = if_abap_behv=>mk-on
                                                                                                     " BASE_UOM    = ls_data-
                                                                                                      fin_entry   = if_abap_behv=>mk-on
                                                                                                      Error       = if_abap_behv=>mk-on
                                                                                                      error_message = if_abap_behv=>mk-on  ) ) ) ) ).
    READ ENTITIES OF zi_file_info IN LOCAL MODE
    ENTITY file
    BY \_ses_excel
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(lt_excel).

** Delete already existing entries from child entity
    MODIFY ENTITIES OF zi_file_info IN LOCAL MODE
    ENTITY exceldata
    DELETE FROM VALUE #( FOR ls_excel IN lt_excel (  %is_draft = ls_excel-%is_draft
                                                     %key      = ls_excel-%key ) )
    MAPPED DATA(lt_mapped_delete)
    REPORTED DATA(lt_reported_delete)
    FAILED DATA(lt_failed_delete).

** Create the records from the new attached CSV file
    MODIFY ENTITIES OF zi_file_info IN LOCAL MODE
    ENTITY file
    CREATE BY \_ses_excel
    AUTO FILL CID
    WITH lt_att_create
    MAPPED DATA(lt_map)
    REPORTED DATA(lt_rep)
    FAILED DATA(lt_fail).


    APPEND VALUE #( %tky = lt_inv[ 1 ]-%tky ) TO mapped-file.
    APPEND VALUE #( %tky = lt_inv[ 1 ]-%tky
                    %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                  text = 'Excel Data Uploaded' )
                   ) TO reported-file.

**  Update the status of file as processed
    MODIFY ENTITIES OF zi_file_info IN LOCAL MODE
    ENTITY file
    UPDATE FROM VALUE #( ( %is_draft = keys[ 1 ]-%is_draft
                           end_user  = sy-uname
                           status     =  'P'
                          " %data     = VALUE #( status = 'P' )
                           %control  = VALUE #( status = if_abap_behv=>mk-on ) ) )
    MAPPED DATA(lt_mapped_update)
    REPORTED DATA(lt_reported_update)
    FAILED DATA(lt_failed_update).

    READ ENTITIES OF zi_file_info IN LOCAL MODE
    ENTITY file
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_file_status).

**  Update the status of processing as completed
    MODIFY ENTITIES OF zi_file_info IN LOCAL MODE
    ENTITY file
    UPDATE FROM VALUE #( FOR ls_file_status IN lt_file_status ( %is_draft = ls_file_status-%is_draft
                                                                %tky      = ls_file_status-%tky
                                                                %data     = VALUE #( status = 'C'  )
                                                                %control  = VALUE #( status = if_abap_behv=>mk-on ) ) ).

    READ ENTITIES OF zi_file_info IN LOCAL MODE
    ENTITY file
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(lt_file).

    result = VALUE #( FOR ls_file IN lt_file ( %tky   = ls_file-%tky
                                               %param = ls_file ) ).

  ENDMETHOD.

  METHOD fields.

**  If entry for user not present, insert one
    SELECT SINGLE @abap_true  FROM zrap_file_info WHERE end_user = @sy-uname
 INTO @DATA(lv_valid).

    IF lv_valid <> abap_true.
      INSERT zrap_file_info FROM @( VALUE #( end_user = sy-uname ) ).
    ENDIF.

    MODIFY ENTITIES OF zi_file_info IN LOCAL MODE
    ENTITY file
    UPDATE FROM VALUE #( FOR key IN keys ( end_user        = key-end_user
                                           status          = ' ' " Accepted
                                           %control-status = if_abap_behv=>mk-on ) ).

**  Call action for uploading excel data
    IF keys[ 1 ]-%is_draft = '01'.

      MODIFY ENTITIES OF zi_file_info IN LOCAL MODE
      ENTITY file
      EXECUTE uploadexceldata
      FROM CORRESPONDING #( keys ).
    ENDIF.

  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_ZI_FILE_DATA DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.



    METHODS downloadSES FOR MODIFY
      IMPORTING keys FOR ACTION ExcelData~downloadSES.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ExcelData RESULT result.


ENDCLASS.

CLASS lhc_ZI_FILE_DATA IMPLEMENTATION.



  METHOD downloadSES.

*read filters
    DATA(lv_date) = keys[ 1 ]-%param-ValidFrom.
    DATA(lv_final) = keys[ 1 ]-%param-Final.
    DATA(lv_error) = keys[ 1 ]-%param-error.
    DATA: lt_filedata TYPE TABLE OF zrap_file_data.

*get filtered data
    SELECT * FROM zrap_file_data
    WHERE begdate GE @lv_date
    AND fin_entry = @lv_final
    AND error = @lv_error
    INTO TABLE @lt_filedata.

    "Creating a new XLSX document
    DATA(write_xlsx) = xco_cp_xlsx=>document->empty( )->write_access( ).

    "Note that the name of the created worksheet is Sheet1
    "Accessing the first worksheet via the position
    DATA(ws1) = write_xlsx->get_workbook( )->worksheet->at_position( 1 ).

    "As is the case with the read access, a pattern is used.
    "The following pattern uses the entire content.
    DATA(pattern_all4write) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).

    "Writing the internal table lines to the worksheet using the write_from method
    ws1->select( pattern_all4write
      )->row_stream(
      )->operation->write_from( REF #( lt_filedata )
      )->execute( ).

    DATA(file_content) = write_xlsx->get_file_content( ).

    IF file_content IS NOT INITIAL.
"insert data to the table
*      UPDATE zrap_file_info SET attachment = @file_content, filename = 'PO_DOWNLOAD.xlsx' WHERE end_user = @sy-uname.
      DATA: ls_data TYPE zrap_file_info.
      DATA: lv_created_at       TYPE tzntstmpl.
      DATA: lv_timestamp TYPE timestamp,
            lv_random    TYPE char12.
      GET TIME STAMP FIELD lv_created_at.
      GET TIME STAMP FIELD lv_timestamp.
      lv_random = |{ lv_timestamp }|.
      lv_random = lv_random(12).
      ls_data-end_user = lv_random.
      ls_data-attachment = file_content.
      ls_data-filename = |PO_DOWNLOAD_{ lv_timestamp }.xlsx|.
      ls_data-mimetype = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.
      ls_data-local_last_changed_at = lv_created_at.
      ls_data-local_last_changed_by = sy-uname.

      INSERT zrap_file_info FROM @ls_data.

      IF sy-subrc = 0.

        DATA(lv_text) = | { 'Download Successful with id' } { ls_data-end_user } |.

        APPEND VALUE #(
                     %msg = new_message_with_text( severity = if_abap_behv_message=>severity-information
                                                   text = lv_text )
                    ) TO reported-exceldata.

      ENDIF.



    ENDIF.


  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.


ENDCLASS.
