.model tiny

.code
	org 100h
	
	main proc far
		xor ax, ax
		push ds
		push ax
		
		mov ax, ds:[2]
		mov dx, offset unav_mem + 26		; ������ ���� ������㯭��
		call word_to_hex					; ����� � ��ப�, �����
		sub dx, 26
		call print_string
		
		mov ax, ds:[2Ch]
		mov dx, offset envir_adress + 13	; ������ ���� �।�
		call word_to_hex					; � ��ப�, �����
		sub dx, 13
		call print_string
		
		call print_tail						; ����� ���ଠ樨 � 墮�� ���᮫�
		
		call print_envir_path				; ����� ���ଠ樨 � �।� � ���
		
		mov dl, 13
		int 21h								; ������ ���⪨, �����襭��
		retf
	main endp
	
	print_string proc near					; ��楤�� ���� ��ப�
		push ax								; (� dx ��࠭�� ������ ����)
		mov ah, 9
		int 21h
		pop ax
		retn
	print_string endp
	
	byte_to_dec proc near					; ��ॢ�� ���⮢��� ���祭�� � 10 ��
		push ax
		push bx
		push cx
		
		xor ah, ah
		mov bx, 10							; �����⮢�� ������ (bx - ����⥫�)
		xor si, si
		add si, 1
		
		mov cx, 2
		c1:
			div bl
			add ah, '0'
			push bx
			mov bx, dx
			mov [bx + si], ah				; 横� ����� �᫠ � ����
			pop bx
			dec si
			xor ah,ah
			loop c1
			
		pop cx
		pop bx
		pop ax
		retn
	byte_to_dec endp
	
	byte_to_hex proc near					; ��ॢ�� ���⮢��� ���祭�� � 16 ��
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
				add ah, '0'					; �������筮 �।��饬�, ��
			push bx							; ���뢠���� ����������� ������ ᨬ�����
			mov bx, dx						; ��⨭᪮�� ��䠢��
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
		
	word_to_hex proc near					; ��ॢ�� ᫮�� � 16 ��
		push ax
		push bx
		push cx
		push dx
		
		xor dx, dx
		xor si, si
		add si, 3
		
		mov cx, 4							; 4 ����७�� 横��, � �⫨稥 �� �।��饣�
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
	
	print_tail proc near					; �뢮� ���ଠ樨 � 墮�� ���᮫�
		mov dx, offset tail_info
		call print_string
		
		mov di, 80h
		xor cx, cx
		mov cl, [di]						; ����祭�� ���-�� ᨬ�����
		mov ah, 2							; � ��⠭���� � ०�� ��ᨬ���쭮�� �뢮��
		cmp cl, 0
		je void
		inc di
		tail:
			mov dl, [di]					; 横� ࠡ�⠥�, �᫨ 墮�� �� ����
			int 21h
			inc di
			loop tail
		jmp escape_the_void
		
		void:
			mov dx, offset no_tail			; �᫨ �� ���� - �뢮����� ᮮ�饭�� �� �⮬
			call print_string
		
		escape_the_void:					; � ����� ����� ������ ���⠥���
			mov dl, 10						; ��७�� �� ����� ��ப�
			int 21h
			int 21h
		
		retn
	print_tail endp
	
	print_envir_path proc near				; �뢮� ���ଠ樨 � �।� � ���
		push ds

		mov dx, offset envir_content
		call print_string
		
		xor di, di
		mov ax, ds:[2Ch]					; ���室 �� ��㣮� ᥣ����� ����
		mov ds, ax
		mov ah, 2							; � ��⠭���� � ०�� ��ᨬ���쭮�� �뢮��
		whilee:
			mov dl, [di]
			cmp dl, 0
			je zero							; �����, ���� �� ����祭 0-���� (����� ��ப�)
			int 21h
			inc di
			jmp whilee
			
			zero:
				inc di
				mov dl, 10
				int 21h
				mov dl, [di]
				cmp dl, 0					; �᫨ � ��᫥ ���� ��ப� 0-����
				jne whilee					; � ����� ���ଠ樨 � �।�, ���� �������
		
		mov dl, 10
		int 21h
		add di, 3
		push ds
		push ax
		mov ax, es
		mov ds, ax
		mov dx, offset path_info			; �뢮� ��ப� � ������祭��� ���
		call print_string
		pop ax
		pop ds
		
		path:
			mov dl, [di]
			cmp dl, 0
			je stop							; ⠪�� ��ᨬ����� �뢮� ���ଠ樨
			int 21h							; � ��� ���� �� ����祭 0-����
			inc di
			jmp path
			
		stop:
			mov dl, 10						; ��७�� �� ����� ��ப�
			int 21h
				
		pop ds
		retn
	print_envir_path endp
	
	unav_mem db '���� ������㯭�� �����: ', 4 dup(?), 13, 10, 10, '$'
	envir_adress db '���� �।�: ', 4 dup(?), 13, 10, 10, '$'
	tail_info db '����� ���᮫�:$'
	no_tail db ' ����, ��� ��㬥�⮢.$'
	envir_content db '����ন��� �।�:', 10, '$'
	path_info db '����:', 10, '$'
	
end main