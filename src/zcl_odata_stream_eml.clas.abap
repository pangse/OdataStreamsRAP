CLASS zcl_odata_stream_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_odata_stream_eml IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA: po_tab TYPE TABLE OF zrap_file_data.

    READ ENTITIES OF zr_rap_file_info
           ENTITY ZrRapFileInfo
           FIELDS ( attachment mimetype filename )
           WITH VALUE #( ( EndUser = 'CB9980001710' ) )
           RESULT DATA(lt_po_data).

    DATA(lv_po_data) = lt_po_data[ 1 ]-Attachment.

    IF lv_po_data  IS INITIAL.
      out->write( `No XLSX content available to work with` ).
      RETURN.
    ENDIF.

    out->write( `-------------------- Read access to XLSX content --------------------` ).

*    getting a handle to process XLSX content, which is available as xstring.

    DATA(xlsx_doc) = xco_cp_xlsx=>document->for_file_content( lv_po_data ).
    "Getting read access
    DATA(read_xlsx) = xlsx_doc->read_access( ).
    "Reading the first worksheet of the XLSX file
    DATA(worksheet1) = read_xlsx->get_workbook( )->worksheet->at_position( 1 ).
    "The following selection pattern respects all values.
    DATA(pattern_all) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).

    "Note that the content is written to a reference to an internal table
    "with the write_to method.
    worksheet1->select( pattern_all
      )->row_stream(
      )->operation->write_to( REF #( po_tab )
      )->execute( ).

    "Retrieving the table lines to compare the values with the next
    "example that uses a different selection pattern
    DATA(lines_tab1) = lines( po_tab ).
    "Displaying the read result in the console
    out->write( |Lines in po_tab: { lines_tab1 }| ).

    out->write( data = po_tab name = `po_tab` ).
    out->write( |\n\n| ).
*--------------------------------------------------------------------------------------------

    "------------------------ Write access to XLSX content ------------------------

    out->write( `-------------------- Write XLSX content --------------------` ).
    out->write( |\n\n| ).

    "Creating a new XLSX document
    DATA(write_xlsx) = xco_cp_xlsx=>document->empty( )->write_access( ).
    "Note that the name of the created worksheet is Sheet1
    "Accessing the first worksheet via the position
    DATA(ws1) = write_xlsx->get_workbook( )->worksheet->at_position( 1 ).

    SELECT * FROM zrap_file_data
    WHERE  error = 'X'
    INTO TABLE @DATA(lt_filedata).

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

*      UPDATE zrap_file_info SET attachment = @file_content, filename = 'PO_DOWNLOAD2.xlsx' WHERE end_user = @sy-uname.

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
        out->write( |The database table was updated. If implemented, check the file with id { ls_data-end_user }| ).
      ELSE.
        out->write( `The database table was not updated.` ).
      ENDIF.


    ENDIF.




  ENDMETHOD.
ENDCLASS.
