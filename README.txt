Armen Enikolopov
January 2025
"High resolution implementation of the Holdridge Life Zone system with
transitional zones and altitudinal belts"
Submitted. Full text forth coming. 

Interactive view available at: https://aenikolopov.projects.earthengine.app/view/hlz
Code available: https://github.com/armenenikolopov/HoldridgeLifeZoneMap
Data available: 10.6084/m9.figshare.28236242

ABSTRACT:
The Holdridge Life Zone (HLZ) system is a widely used framework for ecological classification, yet existing implementations suffer from coarse resolution and inaccurate evapotranspiration estimates. We present the first global 30-arcsecond (~1 km²) global HLZ map, a 3600x improvement over currently available models, addressing critical limitations of previous models. This high-resolution approach is particularly important in topographically complex regions such as the Tropical Andes, where elevation-driven climate changes occur over short distances and are missed in lower-resolution models. Additionally, many transitional life zones predicted by Holdridge are only visible when mapped at fine scales, making this model especially useful for field-based ecological studies and herbarium specimen attribution rather than broad-scale climate applications.
A key weakness of the traditional HLZ system is its reliance on a simplified evapotranspiration approximation, which we demonstrate to be several-fold inaccurate outside the tropics and significantly flawed even within them. We provide the first quantitative assessment of where these errors are most severe and introduce a high-resolution alternative using the Penman-Monteith model for improved classification accuracy, particularly in non-tropical regions. These resulting classification differences are discussed.  To support broad adoption, we provide open-source code, downloadable datasets, and an interactive web tool for zone determination. This refined HLZ implementation enables more precise ecological fieldwork, floristic studies, biogeographical studies, and climate impact assessments at local scales.


CONTENTS

HLZ_Classical.tif
    GeoTIFF format map at 30 arcsecond resolution of Holdridge Life Zones. 
    Implemented with altitudinal belts and transitional life zones. Uses
    Holdridge 1967 potential evapotranspiration estimate.  Map values 
    correspond to descriptions in HLZ_Codes_Classical.csv. 

HLZ_Penman-Monteith.tif
    GeoTIFF format map at 30 arcsecond resolution of Holdridge Life Zones,
    implemented with Penman-Monteith equation for evapotranspiration. 
    Altitudinal belts included, transitional life zones excluded. See paper
    for details.  Map values correspond to descriptions in 
    HLZ_Codes_Penman-Monteith.csv.
                   
HLZ_Codes_Classical.csv
    2 columns, Code and Name, corresponding to values in the geoTIFF maps
    described above. For each code in column 1, column 2 is a descriptive
    name per Holdridge 1967 of that zone. Applies to classical implementation.
    Example: "17454,warm temperate montane moist forest - hyperpluvial transitional life zone"

HLZ_Codes_Penman-Monteith.csv
    As above. Applies to Penman-Monteith implementation. 
