# Anti-debugging-techniques
 Anti-Debugging detection and obufuscation techniques that involved the use of Win32 API functions.
 
This simple tool was written in Assembler x86 Win32 API and the Anti-Debugging method are:
- NtGlobalFlag - PEB!NtGlobalFlags
- IsDebuggerPresent - kernel32!IsDebuggerPresent
- IsDebuggerPresent - PEB!IsDebugged
- FindWindows for ollydbg
- Software breakpoint detection
- Hardware breakpoint detection
- Self-modifying code
- Obfuscation

For example see follow code (first case):</br>
;NtGlobalFlag - PEB!NtGlobalFlags</br>
xor eax, eax</br>
assume fs:nothing</br>
mov eax, fs:[eax+30h]</br>
mov eax, [eax+68h]</br>
and eax, 70h</br>
db 0ebh, 01h</br>
db 0ffh, 085h, 0C0h</br>
jne @Detected</br>

The NtGlobalFlag field exists at offset 0x68 in the Process Environment Block</br>
We look at the individual instructions:</br>
mov eax, fs:[eax+30h] ; Process Environment Block</br>
mov al, [eax+68h] ; NtGlobalFlag</br>
and eax, 70h ; if value of eax is 70h</br>
db 0ebh, 01h ; means jmp and skip 1 junk byte</br>
db 0ffh, 085h, 0C0h ; Follows opcode "085h, 0C0h" matches with istruction test eax, eax</br>

I have tested the executable on Win 7 32 bit and 64 bit.</br>
