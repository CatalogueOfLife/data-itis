import os, glob, re, requests
import yaml
from requests.auth import HTTPBasicAuth

DATABASE_PASSWORD = os.environ.get('DATABASE_PASSWORD')
COL_API = os.environ.get('COL_API')
print('API: ' + COL_API)
COL_USER = os.environ.get('COL_USER')
print('API User: ' + COL_USER)
COL_PASS = os.environ.get('COL_PASS')
COL_DATASET_ID = os.environ.get('COL_DATASET_ID')

# Wait for database to startup
os.system('sleep 10')

# Remove previous conversion
print('\nRemoving previous conversion...')
try:
    files = glob.glob('/home/col/coldp/*.tsv')
    for f in files:
        os.remove(f)

    os.remove('/home/col/coldp/coldp.zip')
    os.remove('/home/col/raw/itisMySQLBulk.zip')
except FileNotFoundError as e:
    pass

# Download data
print('\nDownloading ITIS data...\n\n')
#os.system('cd /home/col/raw; wget ftp://ftpext.usgs.gov/pub/cr/co/denver/itis/itisMySQLBulk.zip')
os.system('cd /home/col/raw; wget https://www.itis.gov/downloads/itisMySQLBulk.zip')

# Unzip data
print('Uncompressing ITIS data...\n\n')
os.system('cd /home/col/raw; unzip -o itisMySQLBulk.zip')

# Get release date
release_date = ''
extract_directory = ''
directories = glob.glob("/home/col/raw/*/")
for d in directories:
    if re.search('^/home/col/raw/itisMySQL([0-9]{2})([0-9]{2})([0-9]{2})/$', d):
        release_date = re.sub(r'^/home/col/raw/itisMySQL([0-9]{2})([0-9]{2})([0-9]{2})/$', r'20\3-\1-\2', d)
        extract_directory = d
print('\nITIS release date: ' + release_date + '\n\n')

# Import data into MySQL
print('Importing ITIS data into MySQL database...\n\n')
os.system('cd ' + extract_directory + '; mysql -hdatabase -uroot -p' + DATABASE_PASSWORD + ' < CreateDB.sql')

# Convert the data to CoLDP
print('Converting ITIS data to CoLDP format...\n\n')
os.system('cd /home/col/scripts; cat convert.sql | mysql -hdatabase -uroot -p' + DATABASE_PASSWORD)

# Dump tsv files
#os.system('cd /home/col/coldp; mysqldump -hdatabase -uroot -p' + DATABASE_PASSWORD + ' --tab=/home/col/coldp coldp')
print('Exporting data to tab delimited files in CoLDP format...\n\n')
os.system('cd /home/col/coldp; mysql -B -uroot -p' + DATABASE_PASSWORD + ' -hdatabase coldp -e "SELECT * FROM Name" > Name.tsv')
os.system('cd /home/col/coldp; mysql -B -uroot -p' + DATABASE_PASSWORD + ' -hdatabase coldp -e "SELECT * FROM Taxon" > Taxon.tsv')
os.system('cd /home/col/coldp; mysql -B -uroot -p' + DATABASE_PASSWORD + ' -hdatabase coldp -e "SELECT * FROM Synonym" > Synonym.tsv')
os.system('cd /home/col/coldp; mysql -B -uroot -p' + DATABASE_PASSWORD + ' -hdatabase coldp -e "SELECT * FROM VernacularName" > VernacularName.tsv')
os.system('cd /home/col/coldp; mysql -B -uroot -p' + DATABASE_PASSWORD + ' -hdatabase coldp -e "SELECT * FROM Distribution" > Distribution.tsv')
os.system('cd /home/col/coldp; mysql -B -uroot -p' + DATABASE_PASSWORD + ' -hdatabase coldp -e "SELECT * FROM Reference" > Reference.tsv')

# Update metadata (for now just release date)
#  TODO: add other metadata?
yaml_dict = {'released': release_date, 'version': release_date}
with open('/home/col/coldp/metadata.yaml', 'w') as yaml_file:
    documents = yaml.dump(yaml_dict, yaml_file)

# Compress CoLDP files and metadata
print('Compressing CoLDP files...')
os.system('cd /home/col/coldp; zip coldp.zip *.tsv')
os.system('cd /home/col/coldp; zip coldp.zip metadata.yaml')

# Upload data to Clearinghouse
if COL_USER != '' and COL_PASS != '' and COL_DATASET_ID != '' and COL_API != '':
    print('Uploading data to CoL Clearinghouse...')
    login_url = COL_API + '/user/login'
    r = requests.get(login_url, auth=HTTPBasicAuth(COL_USER, COL_PASS))

    print('\n\tAttempting login...\n')
    print('\tResponse code: ' + str(r.status_code))
    bearer = r.text
    print('\tBearer: ' + bearer)
    headers = {'Authorization': 'Bearer ' + bearer, 'Content-Type':  'application/octet-stream'}

    print('\n\tUploading file...')
    importer_url = COL_API + '/importer/' + COL_DATASET_ID
    files = {'file': open('/home/col/coldp/coldp.zip', 'rb')}
    r = requests.post(importer_url, headers=headers, files=files)
    print('\tResponse code: ' + str(r.status_code))
    print('\t' + r.text)

# Remove uncompressed files and directory
print('Cleaning up temporary files...\n\n')
files = glob.glob(extract_directory + '*')
for f in files:
    os.remove(f)
os.rmdir(extract_directory)
