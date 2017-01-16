.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include Hook_MsPaint.inc

.code

start:
        ;call InitInjectCode
        
	invoke GetModuleHandle,NULL
	mov		hInstance,eax

    invoke InitCommonControls
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke ExitProcess,0

;########################################################################

;<<<<<<<<<<<<<<<<<<<<
;   窗口过程函数
;>>>>>>>>>>>>>>>>>>>>
DlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG

	.elseif eax==WM_COMMAND
            .if wParam == IDC_BTN_HOOK
                invoke OnBtnHook
                
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


;<<<<<<<<<<<<<<<<<<<<
;   远程注入代码
;>>>>>>>>>>>>>>>>>>>>
Remote_Begin:
    ;重定位
    call $ + 5
    Relocate_Next:
    pop ebx
    sub ebx, Relocate_Next
    
    ;保存重定位
    ;mov [ebx + offset g_dwRelocate], ebx
    
    ;获取CreateFile的真实地址
    ;call  [ebx + offset GetCreateFileAddr]
    ;lea eax, offset GetCreateFileAddr
    ;lea eax, offset GetFunAddr
    ;add eax, ebx
    ;call  eax
    
    
    ;获取需要的函数地址
    lea eax, offset  GetFunAddr
    add eax, ebx
    call  eax
    .if eax == 0
            or eax, -1  ;线程退出 退出代码-1
            ret
    .endif
 
    ;计算偏移，HOOK CreateFile
    
    ;重定位
    call @f
    @@:
    Lable_Relocate:
    pop ebx
    mov edi, ebx            ;保存定位地址，用于计算HookApi  的CallBack
    sub ebx, offset @b
    
    ;Hook API
    lea eax, offset HookApi
    add eax, ebx
    call eax
    .if eax == 0
        or eax, -1
        ret
    .endif
    
    ;注入完成，远程线程退出
    or eax, 0
    ret
    ;jmp [ebx + g_pfnCreateFile + 5]
    
    
    ;==============CallBack Begin===============
    ;调用CreateFile会跳到这
    Lable_HookCallBack:

    ;保存寄存器环境
    pushad
    
    ;重定位
    call @f
    @@:
    pop eax
 
    ;计算重定位偏移
    mov ebx, eax
    sub ebx, offset @b
    
    mov eax, [ebx + g_bIsHook]
    .if eax == TRUE
        popad
                    
        ;获得CreateFile返回地址
        pop eax
        
        ;恢复HOOK修改的代码
        push ebp
        mov ebp, esp
        jmp eax

    .endif
    
    ;标记为HOOK 重入
    mov [ebx + g_bIsHook], TRUE
    
    
    ;CALL CreateLog
    lea eax, offset CreateLog
    add eax, ebx
    call eax
    .if eax == INVALID_HANDLE_VALUE
        or eax, -1
        ret
    .endif
    ;重定位
    call @f
    @@:
    pop ebx
    sub ebx, offset @b  
    
    mov [ebx + offset g_hFileHandle], eax
    
    ;调用写日志
    lea eax, offset  WriteLog
    add eax, ebx
    call  eax
    
    ;关闭文件
    mov eax, [ebx + g_hFileHandle]
    push eax
    call  [ebx + offset g_pfnCloseHandle]
    
    popad
    ;返回CreateFile函数
    ;jmp [ebx + g_pfnCreateFile + 5]
    ;ret
    ;获得返回地址
    pop eax
    
    ;恢复HOOK修改的代码，转移流程回CreateFile
    push ebp
    mov ebp, esp
    jmp eax
    
    
    ;==============CallBack End===============
    
    ;.data
    ;g_dwRelocate         DWORD 0    ;重定位字节数
    g_hFileHandle         HANDLE  0
    
    g_pfnLoadLibrary    DWORD 0
    g_pfnGetProcAddr  DWORD 0
    g_pfnCreateFile       DWORD 0
    g_pfnWriteFile         DWORD 0
    g_pfnSetFilePointer DWORD 0
    g_pfnCloseHandle   DWORD 0
    g_pfnGetLocalTime DWORD 0
    g_pfnWsprintf         DWORD 0
    g_pfnVirtualProtect DWORD 0
    
    g_bIsHook               DWORD FALSE
    
    g_bJmp  db 0E8H

    g_szCR_LF   db 0Dh, 0AH, 0      ;回车换行
    
    g_szCreateFile db 'CreateFileW', 0
    ;g_szCreateFileW db 'C', 0, 'r', 0, 'e', 0, 'a', 0, 't', 0, 'e', 0, 'F', 0, 'i', 0, 'l', 0, 'e', 0, 'W', 0, 0, 0
    g_szWriteFile  db 'WriteFile', 0
    g_szSetFilePointer db 'SetFilePointer', 0
    g_szCloseHandle db 'CloseHandle', 0
    g_szGetLocalTime db 'GetLocalTime', 0
    g_szWsprintf   db 'wsprintfA', 0
    g_szVirtualProtect db 'VirtualProtect', 0
    
    g_szKernel32         db 'Kernel32.dll', 0
    ;g_szKernel32W db 'K', 0, 'e', 0, 'r', 0, 'n', 0, 'e', 0, 'l', 0, '3', 0, '2', 0, '.', 0, 'd', 0, 'l', 0, 'l', 0, 0, 0
    g_szUser32 db 'User32.dll', 0
    
    g_szFileNameA db 'Log.txt', 0
    g_szFileNameW db 'c', 0, ':', 0, '/', 0, 'L', 0, 'o', 0, 'g', 0, '.', 0, 't', 0, 'x', 0, 't', 0, 0, 0
    
    ;月/日 时-分-秒
    g_szFmtStr   db '%02d/%02d %02d:%02d:%02d    ', 0
    ;.dataEnd
    
    HookApi proc
        LOCAL @oldProtect: DWORD
        ;invoke VirtualProtect, addr Remote_Begin, Remote_End - Remote_Begin, \
        ;                                PAGE_EXECUTE_READWRITE, addr @oldProtect
        
        lea eax, [@oldProtect]
        push  eax
        push  PAGE_EXECUTE_READWRITE
        push  5
        mov eax, [ebx + g_pfnCreateFile]
        push eax
        call [ebx + g_pfnVirtualProtect]
        .if eax == 0
            ret
        .endif
 
        ;写E9
        mov ecx, [ebx + g_pfnCreateFile]
        mov al, [ebx + g_bJmp]
        mov byte ptr [ecx], al
    
        ;写地址
        ;偏移地址 = 目标地址 - API 基址 - 5
        mov eax, edi        ;重定位地址
        add eax, Lable_HookCallBack - Lable_Relocate ;真实代码地址
        ;mov edx, [ebx + g_pfnCreateFile]    ;API 地址
        mov edx, ecx     ;API 地址
        sub eax, edx            ;
        sub eax, 5
        mov [ecx + 1], eax

        ret
    HookApi endp
    
     ;<<<<<<<<<<<<<<<<<<<<
    ;   创建日志文件
    ;   返回值： 成功/失败
    ;>>>>>>>>>>>>>>>>>>>>
    CreateLog proc
        ;Call 创建文件
        
        ;给标志位如果下次进入为递归方式进入，则直接退出
        mov [ebx + g_bIsHook], TRUE
        
        push NULL                                       ;文件模版
        push FILE_ATTRIBUTE_NORMAL     ;文件属性
        push OPEN_ALWAYS                       ;如何创建
        push NULL                                       ;安全属性
        push FILE_SHARE_READ                  ; 打开方式，  不共享
        push 0C0000000H                           ;GENERIC_READ|GENERIC_WRITE
        lea eax, [ebx + offset g_szFileNameW]       
        push eax                                          ; 文件路径  （文件路径 + 文件名）
        
        ;lea eax, offset g_pfnCreateFile
        mov eax, [ebx + offset g_pfnCreateFile]
        ;add eax, ebx
        call eax
        .if eax == INVALID_HANDLE_VALUE
            and eax, 0
            ret
        .endif
        
        ;重定位
        call @f
        @@:
        pop ebx
        sub ebx, offset @b        
        
        ;标志非重入
        mov [ebx + g_bIsHook], FALSE
        
        ret
    CreateLog endp
    
    ;<<<<<<<<<<<<<<<<<<<<
    ;   写日志
    ;   返回值： 成功/失败
    ;>>>>>>>>>>>>>>>>>>>>
    WriteLog proc   
        LOCAL @szTime[MAXBYTE]: BYTE
        LOCAL @dwLen: DWORD
        LOCAL @dwOutLen: DWORD
        
        ;push ebp
        ;mov ebp, ebx
        
        ;移动文件指针        
        push FILE_END ;文件尾部
        push NULL
        push NULL
        mov eax, offset g_hFileHandle   ;文件句柄
        add eax, ebx
        push [eax]
        
        call [ebx + offset g_pfnSetFilePointer]
        .if eax == INVALID_SET_FILE_POINTER
            and eax, 0
            ret
        .endif
        
        ;获取时间
        lea eax, @szTime
        push eax
        lea eax, offset  GetTime
        add eax, ebx
        call  eax
        ;call [ebp + GetTime]
        
        ;写入时间
        ;重定位
        call @f
        @@:
        pop ebx
        sub ebx, offset @b  
        
        ;计算时间字符串长度
        lea eax, [@szTime]
        push eax
        
        lea eax, [StrLen]
        add eax, ebx
        call eax
        mov @dwLen, eax
        
        ;写文件
        push NULL                       ;
        lea eax, [@dwOutLen]    
        push eax                            ;返回写了多少字节
        push @dwLen                 ;需要写多长
        lea eax, [@szTime]
        push eax                            ;缓冲区地址
        mov eax, [ebx + offset g_hFileHandle]
        push eax                            ;文件句柄
        
        call [ebx + offset g_pfnWriteFile]
        
        ;获取栈中的参数
        mov eax, [ebp + 30H]
        push eax
        lea eax, [BstrLen]
        add eax, ebx
        call eax
        mov @dwLen, eax
        
        ;EBP+30H
        
        ;写入参数
        push NULL                       ;
        lea eax, [@dwOutLen]    
        push eax                            ;返回写了多少字节
        push @dwLen                 ;需要写多长
        mov eax, [ebp + 30H]
        push eax                            ;缓冲区地址
        mov eax, [ebx + offset g_hFileHandle]
        push eax                            ;文件句柄
        
        call [ebx + offset g_pfnWriteFile]
        
        ;写入回车换行
        push NULL                       ;
        lea eax, [@dwOutLen]    
        push eax                            ;返回写了多少字节
        push 2                 ;需要写多长
        lea eax, [offset g_szCR_LF]
        add eax, ebx
        push eax                            ;缓冲区地址
        mov eax, [ebx + offset g_hFileHandle]
        push eax                            ;文件句柄
        
        call [ebx + offset g_pfnWriteFile]
        ;提交文件
        
        ret
    WriteLog endp
    
