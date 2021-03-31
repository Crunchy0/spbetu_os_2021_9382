.model tiny

.code
	org 100h
	
	main proc far
		xor ax, ax
		push ds
		push ax
		
		call print_mem_size
		call free
		call extend
		call print_mcbs
		call free
		
		mov ah, 4Ch
		int 21h
		
		retf
	main endp
	
	extend proc near
	mov bx, 1000h
	mov ah, 48h
	int 21h
	
	mov dx, offset ext_report
	call print_string

	jc deny

	add dx, 23
	call print_string
	jmp exit1

	deny:
	   add dx, 34
	   call print_string
	   jmp exit1

	exit1:
	   retn
	extend endp
	
	free proc near
    mov ax, offset edge
    mov bx, 10h
    xor dx, dx
    div bx
    inc ax
    mov bx, ax
    mov ah, 4ah
    int 21h
    retn
	free endp
	
	clr_mem proc near
	reset:
		mov byte ptr [si], ' '
		inc si
		loop reset
	retn
	clr_mem endp
	
	print_string proc near
		push ax
		mov ah, 9
		int 21h
		pop ax
		retn
	print_string endp
	
	byte_to_dec proc near
		push ax
		push bx
		push cx
		
		xor ah, ah
		mov bx, 10
		add si, 2
		
		mov cx, 3
		c1:
			div bl
			add ah, '0'
			mov [si], ah
			dec si
			xor ah,ah
			loop c1
			
		pop cx
		pop bx
		pop ax
		retn
	byte_to_dec endp
	
	byte_to_hex proc near
		push ax
		push bx
		push cx
		
		xor ah, ah
		mov bx, 16
		add si, 1
		
		mov cx, 2
		c2:
			div bl
			cmp ah, 10
			jl digit1
			add ah, 7
			digit1:
				add ah, '0'
			mov [si], ah
			dec si
			xor ah, ah
			loop c2

		pop cx
		pop bx
		pop ax
		retn
	byte_to_hex endp
		
	word_to_hex proc near
		push ax
		push bx
		push cx
		push dx
		
		xor dx, dx
		mov bx, 16
		add si, 3
		
		mov cx, 4
		c3:
			div bx
			cmp dl, 10
			jl digit2
			add dl, 7
			digit2:
				add dl, '0'
			mov [si], dl
			dec si
			xor dx, dx
			loop c3
			
		pop dx
		pop cx
		pop bx
		pop ax
		retn
	word_to_hex endp
	
	mem_to_dec proc near
		push ax
    push bx
    push cx
    push dx
    push si

	mov bx, 10h
	mul bx
	mov bx, 0ah
	xor cx, cx

	remnants:
	div bx
	push dx
	inc cx
	xor dx, dx
	cmp ax, 0h
	jnz remnants

	xtoc:
	pop dx
	or dl, 30h
	mov [si], dl
	inc si
	loop xtoc

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
	retn
	mem_to_dec endp
	
	print_mem_size proc near
    mov ah, 4ah
    mov bx, 0ffffh
    int 21h
    mov ax, bx
	
    mov si, offset av_mem + 25
    call mem_to_dec
    mov dx, offset av_mem
    call print_string

    mov al, 30h
    out 70h, al
    in al, 71h
    mov al, 31h
    out 70h, al
    in al, 71h
    mov ah, al

    mov si, offset ext_mem + 27
    call mem_to_dec
    mov dx, offset ext_mem
    call print_string

    retn
	print_mem_size endp
	
	print_mcb_info proc near
    push ax
    push dx
    push si
    push di
    push cx

    mov ax, es
    mov si, offset MCB_addr + 7
    call word_to_hex
    mov dx, offset MCB_addr
    call print_string

    mov ax, es:[1]
    mov si, offset PSP_addr + 5
    call word_to_hex
    mov dx, offset PSP_addr
    call print_string

    mov ax, es:[3]
    mov si, offset MCB_size + 8
    call mem_to_dec
    mov dx, offset MCB_size
    call print_string

    mov dx, offset SC_SD
    call print_string
    
	add dx, 8
	push dx
	mov si, 8
	mov cx, 8
	scsd_out:
		mov dl, es:[si]
		mov ah, 02h
		int 21h
		inc si
		loop scsd_out
		
	pop dx
	call print_string

    pop cx
    pop di
    pop si
    pop dx
    pop ax

    retn
	print_mcb_info endp
	
	print_mcbs proc near

    push es

    mov ah, 52h
    int 21h
    mov es, es:[bx-2]
    mov cl, 1

	iter_mcb:
		mov si, offset MCB_num + 6
		mov al, cl
		call byte_to_dec
		mov dx, offset MCB_num
		call print_string

		call print_mcb_info

		mov al, es:[0]
		cmp al, 5ah
		je exit

		mov bx, es:[3]
		mov ax, es
		add ax, bx
		inc ax
		mov es, ax

		inc cl
		
		push cx
		mov si, offset MCB_num + 6
		mov cx, 3
		call clr_mem
		
		mov si, offset MCB_size + 8
		mov cx, 6
		call clr_mem		
		pop cx
		
		jmp iter_mcb

	exit:
		pop es

    retn
	print_mcbs endp
	
	
	av_mem db 'Размер доступной памяти: ', 6 dup(?), ' байт', 13, 10, '$'
	ext_mem db 'Размер расширенной памяти: ', 6 dup(?), ' байт', 13, 10, '$'
	
	MCB_num db 'Блок №   : ', '$'
	MCB_addr db 'Адрес: ', 4 dup(?), '; $'
	PSP_addr db 'PSP: ', 4 dup(?), '; $'
	MCB_size db 'Размер: ', 6 dup(?), ' байт', '; $'
	SC_SD db 'SC/CD: $', 13, 10, '$'
	ext_report db 'Выделение доп. памяти $успешно.', 13, 10, '$отменено.', 13, 10, '$'
	
	edge:
end main