# Observing network dataset: build log

Output: `data/observing_network.json`. Script: `methods/scripts/fetch_observing_network.ps1`. Raw downloads: `data/raw/observing_network/`.
Built 2026-09-25.

## How to re-create

```
powershell -ExecutionPolicy Bypass -File methods\scripts\fetch_observing_network.ps1          # download and build
powershell -ExecutionPolicy Bypass -File methods\scripts\fetch_observing_network.ps1 -Offline # rebuild from saved raw files
```

The script needs Windows PowerShell 5.1 and nothing else. The live sources change over time, so a later run can give slightly different counts. The raw files saved on 2026-09-25 are the frozen copy.

## Result

| Layer | Total | With coords | Primary source |
|---|---|---|---|
| radars | 17 | 16 | WMO Radar Database (wrd.mgm.gov.tr), 16 SAWS radars (10 Operational, 6 Closed), plus Venetia Mine (no coords) |
| surface_stations | 188 | 188 | WMO OSCAR/Surface, territory ZAF, WMO block-68 land stations (169 Operational, 3 Silent, 16 Closed) |
| river_gauges | 531 | 531 | WMO OSCAR/Surface, DWS WHYCOS stations with H-type codes (all declared Operational) |
| lightning_sensors | 26 | 0 | SAWS EW4All Roadmap 2025-2029 (count only) |
| satellites | 17 | n/a | WMO OSCAR/Space satellite pages and the EUMETSAT Meteosat series page |

## Steps and decisions

1. **Radars.** The WMO Radar Database has a public DataTables endpoint (`POST /Radar/Search`, with the CSRF token taken from `/Radar/List`). Searching "South Africa" returns 16 records with coordinates, band, polarisation, manufacturer and status.
   - The OR Tambo X-band record is stored at 25N 54E, which is outside South Africa and so an error. Its position was replaced with the OSCAR/Surface "RADAR Ort" record (-26.143, 28.2346; status Silent/Planned). That record uses the same coordinates as the JNB airport synoptic station, so it marks the airport rather than a surveyed radar site. This is flagged in the point's `note`.
   - Six radars also have dedicated OSCAR "RADAR ..." records. Five of them sit at the WRD position (0 km apart); the sixth is the OR Tambo record above.
   - The WRD Irene position (-25.9119, 28.2108) matches Becker (2014), which gives 25.91 S, 28.21 E. This is an independent check.
   - Venetia Mine is on SAWS's 2024/25 Tier-1 radar list but appears in neither WRD nor OSCAR. No coordinates were found, so it is counted but not plotted.
   - WRD's 10 operational radars (9 S-band plus 1 C-band at Cape Town) plus Venetia give 11. That matches the SAWS figure of 11 (10 S, 1 C), but the match is an inference.
   - Status is WRD's declared status. The operational records were last updated in Jan 2020, so status is not live uptime.
2. **Surface stations.** The OSCAR REST search `.../rest/api/search/station?territoryName=ZAF` returns all 1,781 ZAF records in one JSON response. Kept: "Land (fixed)" records with a WIGOS id `0-20000-0-68xxx` or `0-710-0-68xxx`, inside lat -35.5..-22 and lon 16..33.5.
   - This leaves out Marion Island and SANAE, ships, Argo floats, the RADAR records and GAW/INDAAF/BSRN research sites.
   - OSCAR territory is ZAF for all records, so no Lesotho or Eswatini stations are included.
   - Cross-check against NOAA ISD (`isd-history.csv`, CTRY = SF): 290 stations inside the box, 173 with data in 2025. The ISD file only runs to 2025-08-28. 175 of the 188 OSCAR stations match an ISD station by WMO index (USAF = index x 10), and their `isd_last_obs` value is included.
   - These points are only the WMO-registered subset. SAWS reports 265 AWS and 156 automatic rainfall stations, but publishes no coordinate list for them.
3. **River gauges.** DWS registers 1,567 hydrological stations in OSCAR under WHYCOS, all with coordinates.
   - Station type comes from the DWS code letter. H means a river flow-gauging station: the DWS near-real-time page shows them with Stage/Flow and marks the R stations as dams, and the DWS KMZ layers are named "H_his: River hydrological data" and "R_his: Dam hydrological data".
   - 531 of the 1,567 are H stations and are plotted.
   - 1,025 are N stations, which are groundwater monitoring sites. For A1N0001 the OSCAR WMDR record gives observed variable "Groundwater level" (code 166). These are not plotted.
   - 1 R station and 9 L stations are not plotted.
   - How many currently report is **unknown**: OSCAR's assessed status is "Unknown". The only reporting evidence found is a Wayback copy (1 Jun 2023) of the DWS real-time page for the Vaal WMA only: 47 stations, of which 2 showed "no data".
   - Historical scale for comparison: 782 gauged positions at end-2007 (Wessels & Rooseboom 2009, Water SA 35(1)).
4. **Lightning.** The count of 26 is from the SAWS EW4All Roadmap (Wayback copy, as cited in `data/forecasting_infrastructure.json`). No published sensor locations were found.
5. **Satellites.** Orbit, longitude, equator-crossing time, status and instrument list are parsed from WMO OSCAR/Space pages. The fleet roles and scan rates come from the EUMETSAT Meteosat series page.
   - `saws_receives`: the only SAWS-specific statement found is Becker (2014): "The SAWS also has access to Meteosat Second Generation (MSG) data." It is applied to the MSG satellites with the caveat that it does not name a satellite.
   - All other satellites are "not documented". No source was found for SAWS reception of Meteosat-12 or of any polar orbiter.
   - Great-circle distances from Pretoria to the Meteosat-9 (45.5E) and FY-2H (79E) sub-satellite points were computed from coordinates.

## Could not obtain

- **DWS station catalogue** (dws.gov.za/Hydrology, HyCatalogue.aspx, H_his.kmz): HTTP 403 to scripted requests and to WebFetch. The Wayback CDX returned 503/429, and the other WMA real-time pages sit behind ASP.NET postbacks. There is therefore no official current count of gauges or of how many report in real time.
- **GRDC catalogue**: not tried in depth, because it needs the interactive portal. Cross-checking against it is still open.
- **Venetia Mine radar coordinates.**
- **Lightning sensor locations.**
- **SAWS full AWS/rainfall station list with coordinates.**
- **Documentation that SAWS receives Meteosat-12 or any polar orbiter.**
- **Radar range statement.** The coverage note says Becker (2014) shows 200 km and 300 km range rings, but that wording comes from a search-index extract. The PDF (saved as `becker_2014_irene_qpe.pdf`) could not be text-extracted here, so check it against the document before quoting.
- **Metop AHRPT 1,500 km radius.** This also comes from a search-index extract of the EUMETSAT direct-dissemination page, which returned 403 to scripted access.

## Things to note for the visualisation

- Radar and station status values are **declared** metadata, not measured uptime. SAWS's own reported radar data availability was 44-80% in 2020-2025.
- The OSCAR station report pages include personal contact details (names and emails of metadata editors). The script only uses the search-list endpoint, and no personal data is written to the output.
