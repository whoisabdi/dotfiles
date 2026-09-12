#!/usr/bin/env sh
awk '
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
  if (used_mb >= 1024) mem_str = sprintf("%.1fG", used_mb / 1024);
  else mem_str = sprintf("%dM", used_mb);
  printf "%d%%|%s\n", cpu_pct, mem_str;
}
' /proc/stat /proc/meminfo
