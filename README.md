# abap-cds-amdp-odata-rap-examples

**The modern ABAP read/expose stack in one place: CDS view entities with associations and `CASE`, an AMDP-backed CDS table function, OData V2 (SEGW) design notes, and a RAP managed business object with draft.**

Each file is a self-contained, client-free example of a pattern used on S/4HANA projects.

## Contents

| File | What it shows |
|---|---|
| [`zi_salesorder_netvalue.ddls.asddls`](zi_salesorder_netvalue.ddls.asddls) | **CDS view entity** over released `I_SalesOrderItem` with associations to `I_SalesOrder` / `I_Product`, `CASE` classification (A/B/C value class), guarded `division( )` arithmetic, currency semantics, exposed associations |
| [`ztf_pending_delivery.ddls.asddls`](ztf_pending_delivery.ddls.asddls) + [`zcl_amdp_pending_delivery.clas.abap`](zcl_amdp_pending_delivery.clas.abap) | **CDS table function implemented by AMDP** (SQLScript). Pending delivery quantity per sales-order item = confirmed schedule-line qty − delivered qty, with a parameterised cut-off date, `COALESCE` and a `HAVING` filter - logic that is awkward to express in plain CDS |
| [`zr_fuelissue.bdef.asbdef`](zr_fuelissue.bdef.asbdef) | **RAP behavior definition**, managed, strict(2), with draft: header/item composition, early numbering, determinations, validations, feature-controlled action `post`, field mappings |
| [`zbp_r_fuelissue.clas.locals_imp.abap`](zbp_r_fuelissue.clas.locals_imp.abap) | **Behavior implementation** (header entity): instance features, early numbering via `cl_numberrange_runtime`, determination, validations with `%element` targeting, action skeleton. The item handler and the CDS/table layer are left out to keep the example focused; for a complete, installable BO see [abap-rap-service-request-draft-bo](https://github.com/sunny-bhanu/abap-rap-service-request-draft-bo) |

## Design notes

### CDS
- **Released `I_` views first.** `ZI_` views only wrap released views or own Z tables - no direct access to `VBAK`/`VBAP` from a CDS *view entity* in a clean-core landscape.
- `@ObjectModel.usageType` and `@AccessControl.authorizationCheck: #CHECK` are set deliberately; a DCL (`ZI_SalesOrder_NetValue` → `I_SalesOrder` inheritance) belongs alongside in a real transport.
- `division( a, b, 2 )` with a zero guard - unguarded division dumps at runtime on HANA.

### AMDP table function
- The AMDP reads base tables (`VBAK`, `VBAP`, `VBEP`, `LIPS`) because SQLScript cannot consume CDS view entities on all releases. In an **ABAP Cloud / tier-1** context this class is not allowed - replace it with a CDS view using `I_SalesOrderScheduleLine` and `I_DeliveryDocumentItem`, or move it to tier 2.
- Client handling is `#SESSION_VARIABLE` with `p_clnt` bound to `#CLIENT`, so consumers never pass the client explicitly.
- `OPTIONS READ-ONLY` and an explicit `USING` list are mandatory for the AMDP syntax check.

### OData V2 (SEGW) - not in files, but the approach
For the Gateway services behind SAPUI5 freestyle apps:
1. Model the entity sets by **referencing the CDS views** (`Reference → Data Source → CDS`) instead of importing DDIC structures, so filtering and paging are pushed down automatically.
2. Put **value-help entity sets** (plants, equipment by ownership, storage locations) on CDS views with `@Consumption.valueHelpDefinition`.
3. Redefine only what CDS cannot do in the DPC extension class: **function imports** for *build lines* and *post*, deep-insert in `CREATE_DEEP_ENTITY`, and `/IWBEP/CX_MGW_BUSI_EXCEPTION` with a message container for errors.
4. Posting goes through released BAPIs (`BAPI_GOODSMVT_CREATE` + `BAPI_TRANSACTION_COMMIT`) - one controlled LUW, never BDC.

### RAP
- `strict ( 2 )` enforces the ABAP Cloud rule set at design time - the earlier you turn it on, the cheaper.
- `early numbering` through `cl_numberrange_runtime` keeps the ID stable across draft → active.
- The `post` action sets the status; the goods-movement BAPI itself belongs in the **save sequence** (`lsc_…=>save_modified`) so it runs inside the RAP LUW and rolls back with it. Calling a BAPI with COMMIT inside an action method breaks the RAP transaction model.
- Instance features disable `post` once the status is no longer *New*, so the Fiori Elements button greys out without any UI code.

## Related

- Complete draft-enabled RAP business object with actions, side effects, DCL and ABAP Unit tests: [abap-rap-service-request-draft-bo](https://github.com/sunny-bhanu/abap-rap-service-request-draft-bo)
- Clean-core wrapper pattern: [abap-salv-runtime-capture-wrapper](https://github.com/sunny-bhanu/abap-salv-runtime-capture-wrapper)
- Performance patterns referenced above: [abap-performance-patterns](https://github.com/sunny-bhanu/abap-performance-patterns)

---
*Written as generic reference material. No client data or client-specific logic.* MIT License - see [LICENSE](LICENSE).
