@EndUserText.label: 'Download Filter'
define abstract entity za_download_filter
{

  @EndUserText.label: 'Valid From'
  ValidFrom : abap.dats;
  @EndUserText.label: 'Final Entry'
  Final     : abap_boolean;
  @EndUserText.label: 'Error'
  error     : abap_boolean;

}
