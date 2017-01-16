extern MessageBoxA: proc
extern LoadLibraryA: proc
extern GetProcAddress: proc
extern VirtualProtect: proc
extern FreeLibrary: proc
extern FindWindowA: proc
extern GetWindowThreadProcessId : proc
extern OpenProcess: proc
extern VirtualAllocEx: proc
extern VirtualAllocEx: proc
extern WriteProcessMemory: proc
extern CreateRemoteThread: proc
extern VirtualFreeEx: proc

extern Sleep: proc

includelib user32.lib
includelib Kernel32.lib

;=============================================================
MB_OK       equ 0
MB_YESNO    equ 4
IDOK        equ 1
IDYES       equ 6

NULL        equ 0
INVALID_HANDLE_VALUE    equ -1

PAGE_EXECUTE_READWRITE  equ 40h
PROCESS_ALL_ACCESS   equ 1f0fffH
FALSE       equ 0

MEM_COMMIT  equ 1000h
MEM_RELEASE equ 8000h
PAGE_EXECUTE_READWRITE equ 40h
;=============================================================

.data
g_szText      db '是否注入?', 0
g_szCaption   db 'Inject', 0
g_szSucceed   db 'Hook成功', 0


g_szCalc    db 'CalcFrame', 0

g_szKernel32    db 'Kernel32.dll' ,0
g_szLoadLib db 'LoadLibraryA', 0
g_szGetProc db 'GetProcAddress', 0 
g_szVirtualProtect db 'VirtualProtect', 0

g_szErr     db 'Error', 0


.code

Inject_Code_Start:
    jmp RemoteMain

;HookApi主体
MyHookApi proc
    ;获取返回地址
    pop r15
    
    ;原生代码
    push rbx
    push rbp
    push rsi
    push rdi
    
    ;保存参数
    push rcx
    push rdx
    push r8
    push r9
    
    ;保存返回地址
    push r15
    
    ;Hook主代码
    sub rsp, 30h

    mov rcx, 0
    lea rdx, g_szHello
    lea r8, g_szTitle
    mov r9, MB_OK
    call g_pfnMsgBoxA
    
    add rsp, 30h
    
    ;获得返回地址
    pop r15
    ;mov r15, [rsp]
    
    ;还原参数
    pop r9
    pop r8
    pop rdx
    pop rcx
    sub rsp,68H
    
    ;跳回原API
    jmp r15
MyHookApi endp    


;加载Lib    
;hUser32:QWORD, hShell32:QWORD
MyLoadLib proc 
    LOCAL @hUser32:QWORD
    LOCAL @hShell32:QWORD
    mov @hUser32, rcx
    mov @hShell32, rdx
    
    sub rsp, 28h
    
    ;获取User32的句柄
    lea rcx, offset g_szUser32
    call g_pfnLoadLibrary
    cmp rax, NULL
    jnz @F
        JMP MyLoadLib_Safe_Ret
@@:
    mov r15, @hUser32
    mov [r15], rax
    
    ;获取Shell32的句柄
    lea rcx, offset g_szShell32
    call g_pfnLoadLibrary
    cmp rax, NULL
    jnz @F
        JMP MyLoadLib_Safe_Ret
@@:
    mov r15, @hShell32
    mov [r15], rax
    
    mov rax, 1

MyLoadLib_Safe_Ret:
    add rsp, 28h
    ret
MyLoadLib endp
    
;获取所需函数
MyGetPorc proc
    LOCAL @hUser32: QWORD
    LOCAL @hShell32: QWORD
    LOCAL @lpShellAbout: QWORD
    LOCAL @lpMsgBox: QWORD
    mov @hUser32, rcx
    mov @hShell32, rdx
    mov @lpShellAbout, r8
    mov @lpMsgBox, r9
    
    sub rsp, 28h

    
    ;获取MsgBox地址
    mov rcx, @hUser32
    lea rdx, offset g_szMsgBoxA
    call g_pfnGetProcAddr
    cmp rax, NULL
    jnz @F
       JMP MyGetPorc_Safe_Ret
@@:
    mov r15, @lpMsgBox
    mov [r15], rax
     
    ;获取ShellAbout地址
    mov rcx, @hShell32
    lea rdx, offset g_szShellAboutW
    call g_pfnGetProcAddr
    cmp rax, NULL
    jnz @F
       JMP MyGetPorc_Safe_Ret
@@:
    mov r15, @lpShellAbout
    mov [r15], rax
    
    mov rax, 1
    
MyGetPorc_Safe_Ret:   
    add rsp, 28h
    ret
MyGetPorc endp

