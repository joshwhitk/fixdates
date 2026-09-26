# fixdates

A Windows PowerShell utility that derives photo/video dates from _YYYYMMDD_ filename segments and writes them with ExifTool.

## Scope and status

- The script expects ExifTool at C:\Program Files\exiftool\exiftool.exe. It scans supported media recursively, reports mismatches and waits for Enter before writing.
- It writes CreateDate, FileCreateDate and FileModifyDate at midnight, and uses -overwrite_original. Work on a copy when preserving the original dates matters.
- Files without the delimited date pattern or with a year outside 2000 through the current year are skipped.

## Local development

```powershell
powershell -File .\fixdates.ps1 -TargetFolder 'C:\path\to\a-copy-of-your-media'
```

Documentation reviewed from source and available project history on 2026-09-27. The application was not started or acceptance-tested as part of this documentation update.
