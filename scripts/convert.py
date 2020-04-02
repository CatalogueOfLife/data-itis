import os, glob, re, requests
from requests.auth import HTTPBasicAuth

# Get database password
DATABASE_PASSWORD = os.environ.get('DATABASE_PASSWORD')
COL_API = os.environ.get('COL_API')
print(COL_API)
COL_USER = os.environ.get('COL_USER')
print(COL_USER)
COL_PASS = os.environ.get('COL_PASS')
COL_DATASET_ID = os.environ.get('COL_DATASET_ID')


# Remove previous conversion
print('\nRemoving previous conversion...')
files = glob.glob('/home/col/coldp/*.tsv')
for f in files:
    os.remove(f)
os.remove('/home/col/coldp/coldp.zip')

# Download data
print('\nChecking for updated ITIS download...\n\n')
os.system('cd /home/col/raw; wget -c -N https://www.itis.gov/downloads/itisMySQLBulk.zip')

# Unzip data
print('Uncompressing ITIS data...\n\n')
os.system('cd /home/col/raw; unzip -o itisMySQLBulk.zip')

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

# Compress CoLDP files
print('Compressing CoLDP files...')
os.system('cd /home/col/coldp; zip coldp.zip *.tsv')

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
