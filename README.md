# Linux-windows-cpu-scaler
  
Zero-dependency Linux bash script replicating Windows' native Processor Power Management (PPM) for CPU frequency scaling.  
auto-detected hardware min/max/boost frequencies via sysfs. so that the scheduler can operate inside those values  
Compatible with Arch, Ubuntu, and all systemd-based distros.
  
 Stop script from autostarting if you ran setup_autostart.sh
```bash
systemctl stop cpu-scaling
systemctl disable cpu-scaling
```
  
<img width="2559" height="1439" alt="cpu2" src="https://github.com/user-attachments/assets/9ac0c8c5-a9ce-40dc-9777-ffedd42dadfe" />
<img width="2543" height="1439" alt="cpu1" src="https://github.com/user-attachments/assets/772cef8f-84bd-42d3-9fe6-5105332b27b4" />

if the script changed something in a wierd way you can reset everthing with 
```bash
sudo cpupower frequency-set -d $(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq) -u $(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
```
