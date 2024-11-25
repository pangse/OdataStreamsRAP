@EndUserText.label: 'Download Filter'
define abstract entity za_download_filter
{

  //  @UI.defaultValue:#( 'ELEMENT_OF_REFERENCED_ENTITY: Ebeln')
  //  //  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_FILE_DATA', element: 'Ebeln' } }]
  //  @Consumption.valueHelpDefinition: [{
  //     entity.name: 'ZI_FILE_DATA',
  //     entity.element: 'Ebeln'
  //   }]
  //  PurchaseOrder : ebeln;

  @EndUserText.label: 'Valid From'
  ValidFrom : abap.dats;
  @EndUserText.label: 'Final Entry'
  Final     : abap_boolean;
  @EndUserText.label: 'Error'
  error     : abap_boolean;

}
