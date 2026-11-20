# POCTESTTA - Specification Form (SAP ABAP Cloud RAP)

abapGit repository for **Product Specification Form** (`ZPOCTESTTA`) on **SAP S/4HANA Public Cloud** (ABAP Language Version 5, Managed RAP with Draft, OData V4 UI).

## Architecture Overview

| Layer | Object | Description |
| :--- | :--- | :--- |
| **Package** | `ZPOCTESTTA` | Root package |
| **Database Tables** | `ZQMTSPHT` / `ZQMTSPIT` | Header & Detail persistent tables |
| **Draft Tables** | `ZQMTSPHDT` / `ZQMTSPIDT` | Managed draft persistence tables |
| **Interface CDS** | `ZI_QM_SPEC` / `ZI_QM_SPECITEM` | Root & Child interface view entities |
| **Projection CDS** | `ZC_QM_SPEC` / `ZC_QM_SPECITEM` | Transactional consumption views |
| **Metadata Extensions** | `ZC_QM_SPEC` / `ZC_QM_SPECITEM` | Fiori Elements List Report & Object Page UI |
| **Behavior Definitions** | `ZI_QM_SPEC` / `ZC_QM_SPEC` | Managed + Draft + Early Numbering + Actions |
| **Behavior Pool** | `ZBP_I_QM_SPEC` | EML handlers, validations, features |
| **Business Logic** | `ZCL_QM_SPEC_ACTION` | Doc/Version numbering & clone helpers |
| **Service Definition** | `ZSD_QM_SPEC_TOM_SRV` | Exposes `SpecHeader`, `SpecItem`, `BusinessUser` |
| **Service Binding** | `ZSB_QM_SPEC_UI` | OData V4 - UI |

## Implemented Features & Actions

- **Create / Edit / Delete** with RAP Draft handling (`Edit`, `Activate`, `Discard`, `Resume`, `Prepare`).
- **Auto Numbering**: `DocNo` (10-digit running number) + `Version` (`001`) via early numbering.
- **Create New Version (`NewVersion`)**: Clones header + all sections/lines to `Version + 1` under the same `DocNo`.
- **Copy (`Copy`)**: Clones header + all sections/lines to a new `DocNo` starting at `Version 001`.
- **Print Specification (`Print`)**: Action hook for A4 Specification print / PDF output.
- **Product Image Attachment**: `@Semantics.largeObject` on `ImageContent` (`RAWSTRING`) with MIME type & filename.
- **Validations**: Mandatory `ProductCode` & `ProductName`, mandatory `SectionTitle` on items, image size <= 2 MB.

## Deployment (GitHub -> Eclipse ADT abapGit)

1. Create an empty repository named **`POCTESTTA`** on GitHub (do **not** initialize with README).
2. Push this `POCPTA` folder using:
   ```powershell
   .\push_to_github.ps1 -RepoUrl "https://github.com/<your-username>/POCTESTTA.git"
   ```
3. In **Eclipse ADT**, open **abapGit Repositories** -> **Link**, point to `POCTESTTA` and package `ZPOCTESTTA`, then **Pull**.
4. Activate objects bottom-up (Tables -> CDS -> DDLX -> BDEF -> Classes -> SRVD -> SRVB) and **Publish** `ZSB_QM_SPEC_UI`.
