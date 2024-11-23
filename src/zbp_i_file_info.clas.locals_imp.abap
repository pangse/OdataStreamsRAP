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
                                               %features-%action-uploadexceldata = COND #( WHEN ls_file-%is_draft = '00'
                                                                                           THEN if_abap_behv=>fc-f-read_only
                                                                                           ELSE if_abap_behv=>fc-f-unrestricted ) ) ).

  ENDMETHOD.


  METHOD uploadExcelData.

** Check if there exist an entry with current logged in username in parent table
    SELECT @abap_true INTO @DATA(lv_valid) FROM zrap_file_info UP TO 1 ROWS WHERE end_user = @sy-uname.
    ENDSELECT.
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
          conv          TYPE REF TO cl_abap_conv_in_ce,
          ls_excel_data TYPE zrap_file_data,
          lt_excel_data TYPE STANDARD TABLE OF zrap_file_data,
          lv_quantity   TYPE char10,
          lv_entrysheet TYPE ebeln.

** Convert excel file with CSV format into internal table of type string
    conv = cl_abap_conv_in_ce=>create( input = lv_attachment ).
    conv->read( IMPORTING data = content ).

** Split the string table to rows
    SPLIT content AT cl_abap_char_utilities=>cr_lf INTO TABLE rows.

** Process the rows and append to the internal table
    LOOP AT rows INTO DATA(ls_row).
      SPLIT ls_row AT ',' INTO ls_excel_data-entrysheet
                               ls_excel_data-ebeln
                               ls_excel_data-ebelp
                               ls_excel_data-ext_number
                               ls_excel_data-begdate
                               ls_excel_data-enddate
                               lv_quantity
                               "ls_attdata-BASE_UOM
                               ls_excel_data-fin_entry.

      ls_excel_data-entrysheet = lv_entrysheet = |{ ls_excel_data-entrysheet ALPHA = IN }|.
      ls_excel_data-ebeln      = |{ ls_excel_data-ebeln ALPHA = IN }|.
      ls_excel_data-ebelp      = |{ ls_excel_data-ebelp ALPHA = IN }|.
      ls_excel_data-quantity = CONV #( lv_quantity ).

      APPEND ls_excel_data TO lt_excel_data.

      CLEAR: ls_row, ls_excel_data.
    ENDLOOP.

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
                                                                                  %control = VALUE #( end_user    = if_abap_behv=>mk-on
                                                                                                      entrysheet  = if_abap_behv=>mk-on
                                                                                                      ebeln       = if_abap_behv=>mk-on
                                                                                                      ebelp       = if_abap_behv=>mk-on
                                                                                                      ext_number  = if_abap_behv=>mk-on
                                                                                                      begdate     = if_abap_behv=>mk-on
                                                                                                      enddate     = if_abap_behv=>mk-on
                                                                                                      quantity    = if_abap_behv=>mk-on
                                                                                                     " BASE_UOM    = ls_data-
                                                                                                      fin_entry   = if_abap_behv=>mk-on  ) ) ) ) ).
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
    WITH lt_att_create.


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
    SELECT @abap_true INTO @DATA(lv_valid) FROM zrap_file_info UP TO 1 ROWS WHERE end_user = @sy-uname.
    ENDSELECT.

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
      IMPORTING keys FOR ACTION ExcelData~downloadSES RESULT result.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ExcelData RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ExcelData RESULT result.

ENDCLASS.

CLASS lhc_ZI_FILE_DATA IMPLEMENTATION.



  METHOD downloadSES.

  READ ENTITIES OF ZI_FILE_INFO IN LOCAL MODE
         ENTITY ExcelData
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_excel)
         " TODO: variable is assigned but never used (ABAP cleaner)
         FAILED DATA(lt_failed_v).

*    DATA(write_xlsx) = xco_cp_xlsx=>document->empty( )->write_access( ).

  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

ENDCLASS.