;远程执行的主函数
RemoteMain proc
    LOCAL @hUser32: QWORD
    LOCAL @hShell32: QWORD
    LOCAL @lpShellAbout: QWORD
    LOCAL @lpMsgBox: QWORD
    LOCAL @oldProtect: QWORD
    
    sub rsp, 28h
    
    mov @hUser32, 0
    mov @hShell32, 0
    
    
    ;加载所需Lib
    lea rcx, @hUser32
    lea rdx, @hShell32
    call MyLoadLib
    cmp rax, 1
    jz @F
        jmp Safe_Ret
@@:
    
    ;获取函数地址
    mov rcx, @hUser32
    mov rdx, @hShell32
    lea r8, @lpShellAbout
    lea r9, @lpMsgBox
    call MyGetPorc
    cmp rax, 1
    jz @F
        jmp Safe_Ret
@@:

    ;修改内存保护属性,用于保存函数地址
    lea rcx, MyData
    mov rdx, Inject_Code_End - MyData
    mov r8, PAGE_EXECUTE_READWRITE
    lea r9, @oldProtect
    call g_pfnVirtualProtect
    cmp rax, NULL
    jnz @F
        jmp Safe_Ret
@@:
    
    ;保存数据
    mov rax, @lpMsgBox
    lea rbx, g_pfnMsgBoxA
    mov [rbx], rax
    
    mov rax, @lpShellAbout
    lea rbx, g_pfnShellAboutA
    mov [rbx], rax

    ;还原内存保护属性
    lea rcx, MyData
    mov rdx, Inject_Code_End - MyData
    mov r8, @oldProtect
    lea r9, @oldProtect
    call g_pfnVirtualProtect
    cmp rax, NULL
    jnz @F
        jmp Safe_Ret
@@:


    ;修改内存保护属性
    mov rcx, @lpShellAbout
    mov rdx, 1000h
    mov r8, PAGE_EXECUTE_READWRITE
    lea r9, @oldProtect
    call g_pfnVirtualProtect
    cmp rax, NULL
    jnz @F
        jmp Safe_Ret
@@:

    ;调用Hook
    ;mov rcx, @lpShellAbout
    ;mov rdx, @lpMsgBox
    ;call HookApi
    mov rax, @lpShellAbout
    lea rdx, g_ShellCode
    mov rdx, [rdx]
    mov QWORD ptr[rax], rdx
    mov byte ptr[rax+8], 90h
    
    ;保存跳转地址
    lea rdx, MyHookApi
    sub rax, 9
    mov QWORD ptr [rax], rdx
    
    ;还原内存保护属性
    mov rcx, @lpShellAbout
    mov rdx, 1000h
    mov r8, @oldProtect
    lea r9, @oldProtect
    call g_pfnVirtualProtect
    cmp rax, NULL
    jnz @F
        jmp Safe_Ret
@@:
    mov rax, 1
Safe_Ret:
    cmp @hUser32, 0
    jz @F
        ;释放Dll
@@:
    cmp @hShell32, 0
    jz @F
        ;释放Dll
@@:
    
    add rsp, 28h
    ret
RemoteMain endp
    
    MyData:
    g_pfnMsgBoxA        QWORD 0
    g_pfnShellAboutA    QWORD 0
    
    g_pfnVirtualProtect QWORD 0 
    g_pfnLoadLibrary    QWORD 0
    g_pfnGetProcAddr    QWORD 0
    
    g_ShellCode         QWORD 9090FFFFFFF115FFH
    ;FF 15 F2 FF FF FF 90 90
    ;000007FEFEA79448 | FF 15 F1 FF FF FF                | call qword ptr ds:[7FEFEA7943F]          |
    ;call qword ptr [0x7fefea7943f]
    
    g_szHello       db 'Hello', 0
    g_szTitle       db 'Inject', 0
    g_szMsgBoxA      db 'MessageBoxA', 0
    g_szShellAboutW  db 'ShellAboutW', 0
    
    g_szShell32     db 'Shell32.dll', 0
    g_szUser32      db 'user32.dll', 0
    
Inject_Code_End:

;==========================================================================
MsgBox proc
    sub rsp, 28h
    
    mov rdx, rcx
    mov r8, offset g_szErr
    mov r9, MB_OK
    xor rcx, rcx
    call MessageBoxA
    
    int 3
    add rsp, 28h
    ret  
MsgBox endp

