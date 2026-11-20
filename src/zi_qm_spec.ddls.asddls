@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Specification Header Interface View'
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
define root view entity ZI_QM_SPEC
  as select from zqmtspht
  composition [0..*] of ZI_QM_SPECITEM as _Item
  association [0..1] to I_BusinessUserBasic as _BusinessUserCreatedBy
    on _BusinessUserCreatedBy.UserID = $projection.LocalCreatedBy
  association [0..1] to I_BusinessUserBasic as _BusinessUserChangedBy
    on _BusinessUserChangedBy.UserID = $projection.LocalLastChangedBy
{
  key doc_no                as DocNo,
  key version               as Version,
      product_code          as ProductCode,
      product_name          as ProductName,
      long_text             as LongText,
      image_filename        as ImageFilename,
      @Semantics.mimeType: true
      image_mimetype        as ImageMimetype,
      @Semantics.largeObject: {
        mimeType: 'ImageMimetype',
        fileName: 'ImageFilename',
        acceptableMimeTypes: [ 'image/jpeg', 'image/png', 'image/gif', 'image/svg+xml', 'image/webp' ],
        contentDispositionPreference: #INLINE
      }
      image_content         as ImageContent,
      @Semantics.user.createdBy: true
      local_created_by      as LocalCreatedBy,
      @Semantics.systemDateTime.createdAt: true
      local_created_at      as LocalCreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      _Item,
      _BusinessUserCreatedBy,
      _BusinessUserChangedBy
}
