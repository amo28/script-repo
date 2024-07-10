# batch scripts

- NAS_Samba_Access_Check.bat -- Batch script which uses putty/plink function. Designed to run as a scheduled task and check NAS shares for accessibility. It attempts to map a share as a local drive using two different user credentials. If one of them fails, it issues a restart to the Samba service on the NAS, then tries again. Written to workaround an ongoing issue with QNAP NAS's where permissions would lock out for an unknown reason.
