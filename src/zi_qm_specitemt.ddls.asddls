@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Specification Item Interface View'
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
define view entity ZI_QM_SPECITEMT
  as select from zqmtspit
  association to parent ZI_QM_SPECT as _Header
    on  $projection.DocNo   = _Header.DocNo
    and $projection.Version = _Header.Version
{
  key doc_no                as DocNo,
  key version               as Version,
  key section_no            as SectionNo,
  key line_no               as LineNo,
      section_title         as SectionTitle,
      col2_label            as Col2Label,
      col3_label            as Col3Label,
      topic                 as Topic,
      topic_bold            as TopicBold,
      topic_italic          as TopicItalic,
      description           as Description,
      desc_bold             as DescBold,
      desc_italic           as DescItalic,
      method                as Method,
      method_bold           as MethodBold,
      method_italic         as MethodItalic,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _Header
}
