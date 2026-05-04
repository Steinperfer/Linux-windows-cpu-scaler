# Linux-cpu-freq/governors-manager
  
Zero-dependency Linux bash script replicating Windows' native Processor Power Management (PPM) for CPU frequency scaling.
auto-detected hardware min/max/boost frequencies via sysfs for the governors in this ca ondemand, can operate inside those values  
Compatible with Arch, Ubuntu, and all systemd-based distros.

# Why?  
This script makes that your cpu is running in powersave while having low usage  
and automaticly scales the Frequency depending on the load, 
So that you can brwose the internet without a noisy fan. 
  
# Install  
```bash
git clone https://github.com/Steinperfer/Linux-windows-cpu-scaler && cd Linux-windows-cpu-scaler && bash setup_autostart.sh
```
  
<img width="2559" height="1439" alt="cpu2" src="https://github.com/user-attachments/assets/9ac0c8c5-a9ce-40dc-9777-ffedd42dadfe" />  
<img width="2543" height="1439" alt="cpu1" src="https://github.com/user-attachments/assets/772cef8f-84bd-42d3-9fe6-5105332b27b4" />  
Images not uptodate, more optimised  
  
Get Available governors:  
```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
```
Change the governors for the script with:  
```bash
 for c in /sys/devices/system/cpu/cpu*/cpufreq
      echo ondemand | sudo tee "$c/scaling_governor"
  end
```
 Stop script from autostarting if you ran setup_autostart.sh and wont to stop it:
```bash
systemctl stop cpu-scaling
systemctl disable cpu-scaling
```
if the script changed something in a wierd way you can reset everthing with 
```bash
sudo cpupower frequency-set -d $(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq) -u $(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
```
