; nasm -felf64 main.asm -o main.o
; ld main.o -o main -lX11 -dynamic-linker /lib64/ld-linux-x86-64.so.2

[bits 64]
global _start


section .data
msg: db "Hello World!"
msgLen: equ $ - msg
; object0:
; 	.locX: dq 250
; 	.locY: dq 250
; 	.weight: dq 100.0
objectA:
	.locX: dq 500
	.locY: dq 200
	.velX: dq -10.0
	.velY: dq 0.0
	.weight: dq 200.0
objectB:
	.locX: dq 500
	.locY: dq 370
	.velX: dq 10.0
	.velY: dq 0.0
	.weight: dq 100.0
objectC:
	.locX: dq 200
	.locY: dq 270
	.velX: dq 1.0
	.velY: dq 0.0
	.weight: dq 100.0
objectD:
	.locX: dq 700
	.locY: dq 700
	.velX: dq 10.0
	.velY: dq 0.0
	.weight: dq 50.0
objectArray: dq objectA, objectB, objectC, objectD, 0
; G: dq 6.67e-11
G: dq 100.0

section .bss
d: resq 1
w: resq 1
e: resb 192
s: resq 1
rootwindow: resq 1
blackPixel: resq 1
whitePixel: resq 1
defaultGC: resq 1

section .text

	; x11 includes
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
	pop rax	; bruh moment. i don't know why it is required

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

.loop1:

	; XNextEvent(d, &e);
	mov rdi, [d]
	mov rsi, e
	call XNextEvent

	; is it an expose event
	mov eax, [e]
	cmp eax, 12	; Expose
	jne .skip1

	call initObjects

.skip1:
	; is it a keypress event
	mov eax, [e]
	cmp eax, 2	; KeyPress
	jne .skip2

	; esc got pressed -> closes window
	mov eax, [e + 84]	; e.xkey.keycode
	cmp eax, 9h			; esc keycode
	je .break

	; space got pressed -> calls doStaff
	; mov eax, [e + 84]	; e.xkey.keycode
	cmp eax, 41h		; space keycode
	jne .skip2

	call doStaff

.skip2:
	jmp .loop1

.break:

	mov rdi, [d]
	call XCloseDisplay

	mov rax, 1
	mov rbx, 0
	int 80h



doStaff:

	; XClearWindow(d, w)
	mov rdi, [d]
	mov rsi, [w]
	call XClearWindow

	call updateObjects

	ret



updateObjects:

	xor r10, r10
.objectArrayLoop:
	mov r11, [objectArray + r10]	; gets objectArray's r10th element
	cmp r11, 0
	je .skip2


	xor r12, r12
.objectObjectArrayLoop:
	mov r13, [objectArray + r12]	; gets objectArray's r12th element
	cmp r13, 0
	je .skip1

	cmp r13, r11
	je .next1


	; applies gravity x

	; v = v0 + ((G * mOther) / distance^2) * direction
	finit

	fild qword [r11 + 8]
	fild qword [r13 + 8]
	fsub

	fxam
	fstsw ax
	and rax, 0100000000000000b	; take only condition code flags
	cmp rax, 0
	jng .skip1X

	fldz						; direction
	jmp .else1X

.skip1X:

	fxtract
	fstp st1					; direction

.else1X:

	fld qword [G]				; grav const
	fld qword [r13 + 32]		; mOther
	fmul						; G * mOther

	; calculates distance using the pythagoras theorem
	fild qword [r13 + 8]
	fild qword [r11 + 8]
	fsub						; (locOtherY - locThisY)
	fild qword [r13 + 8]
	fild qword [r11 + 8]
	fsub						; (locOtherY - locThisY)
	fmul						; (locOtherY - locThisY)^2
	fild qword [r13 + 0]
	fild qword [r11 + 0]
	fsub						; (locOtherX - locThisX)
	fild qword [r13 + 0]
	fild qword [r11 + 0]
	fsub						; (locOtherX - locThisX)
	fmul						; (locOtherX - locThisX)^2
	fadd						; distance^2

	fdiv						; ( G * mOther ) / distance^2)
	fmul						; ((G * mOther) / distance^2) * direction
	fld qword [r11 + 24]		; v0
	fadd						; v0 + ((G * mOther) / distance^2) * direction

	fstp qword [r11 + 24]		; saves vel



	; applies gravity y

	; v = v0 + ((G * mOther) / distance^2) * direction
	finit

	fild qword [r11 + 0]
	fild qword [r13 + 0]
	fsub

	fxam
	fstsw ax
	and rax, 0100000000000000b	; take only condition code flags
	cmp rax, 0
	jng .skip1Y

	finit
	fldz						; direction
	jmp .else1Y

.skip1Y:

	fxtract
	fstp st1					; direction

.else1Y:

	fld qword [G]				; grav const
	fld qword [r13 + 32]		; mOther
	fmul						; G * mOther

	; calculates distance using the pythagoras theorem
	fild qword [r13 + 8]
	fild qword [r11 + 8]
	fsub						; (locOtherY - locThisY)
	fild qword [r13 + 8]
	fild qword [r11 + 8]
	fsub						; (locOtherY - locThisY)
	fmul						; (locOtherY - locThisY)^2
	fild qword [r13 + 0]
	fild qword [r11 + 0]
	fsub						; (locOtherX - locThisX)
	fild qword [r13 + 0]
	fild qword [r11 + 0]
	fsub						; (locOtherX - locThisX)
	fmul						; (locOtherX - locThisX)^2
	fadd						; distance^2

	fdiv						; ( G * mOther ) / distance^2)
	fmul						; ((G * mOther) / distance^2) * direction
	fld qword [r11 + 16]		; v0
	fadd						; v0 + ((G * mOther) / distance^2) * direction

	fstp qword [r11 + 16]		; saves vel


.next1:

	add r12, 8	; j++
	jmp .objectObjectArrayLoop

.skip1:

	finit
	fild qword [r11 + 8]
	fld qword [r11 + 24]
	fsub
	fistp qword [r11 + 8]		; updates locY

	fild qword [r11 + 0]
	fld qword [r11 + 16]
	fsub
	fistp qword [r11 + 0]		; updates locX



	push r10	; r10 will be changed in next function call

	; XFillRectangle(d, w, DefaultGC(d, s), 20, 20, 10, 10);
	mov rdi, [d]
	mov rsi, [w]
	mov rdx, [defaultGC]
	mov rcx, [r11]
	mov r8, [r11 + 8]
	mov r9, 10
	mov rax, 10
	push rax
	call XFillRectangle
	pop rax	; bruh moment. i don't know why it is required

	pop r10		; welcome back r10

.next2:

	add r10, 8	; i++
	jmp .objectArrayLoop

.skip2:

	ret


initObjects:

	xor r10, r10
.objectArrayLoop:
	mov r11, [objectArray + r10]	; gets objectArray's r10th element
	cmp r11, 0
	je .skip

	push r10	; r10 will be changed in next function call

	; XFillRectangle(d, w, DefaultGC(d, s), 20, 20, 10, 10);
	mov rdi, [d]
	mov rsi, [w]
	mov rdx, [defaultGC]
	mov rcx, [r11]
	mov r8, [r11 + 8]
	mov r9, 10
	mov rax, 10
	push rax
	call XFillRectangle
	pop rax	; bruh moment. i don't know why it is required

	pop r10		; welcome back r10

	add r10, 8	; i++
	jmp .objectArrayLoop

.skip:

	ret