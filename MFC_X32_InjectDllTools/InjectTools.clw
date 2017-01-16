; CLW file contains information for the MFC ClassWizard

[General Info]
Version=1
LastClass=CInjectToolsDlg
LastTemplate=CDialog
NewFileInclude1=#include "stdafx.h"
NewFileInclude2=#include "InjectTools.h"

ClassCount=3
Class1=CInjectToolsApp
Class2=CInjectToolsDlg
Class3=CAboutDlg

ResourceCount=3
Resource1=IDD_ABOUTBOX
Resource2=IDR_MAINFRAME
Resource3=IDD_INJECTTOOLS_DIALOG

[CLS:CInjectToolsApp]
Type=0
HeaderFile=InjectTools.h
ImplementationFile=InjectTools.cpp
Filter=N

[CLS:CInjectToolsDlg]
Type=0
HeaderFile=InjectToolsDlg.h
ImplementationFile=InjectToolsDlg.cpp
Filter=D
BaseClass=CDialog
VirtualFilter=dWC
LastObject=CInjectToolsDlg

[CLS:CAboutDlg]
Type=0
HeaderFile=InjectToolsDlg.h
ImplementationFile=InjectToolsDlg.cpp
Filter=D

[DLG:IDD_ABOUTBOX]
Type=1
Class=CAboutDlg
ControlCount=4
Control1=IDC_STATIC,static,1342177283
Control2=IDC_STATIC,static,1342308480
Control3=IDC_STATIC,static,1342308352
Control4=IDOK,button,1342373889

[DLG:IDD_INJECTTOOLS_DIALOG]
Type=1
Class=CInjectToolsDlg
ControlCount=6
Control1=IDC_EDIT_DLLPATH,edit,1350631552
Control2=IDC_STATIC,static,1342308865
Control3=IDC_BTN_GETDLLPATH,button,1342242816
Control4=IDC_EDIT_DST_NAME,edit,1484849280
Control5=IDC_STATIC,static,1342308865
Control6=IDC_BTN_INJECT,button,1476460544

