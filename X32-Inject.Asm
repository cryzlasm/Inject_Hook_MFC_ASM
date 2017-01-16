.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include FirstDlg.inc

.code

start:
	invoke GetModuleHandle,NULL
	mov		hInstance,eax

    	invoke InitCommonControls
	invoke DialogBoxParam,hInstance,IDD_INJECT,NULL,addr DlgProc,NULL
	invoke ExitProcess,0

;########################################################################

DlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG

	.elseif eax==WM_COMMAND
		mov eax, wParam
		.if eax == BTN_INJECT
			invoke InjectCode
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

begin_label: 
	call $+5  ;重定位
NEXT:
	pop ebp
	sub ebp, NEXT
	push MB_OK
	
	lea eax, [ebp + offset g_szTitle]
	push eax
	
	lea eax, [ebp + offset g_szMsg]
	push eax
	
	push NULL
	mov eax, [ebp + offset g_pfnMessageBox]
	call eax
	ret
	g_szTitle db 'Title', 0
	g_szMsg db 'Hello World', 0
	g_pfnMessageBox DWORD 0
	;g_pfnLoadLibrary DWORD 0
	;g_pfnGetProcAddress DWORD 0
end_label:
InjectCode proc
	LOCAL @hCalc:HWND
	LOCAL @dwPid :dword
	LOCAL @hProcess :HANDLE
	LOCAL @lpBuff :PVOID
	LOCAL @hUser:HANDLE
	LOCAL @oldProtect:DWORD
	LOCAL @lpMsgBox:PVOID
	
	invoke LoadLibrary, addr g_szUser32
	mov @hUser, eax
	;check
	
	invoke GetProcAddress, @hUser, addr g_szMsgBox
	mov @lpMsgBox, eax
	;check
	
	;修改内存保护属性
	invoke VirtualProtect, addr begin_label,  end_label -  begin_label, \
			PAGE_EXECUTE_READWRITE, addr @oldProtect
	;check
	
	mov eax, @lpMsgBox		
	mov g_pfnMessageBox, eax
	
	invoke VirtualProtect, addr begin_label,  end_label -  begin_label, \
			@oldProtect, addr @oldProtect
	;check
		
	invoke FreeLibrary,@hUser
	;check
	
	
	invoke FindWindow,NULL, addr g_szCalc
	mov @hCalc, eax
	;check
	
	invoke GetWindowThreadProcessId,@hCalc, addr @dwPid
	;check
	
	invoke OpenProcess, PROCESS_ALL_ACCESS, FALSE, @dwPid
	mov @hProcess, eax
	;check
	
	;申请内存
	invoke VirtualAllocEx, @hProcess, NULL, 1000h, MEM_COMMIT, PAGE_EXECUTE_READWRITE
	mov @lpBuff, eax
	;check
	
	;写入内存
	invoke WriteProcessMemory,@hProcess, @lpBuff, \
		addr begin_label, end_label - begin_label, NULL
	;check
	
	;创建远程线程
	invoke CreateRemoteThread,@hProcess, NULL, 0, @lpBuff, NULL, 0, NULL
	;check
	
	;释放内存
	invoke VirtualFreeEx,@hProcess, @lpBuff, 1000h, MEM_RELEASE
	;check
	ret

InjectCode endp
end start