;    GetAppCreateFileAddr proc
;        
;        mov esi, 01001200H
;        mov eax, [esi]
;        mov [ebx + g_pfnCreateFile], eax
;        
;        ret
;    GetAppCreateFileAddr endp
    
    GetFunAddr proc 
        LOCAL @hKernelMod: HMODULE 
        LOCAL @hUserMod: HMODULE
        
        ;获取Kernel模块地址
        lea eax, [ebx + offset g_szKernel32]
        push eax
        
        mov eax, [ebx + offset g_pfnLoadLibrary]
        ;add eax, ebx
        call eax
        .if eax == 0
            ret
        .endif
        mov @hKernelMod, eax
        
         ;获取User32模块地址
        lea eax, [ebx + offset g_szUser32]
        push eax
        
        mov eax, [ebx + offset g_pfnLoadLibrary]
        ;add eax, ebx
        call eax
        .if eax == 0
            ret
        .endif
        mov @hUserMod, eax
        
        ;获取CreateFile函数地址
        lea eax, [ebx + offset g_szCreateFile]
        push eax
        
        mov eax, @hKernelMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ;invoke GetLastError
            ;and eax, 0
            ret
        .endif
        mov [ebx + offset g_pfnCreateFile], eax
        
        ;获取WriteFile函数地址
        lea eax, [ebx + offset g_szWriteFile]
        push eax
        
        mov eax, @hKernelMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ;invoke GetLastError
            ;and eax, 0
            ret
        .endif
        mov [ebx + offset g_pfnWriteFile], eax
        
        ;获取SetFilePointer函数地址
        lea eax, [ebx + offset g_szSetFilePointer]
        push eax
        
        mov eax, @hKernelMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ;invoke GetLastError
            ;and eax, 0
            ret
        .endif
        mov [ebx + offset g_pfnSetFilePointer], eax

        ;获取CloseHandle函数地址
        lea eax, [ebx + offset g_szCloseHandle]
        push eax
        
        mov eax, @hKernelMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ret
        .endif
        mov [ebx + offset g_pfnCloseHandle], eax

        
        ;获取GetLocalTime函数地址
        lea eax, [ebx + offset g_szGetLocalTime]
        push eax
        
        mov eax, @hKernelMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ret
        .endif
        mov [ebx + offset g_pfnGetLocalTime], eax
        
        ;获取VirtualProtect函数地址
        lea eax, [ebx + offset g_szVirtualProtect]
        ;lea eax, [ebx + offset g_szGetLocalTime]
        push eax
        
        mov eax, @hKernelMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ;invoke GetLastError
            ;and eax, 0
            ret
        .endif
        mov [ebx + offset g_pfnVirtualProtect], eax
        
        
        ;获取wsprintf函数地址
        lea eax, [ebx + offset g_szWsprintf]
        push eax
        
        mov eax, @hUserMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ret
        .endif
        mov [ebx + offset g_pfnWsprintf], eax
        
        
        ;卸载Lib
        ;invoke FreeLibrary, @hMod
        
        ret
    GetFunAddr endp

    ;<<<<<<<<<<<<<<<<<<<<
    ;   获取Unicode的长度
    ;   返回值： eax， 长度
    ;>>>>>>>>>>>>>>>>>>>>
    BstrLen proc uses ECX EDI bstrSrc:DWORD
        or ecx, -1                  ;的ECX 全F
        xor eax, eax              ;AX 给00
        mov edi, bstrSrc       ;EDI 指向字符串首地址
        repnz scasw             ;循环查找00，找到则退出循环
        not ecx                     ;ECX 取反 得到长度，但是此时统计了\0
        dec ecx                    ; 减掉 \0 的长度
        
        mov eax, ecx            ; 返回
        
        ret
    BstrLen endp
    
    ;<<<<<<<<<<<<<<<<<<<<
    ;   获取Ascii的长度
    ;   返回值： eax， 长度
    ;>>>>>>>>>>>>>>>>>>>>
    StrLen proc uses ECX EDI pszSrc:DWORD
        or ecx, -1                  ;的ECX 全F
        xor eax, eax              ;Al 给0
        mov edi, pszSrc       ;EDI 指向字符串首地址
        repnz scasb             ;循环查找0，找到则退出循环
        not ecx                     ;ECX 取反 得到长度，但是此时统计了\0
        dec ecx                    ; 减掉 \0 的长度
        
        mov eax, ecx            ; 返回
        
        ret
    StrLen endp
    
    
    GetTime proc uses EBX pszBuf: DWORD
        LOCAL @LocalTime: SYSTEMTIME
        
        lea eax, [@LocalTime]
        push eax
        call [ebx + g_pfnGetLocalTime]
        
        xor eax, eax
        mov ax, @LocalTime.wSecond
        push eax
        
        mov ax, @LocalTime.wMinute
        push eax
        
        mov ax, @LocalTime.wHour
        push eax
        
        mov ax, @LocalTime.wDay
        push eax
        
        mov ax, @LocalTime.wMonth
        push eax
        
        mov eax, offset g_szFmtStr
        add eax, ebx
        push eax
        
        mov eax, pszBuf
        push eax
        
        ;mov eax, [ebx + g_pfnWsprintf]
        ;add eax, ebx
        ;call  eax
        call [ebx + g_pfnWsprintf]
        
        or eax, 1
        ret
    GetTime endp

