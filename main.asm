; nasm -felf64 main.asm -o main.o
; ld main.o -o main -lX11 -dynamic-linker /lib64/ld-linux-x86-64.so.2

[bits 64]
global _start

section .data
msg: db "Hello World!"
msgLen: equ $ - msg

section .bss
d: resq 1
w: resq 1
e: resb 192
s: resq 1
rootwindow: resq 1
blackPixel: resq 1
whitePixel: resq 1
defaultGC: resq 1
tmp: resq 1

section .text

	extern XOpenDisplay
	extern XDefaultScreen
	extern XRootWindow
	extern XBlackPixel
	extern XWhitePixel
	extern XCreateSimpleWindow
	extern XSelectInput
	extern XMapWindow
	extern XNextEvent
	extern XDefaultGC
	extern XDrawString
	extern XFillRectangle
	extern XCloseDisplay

	;in case of x86_64 params are passed in RDI, RSI, RDX, RCX, R8, R9, stack (in reverse order)

_start:

	; d = XOpenDisplay(NULL);
	mov rdi, 0
	call XOpenDisplay
	mov [d], rax

	; s = DefaultScreen(d);
	mov rdi, [d]
	call XDefaultScreen
	mov [s], rax

	; RootWindow(d, s)
	mov rdi, [d]
	mov rsi, [s]
	call XRootWindow
	mov [rootwindow], rax

	; BlackPixel(d, s)
	mov rdi, [d]
	mov rsi, [s]
	call XBlackPixel
	mov [blackPixel], rax

	; WhitePixel(d, s)
	mov rdi, [d]
	mov rsi, [s]
	call XWhitePixel
	mov [whitePixel], rax

	; w = XCreateSimpleWindow(d, RootWindow(d, s), 10, 10, 100, 100, 1, BlackPixel(d, s), WhitePixel(d, s));
	mov rdi, [d]
	mov rsi, [rootwindow]
	mov rdx, 10
	mov rcx, 10
	mov r8, 500
	mov r9, 500
	mov rax, [whitePixel]
	push rax
	mov rax, [blackPixel]
	push rax
	mov rax, 1
	push rax
	call XCreateSimpleWindow
	mov [w], rax

	pop rax

	; XSelectInput(d, w, ExposureMask | KeyPressMask);
	mov rdi, [d]
	mov rsi, [w]
	mov rdx, 32769	; ExposureMask | KeyPressMask
	call XSelectInput

	; XMapWindow(d, w);
	mov rdi, [d]
	mov rsi, [w]
	call XMapWindow

.loop:

	; XNextEvent(d, &e);
	mov rdi, [d]
	mov rsi, e
	call XNextEvent

	mov eax, [e]
	cmp eax, 12	; Expose
	jne .skip1

	; DefaultGC(d, s)
	mov rdi, [d]
	mov rsi, 0
	call XDefaultGC
	mov [defaultGC], rax

	; ; XDrawString(d, w, DefaultGC(d, s), 10, 50, msg, strlen(msg));
	; mov rdi, [d]
	; mov rsi, [w]
	; mov rdx, [defaultGC]
	; mov rcx, 10
	; mov r8, 50
	; mov r9, msg
	; mov rax, msgLen
	; push rax
	; call XDrawString

	; ; XFillRectangle(d, w, DefaultGC(d, s), 20, 20, 10, 10);
	; mov rdi, [d]
	; mov rsi, [w]
	; mov rdx, [defaultGC]
	; mov rcx, 20
	; mov r8, 20
	; mov r9, 10
	; mov rax, 10
	; push rax
	; call XFillRectangle

.skip1:
	mov eax, [e]
	cmp eax, 2	; KeyPress
	jne .skip2

	mov eax, [e + 84]	; e.xkey.keycode
	cmp eax, 9
	je break

.skip2:
	jmp .loop

break:

	mov rdi, [d]
	call XCloseDisplay

	mov rax, 1
	mov rbx, 0
	int 80h
