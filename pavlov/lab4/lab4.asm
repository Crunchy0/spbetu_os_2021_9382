assume cs:code, ds:data, ss:Astack

Astack segment stack
	dw 32 dup(?)
Astack ends

code segment

inter_1Ch proc far
	jmp init_counter

	psp1 dw 0
	psp2 dw 0
	save_cs dw 0
	save_ip dw 0
	is_timer_set dw 0fedch
	counter db 'Вызовов прерывания: 0000  $'

init_counter:
	push ax
	push bx
	push cx
	push dx

	mov ah, 3
	xor bh, bh
	int 10h
	push dx
	mov ah, 2
	xor bh, bh
	mov dx, 828h
	int 10h

	push si
	push cx
	push ds
	mov ax, seg counter
	mov ds, ax
	mov si, offset counter
	add si, 23

	mov ah,[si]
	inc ah
	mov [si], ah
	cmp ah, 3ah
	jne print_timer
	mov ah, 30h
	mov [si], ah

	mov bh, [si - 1]
	inc bh
	mov [si - 1], bh
	cmp bh, 3ah
	jne print_timer
	mov bh, 30h
	mov [si - 1], bh

	mov ch, [si - 2]
	inc ch
	mov [si - 2], ch
	cmp ch, 3ah
	jne print_timer
	mov ch, 30h
	mov [si - 2], ch

	mov dh, [si - 3]
	inc dh
	mov [si - 3], dh
	cmp dh, 3ah
	jne print_timer
	mov dh, 30h
	mov [si - 3],dh

print_timer:
    pop ds
    pop cx
	pop si

	push es
    push bp
    mov ax, seg counter
    mov es, ax
    mov bp, offset counter
    mov ax, 1300h
    mov cx, 24
    mov bh, 0
    int 10h
    pop bp
	pop es
	pop dx
	mov ah, 2
	xor bh, bh
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax
	iret
inter_1Ch endp

print_string proc near
	push ax
	mov ah, 9h
	int	21h
	pop ax
	retn
print_string endp

reserve proc
reserve endp

is_set proc near
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1ch
	int 21h

	mov dx, es:[bx + 11]
	cmp dx, 0fedch
	je is
	xor al, al
	jmp isnt

	is:
		mov al, 1
	isnt:
		pop es
		pop dx
		pop bx
	retn
is_set endp

param proc near
	push es

	mov ax, psp1
	mov es, ax
	mov bx, 82h

	mov al, es:[bx]
	inc bx
	cmp al, '/'
	jne unknown_param

	mov al, es:[bx]
	inc bx
	cmp al, 'u'
	jne unknown_param

	mov al, es:[bx]
	inc bx
	cmp al, 'n'
	jne unknown_param

	mov al, 1
	unknown_param:
		pop es
		retn
param endp

load proc near
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1ch
	int 21h
	mov save_ip, bx
	mov save_cs, es
	
	push ds
    mov ax, seg inter_1Ch
    mov ds, ax
	mov dx, offset inter_1Ch
    mov ah, 25h
    mov al, 1ch
    int 21h
	pop ds

	mov dx, offset ld_in_process
	call print_string

	pop es
	pop dx
	pop bx
	pop ax
	retn
load endp

unload proc near
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1ch
	int 21h

	cli
	push ds
    mov dx, es:[bx + 9]
    mov ax, es:[bx + 7]
    mov ds, ax
    mov ah, 25h
    mov al, 1ch
    int 21h
	pop ds
	sti

	mov dx, offset unloaded
	call print_string

	push es
    mov cx, es:[bx + 3]
    mov es, cx
    mov ah, 49h
    int 21h
	pop es

	mov cx, es:[bx + 5]
	mov es, cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax

	retn
unload endp

main proc far
	mov bx, 2ch
	mov ax, [bx]
	mov psp2, ax
	mov psp1, ds
	sub ax, ax
	xor bx, bx

	mov ax, data
	mov ds, ax

	call param
	cmp al, 1
	je tounld

	call is_set
	cmp al, 1
	jne nload

	mov dx, offset loaded
	call print_string
	jmp exit

	mov ah,4ch
	int 21h

	nload:
		call load

		mov dx, offset reserve
		mov cl, 4
		shr dx, cl
		add dx, 1bh

		mov ax, 3100h
		int 21h

	tounld:
		call is_set
		cmp al, 0
		je is_missing
		call unload
		jmp exit

	is_missing:
		mov dx, offset missing
		call print_string

	exit:
		mov ah, 4ch
		int 21h
main endp

code ends

data segment
	missing db "Не найдено прерывание в памяти", 13, 10, '$'
	unloaded db "Прерывание выгружено из памяти", 13, 10, '$'
	loaded db "Прерывание уже загружено в память", 13, 10, '$'
	ld_in_process db "Загрузка прерывания в память", 13, 10, '$'
data ends

end main