Remote_End:



;<<<<<<<<<<<<<<<<<<<<
;   Hook按钮
;>>>>>>>>>>>>>>>>>>>>
OnBtnHook proc
    LOCAL @dwDstPID: DWORD
    ;LOCAL @pRemoteAddr: DWORD
    
    ;已经注入则不允许点击
    .if g_bIsInject != FALSE
        invoke MessageBox, NULL, addr g_szRepInject, NULL, MB_OK
        ret
    .endif
    
    ;查找进程目标，获得进程PID
    invoke FindDstAndGetPID, addr g_szDstClassName, addr @dwDstPID
    .if eax == NULL
        invoke MessageBox, NULL, g_szGetPIDErr, NULL, MB_OK
        ret
    .endif

    ;初始化注入代码
    invoke InitInjectCode, g_szLoadLibraryA, g_szGetProcAddr
    .if eax == NULL
        invoke MessageBox, NULL, g_szInitErr, NULL, MB_OK
        ret
    .endif
    
    ;注入代码
    invoke InjectCode, @dwDstPID, Remote_Begin, Remote_End - Remote_Begin
    .if eax == NULL
        invoke MessageBox, NULL, g_szInjectErr, NULL, MB_OK
        ret
    .endif

    ;标记已经注入
    mov g_bIsInject, TRUE
    ret

