; nasm -felf64 main.asm -o main.o
; ld main.o -o main -lX11 -dynamic-linker /lib64/ld-linux-x86-64.so.2

[bits 64]
global _start


struc object
	.locX: resq 1
	.locY: resq 1
	.velX: resq 1
	.velY: resq 1
	.weight: resq 1
endstruc


section .data
msg: db "Hello World!"
msgLen: equ $ - msg
squareLoc:
	.x: dq 10
	.y: dq 10
objectA:
	istruc object
		at object.locX, dq 150
		at object.locY, dq 150
		at object.velX, dq 0
		at object.velY, dq 0
		at object.weight, dq 1
	iend
objectB:
	istruc object
		at object.locX, dq 400
		at object.locY, dq 350
		at object.velX, dq 0
		at object.velY, dq 0
		at object.weight, dq 1
	iend
objectArray: dq objectA, objectB, 0

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
	extern XClearWindow

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

	; DefaultGC(d, s)
	mov rdi, [d]
	mov rsi, 0
	call XDefaultGC
	mov [defaultGC], rax

loop1:

	; XNextEvent(d, &e);
	mov rdi, [d]
	mov rsi, e
	call XNextEvent

	mov eax, [e]
	cmp eax, 12	; Expose
	jne skip1

	xor r10, r10

objectArrayLoop:
	mov rax, [objectArray + r10]
	cmp rax, 0
	je skip1

	push r10

	; XFillRectangle(d, w, DefaultGC(d, s), 20, 20, 10, 10);
	mov rdi, [d]
	mov rsi, [w]
	mov rdx, [defaultGC]
	mov rcx, [rax]
	mov r8, [rax + 8]
	mov r9, 10
	mov rax, 10
	push rax
	call XFillRectangle
	pop rax

	pop r10

	add r10, 8
	jmp objectArrayLoop

skip1:
	mov eax, [e]
	cmp eax, 2	; KeyPress
	jne skip2

	mov eax, [e + 84]	; e.xkey.keycode
	cmp eax, 9h			; esc keycode
	je break

	; mov eax, [e + 84]	; e.xkey.keycode
	cmp eax, 41h		; space keycode
	jne skip2

	call doStaff

skip2:
	jmp loop1

break:

	mov rdi, [d]
	call XCloseDisplay

	mov rax, 1
	mov rbx, 0
	int 80h



doStaff:
	; ; XClearWindow(d, w)
	; mov rdi, [d]
	; mov rsi, [w]
	; call XClearWindow

	; mov rcx, [squareLoc.x]
	; add rcx, 3
	; mov [squareLoc.x], rcx

	; ; XFillRectangle(d, w, DefaultGC(d, s), 20, 20, 10, 10);
	; mov rdi, [d]
	; mov rsi, [w]
	; mov rdx, [defaultGC]
	; mov r8, [squareLoc.y]
	; mov r9, 10
	; mov rax, 10
	; push rax
	; call XFillRectangle

	; pop rax

	ret











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