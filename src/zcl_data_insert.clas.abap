CLASS zcl_data_insert DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_data_insert IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

*    DATA: ls_data TYPE zuser02.
*
*    ls_data-bname = 'Download'.
*
*    INSERT zuser02 FROM @ls_data.
*
*    if sy-subrc = 0.
*
*    out->write( 's' ).
*
*    ENDIF.





*    DELETE FROM zrap_file_info WHERE end_user = 'Download'.
*    DELETE FROM zrap_file_info WHERE end_user = 'Download1'.
*
*    DELETE FROM zrap_file_info WHERE end_user = 'Download2'.
    DELETE FROM zrap_file_info WHERE end_user = 'Download8'.
        DELETE FROM zrap_file_info WHERE end_user = 'SANDRA'.


*    DELETE FROM zuser02 WHERE bname = 'Download'.
*    DELETE FROM zuser02 WHERE bname = 'Download1'.
*
*    DELETE FROM zuser02 WHERE bname = 'Download2'.
*    DELETE FROM zuser02 WHERE bname = 'Download6'.



  ENDMETHOD.
ENDCLASS.