OnBtnHook endp

;<<<<<<<<<<<<<<<<<<<<
;   查找进程目标，获得目标进程PID
;   pszDstName      目标进程名
;   hOutDstHandle 返回的句柄
;   返回值： 成功/失败
;>>>>>>>>>>>>>>>>>>>>
FindDstAndGetPID proc  pszDstClassName: DWORD, hOutDstPID: HANDLE
    LOCAL @hDstWnd: HWND 
    ;查找窗口，获得窗口句柄
    invoke FindWindow, pszDstClassName, NULL
    .if eax == NULL
        ret
    .endif
    mov @hDstWnd, eax
    
    ;通过窗口句柄获得进程Pid
    invoke GetWindowThreadProcessId, @hDstWnd, hOutDstPID
    .if hOutDstPID == NULL
        and eax, 0
        ret
    .endif
    
    mov eax, TRUE
    ret
FindDstAndGetPID endp

;<<<<<<<<<<<<<<<<<<<<
;   初始化InjectCode，获得函数指针，并修改内存保护属性
;   pszLoadLibrary       LoadLibrary字符串地址
;   pszGetProcAddr     GetProcAddr字符串地址
;   返回值： 成功/失败
;>>>>>>>>>>>>>>>>>>>>
InitInjectCode proc pszLoadLibrary: DWORD, pszGetProcAddr: DWORD
    LOCAL @hMod: HMODULE 
    LOCAL @oldProtect:DWORD
    ;int 3
    
    ;修改内存保护属性, 便于修改数据
     invoke VirtualProtect, addr Remote_Begin, Remote_End - Remote_Begin, \
                                        PAGE_EXECUTE_READWRITE, addr @oldProtect
    .if eax == NULL
        invoke MessageBox, NULL, g_szProtectErr, NULL, MB_OK
        ret
    .endif

    ;加载Kernel32
    invoke LoadLibraryA, addr g_szKernel32
    .if eax == NULL
        ret
    .endif
    mov @hMod, eax
    
    ;获得LoadLibrary地址
    ;lea eax, [offset LoadLibraryW]
    ;lea edx, [offset GetProcAddress]
    invoke GetProcAddress, @hMod, addr g_szLoadLibraryA
    .if eax == NULL
        ret
    .endif
    mov g_pfnLoadLibrary, eax
    
    ;获得GetProcAddr地址
    invoke GetProcAddress, @hMod, addr g_szGetProcAddr
    .if eax == NULL
        ret
    .endif
    mov g_pfnGetProcAddr, eax
    
    ;卸载Lib
    invoke FreeLibrary, @hMod
    
    ret
