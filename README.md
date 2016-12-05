# solar_nn

A Matlab script to calculate the total surface solar radiation (GHI) in W/m2
over a region specified by a LAT_LON.mat meshgrid.

To run at the Matlab command line, the user will need to download and install
the mapping package: m_map [Rich Pawlowicz: https://www.eoas.ubc.ca/~rich/map.html].
For visualization, the global self-consistent, hierarchical, high-resolution
geography (GSHHG) intermediate resolution file is needed: https://www.ngdc.noaa.gov/mgg/shorelines/gshhs.html].

The code uses 5 freely available m-files from the Matlab File Exchange:

  ignoreNaN.m [Matt G, Matlab file exchange: http://bit.ly/2h7YwAF]
  is_Daylight_Savings.m [Nate, Matlab file exchange: http://bit.ly/2h7QTud]
  rgb.m [Chad Greene, Matlab file exchange: http://bit.ly/1osmxpT]
  rgbmap.m [Chad Greene, Matlab file exchange: http://bit.ly/2gvsgaK]
  rgb.txt [Randall Munroe, XKCD colour survey: http://xkcd.com/color/rgb.txt].

See the DEPENDENCIES file for updates.

INPUT FILES:

The user will need to place *.COT files and corresponding *.h5 files
(plus AOD *.mat files if available) in the sub-directory: TEST_DATA/
