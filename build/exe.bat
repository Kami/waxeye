
MKDIR tmp
C:\"Program Files\PLT\mzc.exe" --exe waxeye src\waxeye\waxeye.scm
MOVE waxeye.exe tmp\waxeye.exe
C:\"Program Files\PLT\mzc.exe" --exe-dir . tmp\waxeye.exe
RMDIR /S tmp
