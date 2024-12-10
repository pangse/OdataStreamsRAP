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
*    ls_data-bname = 'CB9980006571'.
*
*    INSERT zuser02 FROM @ls_data.
*
*    if sy-subrc = 0.
*
*    out->write( 's' ).
*
*    ENDIF.





    DELETE FROM zrap_file_info WHERE end_user = 'CB9980001701'.
*    DELETE FROM zrap_file_info WHERE end_user = 'CB9980001701'.
*
*    DELETE FROM zrap_file_info WHERE end_user = 'CB9980001702'.
*    DELETE FROM zrap_file_info WHERE end_user = 'CB9980001703'.
*    DELETE FROM zrap_file_info WHERE end_user = 'CB9980001704'.
*    DELETE FROM zrap_file_info WHERE end_user = 'CB9980001705'.


    DELETE FROM zuser02 WHERE bname = 'CB9980006571'.
*    DELETE FROM zuser02 WHERE bname = 'Download1'.
*
*    DELETE FROM zuser02 WHERE bname = 'Download2'.
*    DELETE FROM zuser02 WHERE bname = 'Download6'.



  ENDMETHOD.
ENDCLASS.
