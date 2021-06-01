astack segment stack
	dw 64 dup(0)
astack ends

data segment
	loading_msg db '���뢠��� ����㦥�� � ������', 10, 13, '$'
	loaded db '���뢠��� 㦥 � �����', 10, 13, '$'
	unloading_msg db '���뢠��� ���㦥�� �� �����', 10, 13, '$'
	missing_msg db '���뢠��� ��� � �����', 10, 13, '$'
	lodd db 0
	tounld db 0
data ends

code segment
assume cs:code, ds:data, ss:astack

inter proc far
    jmp init
		substack dw 128 dup(0)		; �������� �⥪, �࠭���� ��� cs � ip
		ip1 dw 0
		cs1 dw 0
		psp1 dw 0
		ax1 dw 0
		ss1 dw 0
		sp1 dw 0
		id dw 0a492h
		k db 0
		
    init:
		mov ax1, ax
		mov sp1, sp
		mov ss1, ss
		mov ax, seg substack
		mov ss, ax
		mov ax, offset substack		; ����ன�� �⥪�
		add ax, 256
		mov sp, ax

		push ax
		push bx
		push cx
		push dx
		push si
        push es
        push ds
        
	in al, 60h
	cmp al, 12h	; �ࠢ����� ᪠�-�����
	je k1
	cmp al, 14h
	je k2
	cmp al, 16h
	je k3
	cmp al, 9h
	je k4
	
	pushf
	call dword ptr cs:ip1	; ��।�� �ࠢ����� �⠭���⭮�� ��ࠡ��稪�, �᫨ �� ���� �� ������
	jmp exit1

	k1:
		mov k, 'l'
		jmp recall
	k2:
		mov k, 'e'			; ������ ᮮ⢥�����饣� ᨬ����
		jmp recall
	k3:
		mov k, 't'
		jmp recall
	k4:
		mov k, 'i'

	recall:
		in al, 61h
		mov ah, al
		or al, 80h
		out 61h, al			; ��⠭���� ��� ࠧ�襭��
		xchg al, al
		out 61h, al
		mov al, 20h
		out 20h, al
			
	to_buff:
		mov ah, 05h
		mov cl, k
		mov ch, 00h
		int 16h
		or al, al
		jz exit1
		mov ax, 0040h		; ������ ᨬ���� � ����
		mov es, ax
		mov ax, es:[1ah]
		mov es:[1ch], ax
		jmp to_buff

	exit1:
		pop ds
		pop es
		pop si
		pop dx
		pop cx
		pop bx
		pop	ax

		mov sp, sp1
		mov ax, ss1			; ����⠭������� ��室��� ���祭�� ᥣ���⮢ �ணࠬ��
		mov ss, ax
		mov ax, ax1

		mov al, 20h
		out 20h, al
	iret
inter endp

seg_end:

load proc
	push ax
	push bx
	push cx
	push dx
	push es
	push ds

	mov ax, 3509h
	int 21h
	mov cs1, es
	mov ip1, bx
	mov ax, seg inter			; ����祭�� �����
	mov ds, ax
	mov dx, offset inter
	
	mov ax, 2509h
	int 21h
	pop	ds
	mov dx, offset seg_end		; ������ � ���� ᢮��� ��ࠡ��稪�
	mov cl, 4
	shr dx, cl
	add	dx, 110h
	mov ax, 3100h				; �ணࠬ�� ������� � �����
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
	mov al, 09h
	int 21h
	mov si, offset ip1
	sub si, offset inter
	mov dx, es:[bx + si]			; ������ �०��� ���祭�� cs � ip �����
	mov ax, es:[bx + si + 2]
	
	push ds
	mov ds, ax
	mov ah, 25h
	mov al, 09h						; ������� ��� ������
	int 21h
	pop ds
	mov ax, es:[bx + si + 4]
	mov es, ax
	push es
	mov ax, es:[2ch]				; ������ ������, ࠭�� ���������� �ணࠬ���
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

is_lodd proc near
	push es
	push ax
	push bx
	push si

	mov ah, 35h
	mov al, 09h
	int 21h
	mov si, offset id
	sub si, offset inter	; �᫨ id �� ᮮ⢥����� ���������, �����, �⠭���⭮� ���뢠���
	mov ax, es:[bx + si]
	cmp	ax, id
	jne exit2
	mov lodd, 1

	exit2:
		pop si
		pop bx
		pop ax
		pop es
	retn
is_lodd endp

is_tounld proc
	push ax
	push es

	mov ax, psp1
	mov es, ax
	cmp byte ptr es:[82h], '-'
	jne exit3
	cmp byte ptr es:[83h], 'd'		; �᫨ � 墮�� ���᮫� �� "-d", �ணࠬ�� ���㦠���� �� �����
	jne exit3
	mov tounld, 1
		
	exit3:
		pop es
		pop ax
		ret
is_tounld endp

print_string proc near
	push    ax
	mov     ah, 09h
	int     21h
	pop     ax
    retn
print_string endp

main proc
	push ds
	xor ax, ax
	push ax
	mov ax, data
	mov ds, ax
	mov psp1, es
	
	call is_tounld
	call is_lodd
	
	cmp lodd, 1
	je ldd
	cmp tounld, 1
	je miss
	
	mov dx, offset loading_msg
	call print_string
	call load
	jmp _exit_
	
	miss:
		mov dx, offset missing_msg		; ������� ��楤��, ��⢫���� � ����ᨬ��� �� ����� ���짮��⥫�
		call print_string
		jmp _exit_
	ldd:
		cmp tounld, 1
		je unld
		mov dx, offset loaded
		call print_string
		jmp _exit_
	unld:
		mov dx, offset unloading_msg
		call print_string
		call unload
	_exit_:
		mov ax, 4c00h
		int 21h
	main endp
code    ends
end 	main