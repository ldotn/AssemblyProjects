	BITS 16
start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax

.gamestart:
	; set seed
	call setseed
	
	mov ah, 00h
	mov al, 13h
	int 10h

	mov cx,160
	mov dx,120
	mov ah,0Ch
	mov al,12
	int 10h

	xor bx,bx; 13h video mode doesn't have pages, so the bx register is free for use

	.keyloop:
		xor ax,ax
		int 16h
		cmp al,0
		je .keyloop

		; print mines or boosters
		; using an xor-shift RNG
		push ax
		push dx
		push cx
		push bx

		call rng ; returns in ax register
		; make sure the values stay inside the screen
		xor dx,dx
		mov bx, 320
		div bx
		mov cx,dx

		call rng
		xor dx,dx
		mov bx, 200
		div bx
		
		pop bx
		; randomly select between boosters and mines
		; p = 1/8 of booster
		call rng
		and al, 7
		mov ah,0Ch
		jz .booster
		
		.mine:
			mov al,04
			int 10h
			inc cx
			inc dx
			int 10h
			sub dx,2
			int 10h
			sub cx,2
			int 10h
			add dx,2
			int 10h
			jmp .itemclean
		.booster:
			; have the center of a different color, to prevent using the same booster multiple times
			mov al,2fh 
			int 10h
			mov al,33h
			inc cx
			int 10h
			sub cx,2
			int 10h
			dec dx
			inc cx
			int 10h
			add dx,2
			int 10h
		.itemclean:
			pop cx
			pop dx
			pop ax

		cmp al,'w'
		je .up
		cmp al,'a'
		je .left
		cmp al,'s'
		je .down
		cmp al,'d'
		je .right
		jmp .keyloop

		.up:
			dec dx
			jmp .print
		.left:
			dec cx
			jmp .print
		.right:
			inc cx
			jmp .print
		.down:
			inc dx
		.print:
			mov ah,0Dh
			int 10h
			cmp al,2fh ; check if it hit the center of a booster by checking the color
			je .boostscore
			cmp al,33h ; ignore the corners of a boosterr
			je .printsnake
			cmp al,0
			jne .lost
			jmp .printsnake

			.boostscore:
				add bx, 50 ; hit a booster, so increase score

			.printsnake:
				; change color based on second / 8
				push cx 
				push dx
				mov ah,02h
				int 1Ah
				mov al,dh
				shr al,3
				add al,50h ; change color line on the palette http://www.fountainware.com/EXPL/vga_color_palettes.htm
				pop dx
				pop cx
				mov ah,0Ch
				int 10h

		inc byte [4]
		push bx
		mov bl, byte [4]
		and bl, 3 ; = bl % 4
		pop bx
		jnz .wincheck

		inc bx
		.wincheck:
			cmp bx,900
			jge .win
		call printscore
	jmp .keyloop

.gamereset:
	mov bl, 12
	mov ah, 0Eh
	mov al,13
	int 10h
	mov al,0Ah ;new line
	int 10h

	mov ah,02h
	int 1Ah
	xor bl,bl
	mov bh,dh
	.rloop:
		mov ah,02h
		int 1Ah
		cmp bl,10
		jg .gamestart
		cmp dh,bh
		mov bh,dh
		jle .rloop
		inc bl
		push bx
		mov bl, 12
		mov ah, 0Eh
		mov al,'.'
		int 10h
		pop bx
		jmp .rloop
.win:
	mov bl, 12
	mov ah, 0Eh
	mov al,13
	int 10h

	mov al,'Y'
	int 10h
	mov al,'o'
	int 10h
	mov al,'u'
	int 10h
	mov al,' '
	int 10h
	mov al,'W'
	int 10h
	mov al,'o'
	int 10h
	mov al,'n'
	int 10h
	mov al,'!'
	int 10h
	jmp .gamereset
	
.lost:
	mov bl, 12
	mov ah, 0Eh
	mov al,13
	int 10h
	
	mov al,'Y'
	int 10h
	mov al,'o'
	int 10h
	mov al,'u'
	int 10h
	mov al,' '
	int 10h
	mov al,'L'
	int 10h
	mov al,'o'
	int 10h
	mov al,'s'
	int 10h
	mov al,'t'
	int 10h
	mov al,'!'
	int 10h
	jmp .gamereset

printscore:
	push dx
	push ax
	push bx

	xor dx,dx
	xor bh,bh
	mov ah,02h ; reset cursor
	int 10h
	
	pop bx
	mov ax,bx
	push bx
	mov bl,10
	
	div bl
	push ax
	xor ah,ah
	div bl
	push ax
	xor ah,ah
	div bl
	
	xor bh,bh
	mov bl,12
	
	mov al,ah
	add al,48
	mov ah,0Eh
	int 10h
	
	pop ax
	mov al,ah
	add al,48
	mov ah,0Eh
	int 10h
	
	pop ax
	mov al,ah
	add al,48
	mov ah,0Eh
	int 10h
	
	pop bx
	pop ax
	pop dx
	ret
rng:
	push bx
	mov ax,[0]

	mov bx,ax
	shl ax,5
	xor ax,bx

	mov bx,ax
	shr ax,3
	xor ax,bx

	mov bx,ax
	shl ax,1
	xor ax,bx
	
	mov [0],ax
	pop bx
	ret

; not storing the registers to make the code fit
; that makes this function quite dangerous if called without care for the registers values
setseed:
	mov ah,02h

	int 1Ah ; get time
	mov al,dh ; seconds
	add ax,cx ; hours:minutes
	mov [0],ax

	ret

times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
dw 0xAA55		; The standard PC boot signature