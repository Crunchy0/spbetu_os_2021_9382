astack segment stack
	dw 64 dup(?)
astack ends

data segment
	mem_error1 db 'Ошибка: Разрушен управляющий блок памяти', 0dh, 0ah, '$' 
	mem_error2 db 'Ошибка: Недостаточно памяти', 0dh, 0ah, '$' 
	mem_error3 db 'Ошибка: Недействительный адрес памяти', 0dh, 0ah, '$'
	mem_error4 db 'Память успешно очищена' , 0dh, 0ah, '$'

	child_error1 db 'Ошибка: Недействительный номер функции', 0dh, 0ah, '$' 
	child_error2 db 'Ошибка: Файл не найден', 0dh, 0ah, '$' 
	child_error3 db 'Ошибка: сбой диска', 0dh, 0ah, '$' 
	child_error4 db 'Ошибка: недостаточно памяти', 0dh, 0ah, '$' 
	child_error5 db 'Ошибка: неправильная строка среды', 0dh, 0ah, '$' 
	child_error6 db 'Ошибка: неверный формат', 0dh, 0ah, '$' 
	
	terminate1 db 0dh, 0ah, 'Завершено с кодом    ' , 0dh, 0ah, '$'
	terminate2 db 0dh, 0ah, 'Завершено по Ctrl-Break' , 0dh, 0ah, '$'
	terminate3 db 0dh, 0ah, 'Завершено по ошибке устройства' , 0dh, 0ah, '$'
	terminate4 db 0dh, 0ah, 'Завершено по функции 31h, программа оставлена в памяти резидентно' , 0dh, 0ah, '$'
	
	mem_allocated db 0
	ss1 dw 0
	sp1 dw 0
	psp dw 0
	
	params dw 0
			dd 0
			dd 0
			dd 0
	cline db 1, 0dh
	path db 64 dup(0)
	child db 'lab2.com', 0
data ends

code segment
assume cs:code, ds:data, ss:astack

free proc near
	push ax
	push bx
	push cx
	push dx
	
	mov ax, offset child + 9
	mov bx, offset codends
	add bx, ax
	mov cl, 4
	shr bx, cl
	add bx, 30h
	mov ah, 4ah
	int 21h 
	jnc exit1
	
	mem_err1:
		cmp ax, 7
		jne mem_err2
		mov dx, offset mem_error1
		jmp mem_ret	
	mem_err2:
		cmp ax, 8
		jne mem_err3
		mov dx, offset mem_error2
		jmp mem_ret	
	mem_err3:
		mov dx, offset mem_error3
		jmp mem_ret
	exit1:
		mov mem_allocated, 1
		mov dx, offset mem_error4
	mem_ret:
		call print_string
		pop dx
		pop cx
		pop bx
		pop ax
		retn
free endp

find_path proc near
	push ax
	push bx
	push cx 
	push dx
	push di
	push si
	push es
	
	mov ax, psp
	mov es, ax
	mov es, es:[2ch]
	mov bx, 0
	
	seek_path:
		inc bx
		cmp byte ptr es:[bx-1], 0
		jne seek_path
		cmp byte ptr es:[bx+1], 0 
		jne seek_path
	
	add bx, 2
	mov di, 0
	
	write_dir:
		mov dl, es:[bx]
		mov byte ptr [path+di], dl
		inc di
		inc bx
		cmp dl, 0
		je quit
		cmp dl, '\'
		jne write_dir
		mov cx, di
		jmp write_dir
	quit:
		mov di, cx
		mov si, 0
	
	child_append:
		mov dl, byte ptr [child+si]
		mov byte ptr [path+di], dl
		inc di 
		inc si
		cmp dl, 0 
		jne child_append
		
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	retn
find_path endp

run proc near
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	mov sp1, sp
	mov ss1, ss
	
	mov ax, data
	mov es, ax
	mov bx, offset params
	mov dx, offset cline
	mov [bx+2], dx
	mov [bx+4], ds 
	mov dx, offset path
	
	mov ax, 4b00h 
	int 21h 
	
	mov ss, ss1
	mov sp, sp1
	pop es
	pop ds
	
	jnc processing
	
	child_err1:
		cmp ax, 1
		jne child_err2
		mov dx, offset child_error1
		jmp exit2
	child_err2:
		cmp ax, 2
		jne child_err3
		mov dx, offset child_error2
		jmp exit2
	child_err3:
		cmp ax, 5
		jne child_err4
		mov dx, offset child_error3
		jmp exit2
	child_err4:
		cmp ax, 8
		jne child_err5
		mov dx, offset child_error4
		jmp exit2
	child_err5:
		cmp ax, 10
		jne child_err6
		mov dx, offset child_error5
		jmp exit2
	child_err6:
		mov dx, offset child_error6
		jmp exit2

	processing:
		mov ax, 4d00h
		int 21h 
	
	termt1:
		cmp ah, 0
		jne termt2
		push di 
		mov di, offset terminate1
		mov [di+20], al 
		pop di
		mov dx, offset terminate1
		jmp exit2
	termt2:
		cmp ah, 1
		jne termt3
		mov dx, offset terminate2 
		jmp exit2
	termt3:
		cmp ah, 2 
		jne termt4
		mov dx, offset terminate3
		jmp exit2
	termt4:
		cmp ah, 3
		mov dx, offset terminate4

	exit2:
		call print_string 
		pop dx
		pop cx
		pop bx
		pop ax
		retn
run endp

print_string proc near
 	push ax
 	mov ah, 9
 	int 21h 
 	pop ax
 	retn
print_string endp 

main proc far
	push ds
	xor ax, ax
	push ax
	mov ax, data
	mov ds, ax
	mov psp, es
	
	call free 
	cmp mem_allocated, 0
	je failed
	call find_path
	call run
	
	failed:
		xor al, al
		mov ah, 4ch
		int 21h
main endp
codends:
code ends
end main