InitInjectCode endp

;<<<<<<<<<<<<<<<<<<<<
;   注入代码到目标进程, 携带LoadLibrary和GetProcAddr
;   dwPID             目标进程ID
;   pSrcData         待写入的数据
;   dwDataLen     数据长度
;   dwOutRemoteAddr 写入成功的地址
;   返回值： 成功/失败
;>>>>>>>>>>>>>>>>>>>>
InjectCode proc  dwPID: DWORD, pSrcData: DWORD, dwDataLen: DWORD
    LOCAL @hProc: HANDLE
    LOCAL @lpRemoteBuf: LPVOID
    LOCAL @dwWriten: DWORD
    
    ;打开进程
    invoke OpenProcess, PROCESS_ALL_ACCESS, FALSE, dwPID
    .if eax == NULL
        ret
    .endif
    mov @hProc, eax
    
    ;申请远程内存
    invoke VirtualAllocEx, @hProc, NULL, 1000h, MEM_COMMIT, PAGE_EXECUTE_READWRITE
    .if eax == NULL
        invoke GetLastError
        ret
    .endif
    mov @lpRemoteBuf, eax
    
    mov eax, [pSrcData]
    ;写入远程内存
    invoke WriteProcessMemory, @hProc, @lpRemoteBuf, eax, dwDataLen, @dwWriten
    .if eax == NULL
        ret
    .endif
    ;int 3
    ;创建远程线程
    invoke CreateRemoteThread, @hProc, NULL, NULL, @lpRemoteBuf, NULL, NULL, NULL
    .if eax == NULL
        ret
    .endif
    
    ;释放远程内存
    ret
InjectCode endp

;;<<<<<<<<<<<<<<<<<<<<
;;   执行远程线程，跑远程线程
;;   返回值： 成功/失败
;;>>>>>>>>>>>>>>>>>>>>
;RunInjectCode proc
;    
;    ret
;RunInjectCode endp

end start
