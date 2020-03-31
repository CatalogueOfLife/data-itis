import os

# Download data
os.system('echo "Checking for updated ITIS download..."')
os.system('cd /home/col/raw; wget -c -N https://www.itis.gov/downloads/itisMySQLBulk.zip')
os.system('sleep 4')

# Unzip data
os.system('echo "Uncompressing ITIS data..."')
os.system('cd /home/col/raw; unzip -o itisMySQLBulk.zip')

# Import data into MySQL
os.system('echo "Importing ITIS data into MySQL database..."')
os.system('cd /home/col/raw/itisMySQL022620; mysql -hdatabase -uroot -pbiodiversity < CreateDB.sql')

# Convert the data to CoLDP
os.system('echo "Converting ITIS data to CoLDP format..."')
os.system('cd /home/col/scripts; cat convert.sql | mysql -hdatabase -uroot -pbiodiversity')

# Dump tsv files
#os.system('cd /home/col/coldp; mysqldump -hdatabase -uroot -pbiodiversity --tab=/home/col/coldp coldp')
os.system('echo "Exporting data to tab delimited files in CoLDP format..."')
os.system('cd /home/col/coldp; mysql -B -uroot -pbiodiversity -hdatabase coldp -e "SELECT * FROM Name" > Name.tsv')
os.system('cd /home/col/coldp; mysql -B -uroot -pbiodiversity -hdatabase coldp -e "SELECT * FROM Taxon" > Taxon.tsv')
os.system('cd /home/col/coldp; mysql -B -uroot -pbiodiversity -hdatabase coldp -e "SELECT * FROM Synonym" > Synonym.tsv')
os.system('cd /home/col/coldp; mysql -B -uroot -pbiodiversity -hdatabase coldp -e "SELECT * FROM VernacularName" > VernacularName.tsv')
os.system('cd /home/col/coldp; mysql -B -uroot -pbiodiversity -hdatabase coldp -e "SELECT * FROM Distribution" > Distribution.tsv')
os.system('cd /home/col/coldp; mysql -B -uroot -pbiodiversity -hdatabase coldp -e "SELECT * FROM Reference" > Reference.tsv')
