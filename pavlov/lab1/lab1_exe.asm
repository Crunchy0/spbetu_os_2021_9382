AStack segment stack
	dw 64 dup(?)
AStack ends

data segment
	pctype1 db 'PC2 модель 80', 13, 10, '$'
	pctype2 db 'PC Convertible', 13, 10, '$'
	pctype3 db 'PC2 модель 30', 13, 10, '$'
	pctype4 db 'PC/XT (FB)', 13, 10, '$'
	pctype5 db 'AT либо PC2 модель 50 или 60', 13, 10, '$'
	pctype6 db 'PCjr', 13, 10, '$'
	pctype7 db 'PC/XT (FE)', 13, 10, '$'
	pctype8	db 'PC', 13, 10, '$'
	
	dosver db 'Версия DOS: ', 2 dup(?), '.', 2 dup(?), 13, 10, '$'
	oems db 'Серийный номер OEM: ', 2 dup(?), ' HEX', 13, 10, '$'
	users db 'Серийный номер пользователя: ', 6 dup(?), ' HEX$'
	
	defaultmessage db 'Неизвестный номер модели ', 2 dup(?), 13, 10, '$'
	
	types_arr dw pctype1, pctype2, pctype3, pctype4, pctype5, pctype6, pctype7, pctype8	; массив строк
data ends

code segment
	assume ss:AStack, cs:code, ds:data
	
	byte_to_dec proc near
		push ax
		push bx
		push cx
		
		xor ah, ah
		mov bx, 10		; делитель
		xor si, si
		add si, 1		; заполняется с конца
		
		mov cx, 2
		c1:
			div bl
			add ah, '0'	; получается код соответствующей цифры
			push bx
			mov bx, dx
			mov [bx + si], ah	; заносим символ в строку
			pop bx
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
		xor si, si
		add si, 1
		
		mov cx, 2
		c2:
			div bl
			cmp ah, 10
			jl digit
			add ah, 7		; всё аналогично, но если цифра >= 10,
			digit:			; дополнительно прибавляется 7, и получается код соответствующей буквы
				add ah, '0'
			push bx
			mov bx, dx
			mov [bx + si], ah
			pop bx
			dec si
			xor ah, ah
			loop c2
			
		pop cx
		pop bx
		pop ax
		retn
	byte_to_hex endp
	
	pctype proc near
		mov ax, 0F000h
		mov ds, ax
		xor ax,ax			; проверка предпоследнего байта ROM BIOS
		mov ax, [0FFFEh]
		
		mov bx, 0F8h
		mov cx, 8
		check_array:		; проверка типа ПК на соответствие имеющимся
			cmp bl, al
			je eject		; если соответствует
			inc bx
			loop check_array
		jmp default			; если не подогёл ни один
	
		eject:
			mov ax, data
			mov ds, ax
			sub bx, 0F8h
			shl bx, 1
			add bx, offset types_arr	; получение нужной строки
			
			mov dx, [bx]
			jmp exit
			
		default:
			push ax
			mov ax, data
			mov ds, ax
			pop ax
			mov dx, offset defaultmessage	; запись номера в сообщение о неизвестном типе ПК
			add dx, 25
			call byte_to_hex
			sub dx, 25
			
		exit:
		retn
	pctype endp
	
	type_sys_info proc near
		mov dx, offset dosver
		add dx, 12
		call byte_to_dec

		
		mov al, ah
		add dx, 3
		call byte_to_dec
		sub dx, 15
		
		mov ah, 9
		int 21h
		
		mov al, bh
		mov dx, offset oems			; последовательное занесение байтов
		add dx, 20					; с информацией о системе в AL
		call byte_to_hex			; и перевод в нужные СС с записью в строки
		sub dx, 20
		
		int 21h
		
		mov al, bl
		mov dx, offset users
		add dx, 29
		call byte_to_hex
		mov al, ch
		add dx, 2
		call byte_to_hex
		mov al, cl
		add dx, 2
		call byte_to_hex
		sub dx, 33
		
		int 21h
		
		retn
	type_sys_info endp
	
	main proc far
		xor ax, ax
		push ds
		push ax
		
		call pctype				; получение типа ПК и вывод на экран
		mov ah, 9
		int 21h
		
		mov ah, 30h				; получение информации о версии ОС
		int 21h
		
		call type_sys_info		; её вывод на экран
		
		retf
	main endp
code ends
end main