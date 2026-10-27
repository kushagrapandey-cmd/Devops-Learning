"""Read Linux host-visible metrics. These are not container usage metrics."""
import os
import shutil
from datetime import datetime, timezone
from pathlib import Path


def memory_percent(path=Path("/proc/meminfo")):
    values = {}
    for line in path.read_text().splitlines():
        key, value = line.split(":", 1)
        values[key] = int(value.split()[0])
    total = values["MemTotal"]
    if total <= 0:
        raise ValueError("MemTotal must be positive")
    return round(100 * (1 - values["MemAvailable"] / total), 2)


def snapshot(disk_path="/", disk_threshold=85, memory_threshold=90):
    disk = shutil.disk_usage(disk_path)
    disk_pct = round(disk.used / disk.total * 100, 2)
    memory_pct = memory_percent()
    load = os.getloadavg()[0]
    alerts = []
    for name, value, limit in (("disk", disk_pct, disk_threshold),
                               ("memory", memory_pct, memory_threshold)):
        if value >= limit:
            alerts.append({"resource": name, "percent": value, "threshold": limit})
    return {"timestamp": datetime.now(timezone.utc).isoformat(),
            "scope": "host-visible; not cgroup/container utilization",
            "disk_path": disk_path, "disk_percent": disk_pct,
            "memory_percent": memory_pct, "load_1m": load,
            "status": "warning" if alerts else "ok", "alerts": alerts}
