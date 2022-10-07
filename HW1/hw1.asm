.data
array: .word 1:401
reversed: .word 0:401

.text
# Variables
# t0  W ( Numero di Pixel per riga)
# t1  Index Array
# t2  Index Reversed Array
# t3  Registro che contiene singoli valori alla volta
# t4  W* 4 = numero dei pixel per riga
# t5 registro d'appoggio (~riga 75)
# t6 registro d'appoggio (~riga 69)
# t9 registro d'appoggio (~riga 60)


li $t1,4 # Spiazzamento array		

# ======== Estrazione di W ========
li $v0,5                          #
syscall                           #
                                  #
move $t0,$v0                      #
#==================================

beq $t0,0,endProgram # If W = 0 (Non ci sono pixel), termina il programma.

add $t4,$t4,$t0 # PixelPerRiga = W
mul $t4,$t4,16 # W * 16 = Numero di Pixel * word (per pixel = 16 BYTE TOTALI)



WhileLoop:     # Per ogni riga vengono salvati tutti i pixel, invertiti e mandati in output sul file. 
			   # Se si trova -1 si termina il programma.


#=========================== # / Si scorre l'array e si salvano tutti i dati relativi ai pixel.
#     SALVATAGGIO RIGHE    # # /  L'array rappresenta una riga.
#=========================== # /
inputFILE:
	bgt $t1,$t4,endInput # While (Element != -1)

	li $v0,5
	syscall

	move $t3,$v0
	beq $t3,-1,endProgram # If element == -1, termina il programma
	
	sw $t3,array($t1) # Else salva nell'array
	
	addi $t1,$t1,4
	
	j inputFILE
	
endInput:	

	move $t9,$t0 # = W
	mul $t9,$t9,16 # W * 16
	sub $t1,$t1,$t9 # torna alla prima word della riga attuale per poter mandare in output i dati dei pixel
	
#===========================  # / Si salva nella prima posizione di reversed la quart'ultima posizione dell'array.
#   INVERSIONE DEI PIXEL   #  # /  Cioe' si prende la R dell'ultimo pixel e si mette in prima posizione, si avanza di uno,
#===========================  # /   quindi si prende la G e cosi' via.

	move $t2,$t1 # t2 e' all'inizio dell'array reversed
	move $t6,$t4 # t4 e' alla fine dell'array
	subi $t6,$t6,12 # spiazzo all' n-esimo pixel, ma partendo da R (RGBA)
	
Reversing:
	bgt $t2,$t4,endReversing
	
	lw $t5,array($t6) # Copia di R per il reversed
	sw $t5,reversed($t2)
	addi $t6,$t6,4
	addi $t2,$t2,4
	
	lw $t5,array($t6) # Copia di G per il reversed
	sw $t5,reversed($t2)
	addi $t6,$t6,4
	addi $t2,$t2,4
	
	lw $t5,array($t6) # Copia di B per il reversed
	sw $t5,reversed($t2)
	addi $t6,$t6,4
	addi $t2,$t2,4
	
	lw $t5,array($t6) # Copia di A per il reversed
	sw $t5,reversed($t2)

	addi $t2,$t2,4	 # Aggiornamento degli indici per il ciclo successivo
	subi $t6,$t6,28

	j Reversing
	
endReversing:
#===========================   # /
#   OUTPUT DEI RISULTATI   #   # / Viene preso ogni elemento dell'array reversed e mandato in output
#===========================   # /
outputFILE:
	bgt $t1,$t4,endOutput # While (Element != -1) 
	
	lw $t3,reversed($t1)
		
	li $v0,1       
	la $a0,($t3)
	syscall
		
	li $v0,11
	la $a0,10
	syscall
		
	addi $t1,$t1,4
		
	j outputFILE
	
endOutput:
#===========================
############################
	
	add $t4,$t4,$t9 # Riga Successiva
	
	j WhileLoop
	
############################
#===========================

endProgram: # Da in Output -1 sul file e termina il programma

	li $t3,-1

	li $v0,1
	la $a0,($t3)
	syscall
	
	li $v0,10
	syscall