@EndUserText.label: 'Consumption View for File info'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity zc_file_info
  provider contract transactional_query
  as projection on ZI_FILE_INFO
{
  key end_user,
      @EndUserText.label: 'Processing Status'
      FileStatus as status,
      Attachment,
      MimeType,
      Filename,
      Local_Created_By,
      Local_Created_At,
      Local_Last_Changed_By,
      @EndUserText.label: 'Last Action On'
      Local_Last_Changed_At,
      Last_Changed_At,
      CriticalityStatus,
      HideExcel,
      
      /* Associations */
      _ses_excel : redirected to composition child zc_file_data
}
