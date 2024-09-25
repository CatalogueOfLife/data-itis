# ITIS to CoLDP Conversion Tool

Using [Docker Compose](https://docs.docker.com/compose/), this data pipeline automatically converts [ITIS.gov's monthly MySQL export](https://www.itis.gov/downloads/index.html) to [CoLDP](https://github.com/CatalogueOfLife/coldp) format for publishing in [ChecklistBank](https://www.checklistbank.org). The utility checks for an update from ITIS, downloads the update, imports it into a docker MySQL database, converts the data to CoLDP format and then exports the data as tab-delimited text files in the coldp directory.

# Use

1) Clone the repository:

```
git clone https://github.com/catalogueoflife/data-itis.git
```

2) The ITIS database does not provide extinct statuses so ask for an updated list of extinct TSNs from ITIS and update the raw/extinct.tsv

3) Run the docker conversion container (replacing DATABASE_PASSWORD with any password you want):

```
DATABASE_PASSWORD=password COL_USER=user COL_PASS=pass COL_API=api_host COL_DATASET_ID=2144 docker-compose run conversion
```

If the optional environment variables `COL_USER`, `COL_PASS`, `COL_API`, and `COL_DATASET_ID` are provided, the dataset will be automatically uploaded into ChecklistBank.

