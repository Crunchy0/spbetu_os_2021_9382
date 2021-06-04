Astack segment stack
	dw 64 dup(?)
Astack ends

data segment
	loaded db 0
	tounld db 0
	msg_loading db "Обработчик загружен в память",10,13,"$"
	msg_loaded db "Обработчик уже загружен",10,13,"$"
	msg_unloading db "Обработчик выгружен из памяти",10,13,"$"
	msg_unloaded db "Нет загруженного обработчика",10,13,"$"
data ends

code segment
	assume cs:code, ds:data, ss:Astack

	inter proc far
		jmp init
		counter db "0000 вызовов"
		id dw 2228h
		save_cs dw 0
		save_ip dw 0
		save_psp dw 0
		save_ax dw 0
		save_ss dw 0
		save_sp dw 0
		substack dw 64 dup(?)

		init:
			mov save_ax, ax
			mov save_sp, sp
			mov save_ss, ss
			mov ax, seg substack
			mov ss, ax
			mov ax, offset substack
			add ax, 128
			mov sp, ax

		push ax
		push bx
		push cx
		push dx
		push si
		push es
		push ds
		mov ax, seg counter
		mov ds, ax

		mov ah, 03h
		mov bh, 0h
		int 10h
		push dx

		mov ah, 02h
		mov bh, 0h
		mov dx, 0141h 
		int 10h

		mov si, offset counter
		add	si, 3
		mov cx, 4

		increase:
			mov ah, [si]
			cmp ah, '9'
				jl increaseD
			sub ah, 9
			mov [si], ah
			dec si
			loop increase		
		increaseD:
			cmp cx, 0
				je reset
			inc ah
			mov [si], ah
		reset:

		push es
		push bp
		mov ax, seg counter
		mov es, ax
		mov bp, offset counter
		mov ah, 13h
		mov al, 1h
		mov bl, 2h
		mov bh, 0
		mov cx, 12
		int 10h

		pop bp
		pop es
		pop dx
		mov ah, 02h
		mov bh, 0h
		int 10h

		pop ds
		pop es
		pop	si
		pop dx
		pop cx
		pop bx
		pop	ax

		mov sp, save_sp
		mov ax, save_ss
		mov ss, ax
		mov ax, save_ax

		mov al, 20h
		out 20h, al
		iret
	inter endp

	inter_end:

	is_loaded proc
		push ax
		push bx
		push si

		mov ax, 351ch
		int 21h
		mov si, offset id - offset inter
		mov ax, es:[bx + si]
		cmp	ax, id
			jne is_loaded_ret
		mov loaded, 1

		is_loaded_ret:
			pop si
			pop bx
			pop ax
			ret
	is_loaded endp
	
	is_tounld proc
		push ax
		push es

		mov ax, save_psp
		mov es, ax
		cmp byte ptr es:[82h], '-'
			jne is_tounld_ret
		cmp byte ptr es:[83h], 'u'
			jne is_tounld_ret
		mov tounld, 1

		is_tounld_ret:
			pop es
			pop ax
			ret
	is_tounld endp

	load proc
		push ax
		push bx
		push cx
		push dx
		push es
		push ds

		mov ah, 35h
		mov al, 1ch
		int 21h
		mov save_cs, es
		mov save_ip, bx
		mov ax, seg inter
		mov ds, ax
		mov dx, offset inter
		mov ah, 25h
		mov al, 1ch
		int 21h
		pop ds

		mov dx, offset inter_end
		mov cl, 4h
		shr dx, cl
		add dx, 100h
		xor ax, ax
		mov ah, 31h
		int 21h

		pop es
		pop dx
		pop cx
		pop bx
		pop ax
		ret
	load endp

	unload proc
		cli
		push ax
		push bx
		push dx
		push ds
		push es
		push si

		mov ah, 35h
		mov al, 1ch
		int 21h
		mov si, offset save_cs
		sub si, offset inter
		mov ax, es:[bx + si]
		mov dx, es:[bx + si + 2]

		push ds
		mov ds, ax
		mov ax, 251ch
		int 21h
		pop ds

		mov ax, es:[bx + si + 4]
		mov es, ax
		push es
		mov ax, es:[2ch]
		mov es, ax
		mov ah, 49h
		int 21h
		pop es
		mov ah, 49h
		int 21h

		sti

		pop si
		pop es
		pop ds
		pop dx
		pop bx
		pop ax

		ret
	unload endp

	print_string proc near
		push ax
		mov ah, 09h
		int 21h
		pop ax
		retn
	print_string endp

	main proc
		push ds
		xor ax, ax
		push ax
		mov ax, data
		mov ds, ax
		mov save_psp, es

		call is_loaded
		call is_tounld
		cmp tounld, 1
			je to_unload
		cmp loaded, 1
			jne to_load
		mov dx, offset msg_loaded
		call print_string
		jmp main_ret

		to_load:
			mov dx, offset msg_loading
			call print_string
			call load
			jmp main_ret

		to_unload:
			cmp loaded, 1
				jne not_to_unload
			mov dx, offset msg_unloading
			call print_string
			call unload
			jmp main_ret

		not_to_unload:
			mov dx, offset msg_unloaded
			call print_string

		main_ret:
			mov	ax, 4c00h
			int	21h
	main endp
code ends
end main