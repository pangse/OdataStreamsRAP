@EndUserText.label: 'Download Filter'
define abstract entity za_download_filter
{

  @UI.defaultValue:#( 'ELEMENT_OF_REFERENCED_ENTITY: Ebeln')
  //  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_FILE_DATA', element: 'Ebeln' } }]
  @Consumption.valueHelpDefinition: [{
     entity.name: 'ZI_FILE_DATA',
     entity.element: 'Ebeln'
   }]
  @ObjectModel.mandatory: true
  PurchaseOrder : ebeln;
  ValidFrom     : lzvon;

}
