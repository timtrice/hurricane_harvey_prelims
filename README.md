# hurricane_harvey_prelims

`hurricane_harvey_prelims` is an analysis project that has collected text products from the National Weather Service offices in Brownsville, Corpus Christi, Austin/San Antonio, and Houston, Texas, and Lake Charles, and New Orleans Louisiana. The project extracts and moves into tidy datasets the information obtained from these products.

The project consists of a report detailing the observations collected for rainfall, wind, and tornadic activity. The project also contains an explanation on how the data was obtained and how it was cleaned and formatted. 

The project uses the `workflowr` package as a means of organization, but it is not required to run the code.

## Getting Started

### Prerequisites

This project relies on text products dated at a specific time. The sites collected are:

* [Brownsville, TX (BRO)](ftp://tgftp.nws.noaa.gov/data/raw/ac/acus74.kbro.psh.bro.txt)

* [Corpus Christi, TX (CRP)](ftp://tgftp.nws.noaa.gov/data/raw/ac/acus74.kcrp.psh.crp.txt)

* [Austin/San Antonion, TX (EWX)](ftp://tgftp.nws.noaa.gov/data/raw/ac/acus74.kewx.psh.ewx.txt)

* [Houston, TX (HGX)](ftp://tgftp.nws.noaa.gov/data/raw/ac/acus74.khgx.psh.hgx.txt)

* [Lake Charles, LA (LCH)](ftp://tgftp.nws.noaa.gov/data/raw/ac/acus74.klch.psh.lch.txt)

* [New Orleans, LA (LIX)](ftp://tgftp.nws.noaa.gov/data/raw/ac/acus74.klix.psh.lix.txt)

#### Downloading Data

At any time the links above may be updated with new information on ***unrelated*** storm activity. Therefore, the products were downloaded at the original time of writing and saved. The raw products are saved in the ./data directory. The script to do this is ./code/01_download_data.R.

#### Data Cleaning

The script that performs the data extractions and transformations is ./code/02_parse_text.R. 

This script reads the downloaded text files, examines each section of each text file, and, using regex patterns, collects the information into it's appropriate dataset;

* `rain_df` - Rainfall observations

* `slp_df` - Sea Level Pressure observations

* `tor_df` - Tornado observations

#### Required Packages

* ggrepel 0.8.0

* knitr 1.21

* lubridate 1.7.4

* rrricanes 0.2.0-6.9000

* rrricanesdata 0.1.7

* tidyverse 1.2.1

* workflowr 0.2.0

## Built With

* [R 3.5.2](https://www.r-project.org/) - The R Project for Statistical Computing

## Contributing

Please read [Contributing](https://github.com/timtrice/hurricane_harvey_prelims/blob/master/.github/CONTRIBUTING.md) for details on code of conduct.

## Authors

* [Tim Trice](https://github.com/timtrice)

## License

[GNU GENERAL PUBLIC LICENSE](https://github.com/timtrice/hurricane_harvey_prelims/blob/master/LICENSE)
