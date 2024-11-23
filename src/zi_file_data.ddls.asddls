@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface view for file data'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_FILE_DATA
  as select from zrap_file_data
  association to parent ZI_FILE_INFO as _ses_file on $projection.end_user = _ses_file.end_user
{
  key end_user                     as end_user,
  key zrap_file_data.entrysheet    as Entrysheet,
  key zrap_file_data.ebeln         as Ebeln,
  key zrap_file_data.ebelp         as Ebelp,
      zrap_file_data.ext_number    as Ext_Number,
      zrap_file_data.begdate       as Begdate,
      zrap_file_data.enddate       as Enddate, 
      zrap_file_data.base_uom      as Base_Uom,      
      @Semantics.quantity.unitOfMeasure : 'Base_Uom'           
      zrap_file_data.quantity      as Quantity,      
      zrap_file_data.fin_entry     as Fin_Entry,
      zrap_file_data.error         as Error,
      zrap_file_data.error_message as Error_Message,

      _ses_file
}
