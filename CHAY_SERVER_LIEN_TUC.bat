@echo off
chcp 65001 >nul
title [MAY CHU WEB API - TU MINH HIEN] DANG HOAT DONG XUYEN SUOT

echo ======================================================================
echo    HỆ THỐNG MÁY CHỦ WEB API ĐIỂM DANH SINH VIÊN - TỪ MINH HIỂN
echo ======================================================================
echo  * Swagger API (Local):  http://127.0.0.1:5276/swagger
echo  * Swagger API (LAN/Wi-Fi): http://192.168.1.47:5276/swagger
echo  * Database SQL Server:  .\SQLEXPRESS -> 0630_TuMinhHien_WebAPI
echo.
echo  * Tài khoản Admin:      admin01   / AdminPassword123!
echo  * Tài khoản Giảng viên: staff01   / StaffPassword123!
echo  * Tài khoản Sinh viên:  sinhvien01 / StudentPass123! (MSSV: 20260630)
echo ======================================================================
echo.
echo [INFO] Dang khoi dong va duy tri may chu hoat dong xuyen suot...
echo [INFO] Neu xay ra su co tat bat ngo, script se tu dong khoi dong lai sau 3 giay.
echo.

cd /d "C:\Users\Admin\source\repos\0630_TuMinhHien_WebAPI\0630_TuMinhHien_WebAPI\0630_TuMinhHien_WebAPI"

:loop
echo [%date% %time%] Khoi chay Web API...
dotnet run --no-build
echo.
echo [CANH BAO] May chu da dung! Dang tu dong khoi dong lai sau 3 giay...
timeout /t 3 /nobreak >nul
goto loop
