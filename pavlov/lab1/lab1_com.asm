.model tiny

.code
	org 100h
	
	main proc far
		xor ax, ax
		push ds
		push ax
		
		mov ax, ds:[2]
		mov dx, offset unav_mem + 26		; запись адреса недоступной
		call word_to_hex					; памяти в строку, печать
		sub dx, 26
		call print_string
		
		mov ax, ds:[2Ch]
		mov dx, offset envir_adress + 13	; запись адреса среды
		call word_to_hex					; в строку, печать
		sub dx, 13
		call print_string
		
		call print_tail						; печать информации о хвосте консоли
		
		call print_envir_path				; печать информации о среде и пути
		
		mov dl, 13
		int 21h								; возврат каретки, завершение
		retf
	main endp
	
	print_string proc near					; процедура печати строки
		push ax								; (в dx заранее помещён адрес)
		mov ah, 9
		int 21h
		pop ax
		retn
	print_string endp
	
	byte_to_dec proc near					; перевод байтового значения в 10 СС
		push ax
		push bx
		push cx
		
		xor ah, ah
		mov bx, 10							; подготовка данных (bx - делитель)
		xor si, si
		add si, 1
		
		mov cx, 2
		c1:
			div bl
			add ah, '0'
			push bx
			mov bx, dx
			mov [bx + si], ah				; цикл записи числа с конца
			pop bx
			dec si
			xor ah,ah
			loop c1
			
		pop cx
		pop bx
		pop ax
		retn
	byte_to_dec endp
	
	byte_to_hex proc near					; перевод байтового значения в 16 СС
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
			jl digit1
			add ah, 7
			digit1:
				add ah, '0'					; аналогично предыдущему, но
			push bx							; учитывается возможность появления символов
			mov bx, dx						; латинского алфавита
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
		
	word_to_hex proc near					; перевод слова в 16 СС
		push ax
		push bx
		push cx
		push dx
		
		xor dx, dx
		xor si, si
		add si, 3
		
		mov cx, 4							; 4 повторения цикла, в отличие от предыдущего
		c3:
			mov bx, 16
			div bx
			cmp dl, 10
			jl digit2
			add dl, 7
			digit2:
				add dl, '0'
			pop bx
			mov [bx + si], dl
			push bx
			dec si
			xor dx, dx
			loop c3
			
		pop dx
		pop cx
		pop bx
		pop ax
		retn
	word_to_hex endp
	
	print_tail proc near					; вывод информации о хвосте консоли
		mov dx, offset tail_info
		call print_string
		
		mov di, 80h
		xor cx, cx
		mov cl, [di]						; получение кол-ва символов
		mov ah, 2							; и установка в режим посимвольного вывода
		cmp cl, 0
		je void
		inc di
		tail:
			mov dl, [di]					; цикл работает, если хвост не пуст
			int 21h
			inc di
			loop tail
		jmp escape_the_void
		
		void:
			mov dx, offset no_tail			; если же пуст - выводится сообщение об этом
			call print_string
		
		escape_the_void:					; в обоих случаях дважды печатается
			mov dl, 10						; перенос на новую строку
			int 21h
			int 21h
		
		retn
	print_tail endp
	
	print_envir_path proc near				; вывод информации о среде и пути
		push ds

		mov dx, offset envir_content
		call print_string
		
		xor di, di
		mov ax, ds:[2Ch]					; переход на другой сегментный адрес
		mov ds, ax
		mov ah, 2							; и установка в режим посимвольного вывода
		whilee:
			mov dl, [di]
			cmp dl, 0
			je zero							; печать, пока не встречен 0-байт (конец строки)
			int 21h
			inc di
			jmp whilee
			
			zero:
				inc di
				mov dl, 10
				int 21h
				mov dl, [di]
				cmp dl, 0					; если и после конца строки 0-байт
				jne whilee					; то конец информации о среде, иначе повторить
		
		mov dl, 10
		int 21h
		add di, 3
		push ds
		push ax
		mov ax, es
		mov ds, ax
		mov dx, offset path_info			; вывод строки с обозначением пути
		call print_string
		pop ax
		pop ds
		
		path:
			mov dl, [di]
			cmp dl, 0
			je stop							; также посимвольный вывод информации
			int 21h							; о пути пока не встречен 0-байт
			inc di
			jmp path
			
		stop:
			mov dl, 10						; перенос на новую строку
			int 21h
				
		pop ds
		retn
	print_envir_path endp
	
	unav_mem db 'Адрес недоступной памяти: ', 4 dup(?), 13, 10, 10, '$'
	envir_adress db 'Адрес среды: ', 4 dup(?), 13, 10, 10, '$'
	tail_info db 'Хвост консоли:$'
	no_tail db ' пуст, нет аргументов.$'
	envir_content db 'Содержимое среды:', 10, '$'
	path_info db 'Путь:', 10, '$'
	
end main