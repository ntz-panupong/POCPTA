@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Specification Header Projection'
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_QM_SPEC
  provider contract transactional_query
  as projection on ZI_QM_SPEC
{
  @Search.defaultSearchElement: true
  key DocNo,
  key Version,
  @Search.defaultSearchElement: true
  @Search.fuzzinessThreshold: 0.8
      ProductCode,
  @Search.defaultSearchElement: true
  @Search.fuzzinessThreshold: 0.8
      ProductName,
      LongText,
      ImageFilename,
      ImageMimetype,
      ImageContent,
      @ObjectModel.text.element: [ 'CreatedByFullName' ]
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_BusinessUserVH', element: 'UserID' } } ]
      LocalCreatedBy,
      _BusinessUserCreatedBy.PersonFullName as CreatedByFullName,
      @Consumption.filter.selectionType: #INTERVAL
      LocalCreatedAt,
      @ObjectModel.text.element: [ 'ChangedByFullName' ]
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_BusinessUserVH', element: 'UserID' } } ]
      LocalLastChangedBy,
      _BusinessUserChangedBy.PersonFullName as ChangedByFullName,
      @Consumption.filter.selectionType: #INTERVAL
      LocalLastChangedAt,
      LastChangedAt,

      _Item : redirected to composition child ZC_QM_SPECITEM
}
