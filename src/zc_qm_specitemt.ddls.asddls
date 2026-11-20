@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Specification Item Projection'
@Metadata.allowExtensions: true
define view entity ZC_QM_SPECITEMT
  as projection on ZI_QM_SPECITEMT
{
  key DocNo,
  key Version,
  key SectionNo,
  key LineNumber,
      SectionTitle,
      Col2Label,
      Col3Label,
      Topic,
      TopicBold,
      TopicItalic,
      Description,
      DescBold,
      DescItalic,
      Method,
      MethodBold,
      MethodItalic,
      LocalLastChangedAt,

      _Header : redirected to parent ZC_QM_SPECT
}
