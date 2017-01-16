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


g_szCalc    db 'CalcFrame', 0
g_szUser32  db 'user32.dll', 0
g_szMsgBox  db 'MessageBoxA', 0

g_szErr     db 'Error', 0


.code

Inject_Code_Start:
    sub rsp, 28h
    
    call $+5
NEXT:
    pop rbx
    mov rax, NEXT
    sub rbx, rax        ;重定位
    
    mov rcx, offset g_hCalc
    mov rcx, [rbx + rcx]
    mov rax, offset g_szHello
    lea rdx, [rbx + rax]
    mov rax, offset g_szTitle
    lea r8, [rbx + rax]
    mov r9, MB_OK
    mov rax, offset g_pfnMsgBoxA
    mov rax, [rbx + rax]
    call rax
    
    add rsp, 28h
    ret
    
    g_pfnMsgBoxA        QWORD 0
    g_hCalc             QWORD 0 
    ;g_pfnLoadLibrary    QWORD 0
    ;g_pfnGetProcAddr    QWORD 0
    ;g_pfnGetModHandle   QWORD 0
    ;g_pfnCloseHandle    QWORD 0
    
    
    g_szHello     db 'Hello', 0
    g_szTitle   db 'Inject', 0

Inject_Code_End:

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
	LOCAL @hUser:QWORD
	LOCAL @oldProtect:QWORD
	LOCAL @lpMsgBox:QWORD
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
    
    ;获取User32的句柄
    mov rcx, offset g_szUser32
    call LoadLibraryA
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    mov @hUser, rax
    
    ;获取MsgBox地址
    mov rcx, @hUser
    mov rdx, offset g_szMsgBox
    call GetProcAddress
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    mov @lpMsgBox, rax
    
    ;修改内存保护属性
    mov rcx, offset Inject_Code_Start
    mov rdx, Inject_Code_End -  Inject_Code_Start
    mov r8, PAGE_EXECUTE_READWRITE
    lea r9, @oldProtect
    call VirtualProtect
    
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    
    
    ;保存MsgBox地址
    mov rax, @lpMsgBox
    mov g_pfnMsgBoxA, rax
    
    ;保存Calc 的窗口句柄
    mov rax, @hCalc
    mov g_hCalc, rax
    
    ;还原内存保护属性
    mov rcx, offset Inject_Code_Start
    mov rdx, Inject_Code_End -  Inject_Code_Start
    mov r8, @oldProtect
    lea r9, @oldProtect
    call VirtualProtect
    
    cmp rax, NULL
    jnz @F
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    
    ;释放User32
    mov rcx, @hUser
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
        mov rcx, offset g_szErr
        call MsgBox
        jmp Safe_Ret
@@:
    mov @lpBuff, rax
    
    ;写入内存
    mov rcx, @hProcess
    mov rdx, @lpBuff
    mov r8, offset Inject_Code_Start
    mov r9, Inject_Code_End - Inject_Code_Start
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

    mov rcx, 5000
    call Sleep
    
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
    
    cmp eax, IDYES
    jnz @F              
        call Inject     ;.if eax == IDYES
@@:
    xor eax, eax
    
    add rsp, 28h
    ret
Main endp

end 
