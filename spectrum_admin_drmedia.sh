#spectrum_admin_drmedia.sh
#Weekly Spectrum Protect maintenance script with media rotation

spectrum_admin="dsmadmc -id=admin -pass=password"

$spectrum_admin checkin libv LIB-TS3310 search=bulk status=scratch checklabel=barcode waitt=0

sleep 60

$spectrum_admin expire inventory quiet=yes

$spectrum_admin migrate stgpool SPACEMGDISK lo=0 wait=yes

$spectrum_admin migrate stgpool NAS-DISK lo=0 wait=yes

$spectrum_admin backup stgpool PRI_TAPE OFFSITE maxprocess=2 wait=yes

$spectrum_admin backup stgpool VM_DEDUPE_FILE OFFSITE maxprocess=2 wait=yes

sleep 20

$spectrum_admin identify duplicates VM_DEDUPE_FILE numprocess=8 duration=180

sleep 10810

$spectrum_admin reclaim stgpool VM_DEDUPE_FILE threshold=80 duration=180 wait=yes

$spectrum_admin reclaim stgpool PRI_TAPE threshold=70 duration=180 wait=yes

$spectrum_admin reclaim stgpool SPACEMGPOOL threshold=70 duration=120 wait=yes

sleep 2

$spectrum_admin reclaim stgpool OFFSITE threshold=70 offsitereclaimlimit=4 duration=180 wait=yes

sleep 2

### Move DR media onsite

echo "Tapes to be brought back onsite" > /admin/scripts/tapesonsite.txt
$spectrum_admin q drmedia wherestate=vaultretrieve >> /admin/scripts/tapesonsite.txt

sleep 2

mail -s "Tapes to be brought back onsite" </admin/scripts/tapesonsite.txt email@work.com

$spectrum_admin delete volhistory t=dbbackup todate=today-3

sleep 2

$spectrum_admin move drmedia "*" wherestate=vaultretrieve tostate=onsiteretrieve wait=yes

## DB Backup

$spectrum_admin backup db devclass=LTO7_DEVC t=full wait=yes

### Move DR media offsite

echo "Tapes to be sent offsite" > /admin/scripts/tapesoffsite.txt
$spectrum_admin q drmedia source=dbbackup wherestate=Mountable >> /admin/scripts/tapesoffsite.txt

sleep 2

mail -s "Tapes to be sent offsite" </admin/scripts/tapesoffsite.txt email@work.com

$spectrum_admin move drmedia "*" source=dbbackup wherestate=Mountable tostate=Vault wait=yes

sleep 5

### DR processing

$spectrum_admin backup volhist filenames=/admin/dr_files/volhist.dat

$spectrum_admin backup devconfig filenames=/admin/dr_files/devconfig.dat

$spectrum_admin prepare source=DBbackup

$spectrum_admin audit license

sleep 5

scp -p /admin/dr_files/* ci-dr-sp-s:/admin/dr_files/
