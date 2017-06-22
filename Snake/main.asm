	BITS 16

start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax
.gamestart:
	mov ah, 00h
	mov al, 13h
	int 10h
	
	mov ah,02h
	int 1Ah
	mov dh,[104] ; store prev time (seconds)
	
	mov cx,160
	mov dx,120
	mov ah,0Ch
	mov al,12
	int 10h

	mov bx,0; 13h video mode doesn't have pages, so the bx register is free for use
	
	mov word [100],0 ; x direction
	mov word [102],1 ; y direction
	
	.keyloop:
		push dx
		
		.waitloop:
			mov ah,02h
			int 1Ah
			cmp dh,[104] ; check if the seconds changed since last call (busy waiting)
			je .waitloop
			
		mov [104], dh ; update stored time
		pop dx
		
		mov ah,00h
		mov al,0
		int 16h
		
		cmp al,'w'
		je .up
		cmp al,'a'
		je .left
		cmp al,'s'
		je .down
		cmp al,'d'
		je .right
		jmp .print ; the user pressed any other key or nothing at all
		
		.up:
			mov word [100],0
			mov word [102],1
			jmp .print
		.left:
			mov word [100],-1
			mov word [102],0
			jmp .print
		.right:
			mov word [100],1
			mov word [102],0
			jmp .print
		.down:
			mov word [100],0
			mov word [102],-1
			jmp .print
		;hay que realizar un movimiento por segundo (capaz hacerlo mas rapido cada vez que comes), independiente de la entrada. Las teclas solo marcan la direccion
		
		;en cada paso agarras la direccion, se la sumas a la posicion actual, la metes en el vector en el indice actual, le sumas uno al indice y tomas mod el largo
		;eso se guarda en memoria
		;para hacerlo mas facil y rapido, el largo solo son potencias de dos
		
		;despues de actualizar el vector de posiciones, se recorre el vector y se imprimien los pixels de las posiciones del vector
		
		;cada vez que pasas por un lugar marcado (comida) incrementas en uno un contador, y los puntos. cuando el contador llega al doble del largo, cambias el largo por ese , lo que hace crecer el vector
		
		.print:
			; Update position
			add cx,[100]
			add dx,[102]
			
			mov ah,0Dh
			int 10h
			cmp al,0
			jne .lost
		
			push cx ; change color based on second / 8
			push dx
			mov ah,02h
			int 1Ah
			mov al,dh
			shr al,1
			shr al,1
			shr al,1
			inc al ; prevent black
			pop dx
			pop cx
			
			mov ah,0Ch
			int 10h
		
		;inc bx
		;cmp bx,1000
		;je .win
		;call printscore
	jmp .keyloop
	
.gamereset:
	mov bl, 12
	mov ah, 0Eh
	mov al,13
	int 10h
	
	mov ah,02h
	int 1Ah
	mov bl,0
	mov bh,dh
	.rloop:
		mov ah,02h
		int 1Ah
		cmp bl,5
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
	push bx
	
	mov dx,0
	mov bh,0
	mov ah,02h ; reset cursor
	int 10h
	
	mov ax,bx
	mov bl,10
	
	div bl
	push ax
	mov ah,0
	div bl
	push ax
	mov ah,0
	div bl
	push ax
	mov ah,0
	div bl
	push ax
	mov ah,0
	
	mov bh,0
	mov bl,12
	
	pop ax
	mov al,ah
	add al,48
	mov ah,0Eh
	int 10h
	mov dx,0
	
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
	
	pop ax
	mov al,ah
	add al,48
	mov ah,0Eh

	int 10h
	
	pop bx
	pop dx
	ret
	
	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature