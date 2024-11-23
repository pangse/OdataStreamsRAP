@EndUserText.label: 'Consumption View for Ses Excel Data'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true 
define view entity zc_file_data
  as projection on ZI_FILE_DATA
{
  key end_user,
  key Entrysheet,
  key Ebeln,
  key Ebelp,
      Ext_Number,
      Begdate,
      Enddate,
      Quantity,
      Base_Uom,
      Fin_Entry,
      Error,
      Error_Message,
      /* Associations */
      _ses_file : redirected to parent zc_file_info
}
