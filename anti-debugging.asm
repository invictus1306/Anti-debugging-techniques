.386
.model flat,stdcall
option casemap:none
include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib

.data
AppName db "Anti debugging and obfuscation techniques - Andrea Sindoni @invictus1306"

MsgBoxText          db "Windows debugger detected!",0
MsgBoxTitle         db "Debugger detectd!",0
MsgBoxTextNot       db "Windows debugger not detected!",0
MsgBoxTitleNot      db "Perfect!",0
OllydbgFindWindow   db "OLLYDBG",0h

.data?

.code
start proc

JUNKBYTE MACRO
	db	0cch, 0feh, 0ebh, 00h
ENDM

;NtGlobalFlag - PEB!NtGlobalFlags
xor eax, eax
assume fs:nothing
mov eax, fs:[eax+30h]
mov eax, [eax+68h]
and eax, 70h
db 0ebh, 01h
db 0ffh, 085h, 0C0h ;junk byte - test eax, eax
jne @Detected

;obfuscation
db 0ebh, 02h
JUNKBYTE

;IsDebuggerPresent first - kernel32!IsDebuggerPresent
call IsDebuggerPresent
call @eip_manipulate ; change eip (point to next instruction)
mov eax, 010h
cmp eax, 1
je @Detected

;IsDebuggerPresent second - PEB!IsDebugged
xor eax, eax
assume fs:nothing
mov eax, fs:[18h]
mov eax, DWORD PTR ds:[eax+30h]
movzx eax, BYTE PTR ds:[eax+2h]
test eax, eax
jne @Detected

;FindWindows for ollydbg
push 0
push offset OllydbgFindWindow
call FindWindow
test eax, eax
jne @Detected

;software breakpoint detection into MessageBox API
cld
mov edi, offset @Detected
mov ecx, 013h 
mov al,0cch
repne scasb
jz @Detected

;hardware breakpoint detection
assume fs:nothing
push offset HwBpHandler
push fs:[0]
mov DWORD PTR fs:[0], esp
xor eax, eax
div eax
pop DWORD PTR fs:[0]
add esp, 4
test eax, eax
jnz @Detected

;get write permissions for self-modifying code
xor esi, esi
xor ecx, ecx
mov esi, offset @encrypted_code
push esp
push PAGE_EXECUTE_READWRITE
push 04h
push esi
call VirtualProtect

;self-modifying code
mov eax, 1234h   ;key
mov ecx, offset @encrypted_code

@loop_decryption:
xor [ecx], al ;very simple algorithm
inc ecx
cmp ecx, @encrypted_code + 04h
jnz @loop_decryption

@encrypted_code:
db 05eh, 04h  ;push 30h
db 0dfh, 34h  ;jmp at next instruction 

push offset MsgBoxTitleNot
push offset MsgBoxTextNot
push 0
call MessageBox
jmp @Exit

@Detected:
push 30h
push offset MsgBoxTitle
push offset MsgBoxText
push 0
call MessageBox
jmp @Exit

@Exit:
push 0
call ExitProcess

@eip_manipulate:
add dword ptr [esp], 5
ret

start endp

HwBpHandler proc 
     xor eax, eax
     mov eax, [esp + 0ch]         ; This is a CONTEXT structure on the stack
     cmp DWORD PTR [eax + 04h], 0 ; Dr0
     jne bpFound
     cmp DWORD PTR [eax + 08h], 0 ; Dr1
     jne bpFound
     cmp DWORD PTR [eax + 0ch], 0 ; Dr2
     jne bpFound
     cmp DWORD PTR [eax + 10h], 0 ; Dr3
     jne bpFound
     jmp retFromException
     
bpFound:
    mov DWORD PTR [eax + 0b0h], 0ffffffffh ; HW bp found

retFromException:
    add DWORD PTR [eax + 0b8h], 6
    xor eax, eax
    ret

HwBpHandler endp

end start
