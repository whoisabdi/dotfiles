#!/usr/bin/env sh

# 1. CPU & Memory stats in single awk pass
stats=$(awk '
BEGIN {
  if ((getline < "/tmp/.cpu_prev") > 0) {
    prev_total = $1; prev_idle = $2;
  } else {
    prev_total = 0; prev_idle = 0;
  }
  close("/tmp/.cpu_prev");
}
/^cpu / {
  total = $2+$3+$4+$5+$6+$7+$8;
  idle = $5;
  diff_total = total - prev_total;
  diff_idle = idle - prev_idle;
  if (diff_total > 0) {
    cpu_pct = int((diff_total - diff_idle) * 100 / diff_total);
    if (cpu_pct < 0) cpu_pct = 0;
    if (cpu_pct > 100) cpu_pct = 100;
  } else {
    cpu_pct = 0;
  }
  system("echo " total " " idle " > /tmp/.cpu_prev");
}
/^MemTotal:/ { mem_total = $2 }
/^MemAvailable:/ { mem_avail = $2 }
END {
  used_mb = (mem_total - mem_avail) / 1024;
  total_mb = mem_total / 1024;
  mem_pct = int((mem_total - mem_avail) * 100 / mem_total);
  printf "%d|%.1f|%.1f|%d", cpu_pct, used_mb / 1024, total_mb / 1024, mem_pct;
}
' /proc/stat /proc/meminfo)

# 2. CPU Temperature (°C)
temp_file=$(ls /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input 2>/dev/null | head -n 1)
if [ -n "$temp_file" ] && [ -r "$temp_file" ]; then
  temp_raw=$(cat "$temp_file")
elif [ -r /sys/class/thermal/thermal_zone12/temp ]; then
  temp_raw=$(cat /sys/class/thermal/thermal_zone12/temp)
else
  temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
fi
cpu_temp=$((temp_raw / 1000))

# 3. CPU Clock Speed (MHz)
freq_raw=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq 2>/dev/null || echo 0)
cpu_mhz=$((freq_raw / 1000))

# 4. GPU Temperature (°C)
gpu_temp=""
if command -v nvidia-smi >/dev/null 2>&1; then
  gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n 1)
fi
if [ -z "$gpu_temp" ] || [ "$gpu_temp" -le 0 ] 2>/dev/null; then
  for f in /sys/class/drm/card[0-9]/device/hwmon/hwmon*/temp1_input; do
    if [ -r "$f" ]; then
      gpu_temp=$(($(cat "$f" 2>/dev/null) / 1000))
      break
    fi
  done
fi
if [ -z "$gpu_temp" ] || [ "$gpu_temp" -le 0 ] 2>/dev/null; then
  # Intel integrated GPU (shares package die temp, matching HyDE)
  gpu_temp=$cpu_temp
fi

# Output: cpu_pct|mem_used|mem_total|mem_pct|cpu_temp|cpu_mhz|gpu_temp
echo "${stats}|${cpu_temp}|${cpu_mhz}|${gpu_temp}"
