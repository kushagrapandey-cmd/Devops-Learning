"""Host checks and streaming JSONL incident summaries. No shell execution."""
import argparse
import json
from collections import Counter
from pathlib import Path
from sentinel.health import snapshot


def summarize(lines):
    counts = Counter()
    malformed = 0
    for line in lines:
        try:
            entry = json.loads(line)
            if not isinstance(entry, dict):
                raise ValueError("record must be an object")
            status = entry.get("status")
            if type(status) is int and 100 <= status <= 599:
                counts[status] += 1
            else:
                malformed += 1
        except (ValueError, TypeError):
            malformed += 1
    total = sum(counts.values())
    failed = sum(count for code, count in counts.items() if code >= 500)
    return {"requests": total, "server_errors": failed,
            "error_percent": round(100 * failed / total, 2) if total else 0,
            "malformed_or_non_request_lines": malformed,
            "by_status": dict(sorted(counts.items()))}


def percent(value):
    value = float(value)
    if not 0 <= value <= 100:
        raise argparse.ArgumentTypeError("expected percentage between 0 and 100")
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    check = sub.add_parser("check")
    check.add_argument("--disk-path", default="/")
    check.add_argument("--disk-threshold", type=percent, default=85)
    check.add_argument("--memory-threshold", type=percent, default=90)
    logs = sub.add_parser("logs")
    logs.add_argument("file", type=Path)
    logs.add_argument("--error-threshold", type=percent, default=5)
    args = parser.parse_args()
    try:
        if args.command == "check":
            result = snapshot(args.disk_path, args.disk_threshold, args.memory_threshold)
            code = 1 if result["alerts"] else 0
        else:
            with args.file.open() as source:
                result = summarize(source)
            code = 2 if not result["requests"] else int(result["error_percent"] >= args.error_threshold)
        print(json.dumps(result, indent=2))
        return code
    except (OSError, ValueError, KeyError) as exc:
        print(json.dumps({"error": str(exc)}))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