;注入主函数
Inject proc
	LOCAL @hCalc:QWORD
	LOCAL @qwPid :QWORD
	LOCAL @hProcess :QWORD
	LOCAL @lpBuff :QWORD
    LOCAL @hKernel: QWORD
	LOCAL @oldProtect:QWORD
	LOCAL @lpLoadLibrary:QWORD
    LOCAL @lpGetProc: QWORD
    LOCAL @lpVirtualProtect :QWORD  
    sub rsp, 38h
    
    ;查找窗口获得进程句柄
    mov rcx, offset g_szCalc
    mov rdx, NULL
    call FindWindowA
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    mov @hCalc, rax
    
    ;获取Kernel32的句柄
    mov rcx, offset g_szKernel32
    call LoadLibraryA
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    mov @hKernel, rax
    
    ;获取LoadLibrary地址
    mov rcx, @hKernel
    mov rdx, offset g_szLoadLib
    call GetProcAddress
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    mov @lpLoadLibrary, rax
    
    ;获取GetprocAddr地址
    mov rcx, @hKernel
    mov rdx, offset g_szGetProc
    call GetProcAddress
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    mov @lpGetProc, rax
    
    ;获取VirtualProtect地址
    mov rcx, @hKernel
    mov rdx, offset g_szVirtualProtect
    call GetProcAddress
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    mov @lpVirtualProtect, rax
    
    
    ;修改内存保护属性
    mov rcx, offset Inject_Code_Start
    mov rax, offset Inject_Code_End
    mov rbx, offset Inject_Code_Start
    sub rax, rbx
    mov rdx, rax
    mov r8, PAGE_EXECUTE_READWRITE
    lea r9, @oldProtect
    call VirtualProtect
    
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    
    
    ;保存局部地址到待注入代码中
    mov rax, @lpLoadLibrary
    mov g_pfnLoadLibrary, rax
    
    mov rax, @lpGetProc
    mov g_pfnGetProcAddr, rax
    
    mov rax, @lpVirtualProtect
    mov g_pfnVirtualProtect, rax
    
    ;保存Calc 的窗口句柄
    ;mov rax, @hCalc
    ;mov g_hCalc, rax
    
    ;还原内存保护属性
    mov rcx, offset Inject_Code_Start
    mov rax, offset Inject_Code_End
    mov rbx, offset Inject_Code_Start
    sub rax, rbx
    mov rdx, rax
    mov r8, @oldProtect
    lea r9, @oldProtect
    call VirtualProtect
    
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    
    ;释放Kernel32
    mov rcx, @hKernel
    call FreeLibrary
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    
    ;窗口句柄转进程ID
    mov rcx, @hCalc
    lea rdx, @qwPid
    call GetWindowThreadProcessId
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    
    ;打开进程
    mov rcx, PROCESS_ALL_ACCESS
    mov rdx, FALSE
    mov r8, @qwPid
    call OpenProcess
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    mov @hProcess, rax
    
    ;申请远程内存
    mov rcx, @hProcess
    mov rdx, NULL
    mov r8, 1000H
    mov r9, MEM_COMMIT
    mov qword ptr [rsp+20h], PAGE_EXECUTE_READWRITE
    call VirtualAllocEx
    cmp rax, NULL
    jnz @F
        xor rax, rax
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    mov @lpBuff, rax
    
    ;写入内存
    mov rcx, @hProcess
    mov rdx, @lpBuff
    mov r8, offset Inject_Code_Start
    mov rax, offset Inject_Code_End
    mov rbx, offset Inject_Code_Start
    sub rax, rbx
    mov r9, rax
    mov qword ptr [rsp+20h], NULL
    call WriteProcessMemory
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    
    ;开启远程线程
    mov rcx, @hProcess
    mov rdx, NULL
    mov r8, 0
    mov r9, @lpBuff
    mov qword ptr [rsp+20h], NULL
    mov qword ptr [rsp+28h], 0
    mov qword ptr [rsp+30h], NULL
    call CreateRemoteThread
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:

    ;mov rcx, 5000
    ;call Sleep
    
    ;释放远程内存
    ;mov rcx, @hProcess
    ;mov rdx, @lpBuff
    ;mov r8, 1000h
    ;mov r9, MEM_RELEASE
    ;call VirtualFreeEx
    ;cmp rax, NULL
    ;jnz @F
    ;    mov rcx, offset g_szErr
    ;    call MsgBox
    ;    jmp Safe_Ret
;@@:
    
    mov rax, 1
    
Safe_Ret:
    add rsp, 38h
    ret
Inject endp


;@@
;@F :下一个
;@B :前一个

;程序主函数
Main proc
    sub rsp, 28h
    
    ;call Inject
    ;add rsp, 28h
    ;ret

    
    xor rcx, rcx
    mov rdx, offset g_szText
    mov r8, offset g_szCaption
    mov r9, MB_YESNO
    call MessageBoxA
    
    cmp rax, IDYES
    jnz @F              
        call Inject     ;.if eax == IDYES
        cmp rax, 0
        jz @F
        
        ;成功
        xor rcx, rcx
        mov rdx, offset g_szSucceed
        mov r8, offset g_szCaption
        mov r9, MB_OK
        call MessageBoxA
@@:
    xor rax, rax
    
    add rsp, 28h
    ret
Main endp

end 
