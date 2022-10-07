.data
string: .space 100000 # memorizzare lo string di byte
dims: .half 0:9 # memorizza gli elementi per ogni asse
order: .half 0:9 # memorizza l'indice del nuovo ordine per ogni asse sorgente

# Variables
# $t0 = Assi (Vengono moltiplicati per 2 [ indicizzazione half word], dividere per 2 per poter riutilizzare l'int)
# $t1 = Elementi da salvare in dims e order  ------ Riutilizzabile da Riga 78 circa ------ 
# $t9 = Index i (per indicizzare dims e order)   ------ Riutilizzabile da Riga 78 circa ------  (viene riutilizzato per AsciiToInt)
# 
#
# $s5 = registro che contiene l'offset della dimensione corrente
# 
# $s7 = registro che contiene 16, utlizzato nella funzione che converte i numeri in decimale (Utilizzato a riga 112 circa)
#
# $a2 utilizzato dalla funzione che converte da ascii a integer e successivamente dalla funzione ricorsiva che converte da integer a esadecimale
# $a3 ingresso delle funzione che calcola il valore esadecimale associato ai resti della divisione per 16 della funzione ricorsiva

.text
	li $v0,5  # Acquisizione Assi
	syscall

	move $t0,$v0 # Registro t0 contiene gli Assi
	beqz $t0,endProgram # Se il valore degli assi e'¨ uguale a 0 si termina il programma
	
	addi $t0,$t0,-1
	mul $t0,$t0,2 # assi * indicizzazione(2) [ Utilizzato per poter iterare nei due cicli di acquisizione successivi]

	li $t9,0 # i = 0
	
####################################################################################################################################################
####################################################################################################################################################
#                                                          ACQUISIZIONE DATI                                                                       #
####################################################################################################################################################
####################################################################################################################################################

li $s5,1 # inizializzo a 1 l'offset della matrice finale

#=========================
# ACQUISIZIONE DIMESIONI #
#=========================

AcquisiciDimensioni:
	bgt $t9,$t0,endAcquisiciDimensioni
	
	li $v0, 5  # Acquisizione dimesione corrente
	syscall
	
	move $t1,$v0 # Dimensione corrente in $t1
	
	sh $t1,dims($t9) # dims[i] = dimensioneCorrente ($t1)
	
	mul $s5,$s5,$t1 # aggiorno l'offset con tutte le dimensioni della matrice
	
	addi $t9,$t9,2 # i+=2 (indiciziamo half words)
	j AcquisiciDimensioni
	
endAcquisiciDimensioni:
	li $t9,0 # i=0
	mul $s5,$s5,5 # variabile che divisa per la dimensione di un asse ne fornisce l'offset
#=============================
# END ACQUISIZIONE DIMESIONI #
#=============================


#======================
# ACQUISIZIONE ORDINE #
#======================

AcquisiciOrdine:
	bgt $t9,$t0,endAcquisiciOrdine
	
	li $v0, 5  # Acquisizione ordine corrente
	syscall
	
	move $t1,$v0 # Ordine corrente in $t1
	
	sh $t1,order($t9) # order[i] = ordineCorrente ($t1)
	
	addi $t9,$t9,2 # i+=2 (indiciziamo half words)
	j AcquisiciOrdine
	
endAcquisiciOrdine:

#==========================
# END ACQUISIZIONE ORDINE #
#==========================

#=======================================
# INSERIMENTO DELLA STRINGA IN MEMORIA #
#=======================================

	li $v0,8
	la $a0,string # Caricamento della stringa in memoria
	li $a1,100000
	syscall
	
#==============================================
# SALVATAGGIO DEGLI SPIAZZAMENTI DI OGNI ASSE #
#==============================================
# Nello stack saranno salvati gli offset al contrario, ovvero dalle colonne all'asse più esterno (sarà necessario puntare da 4*assi fino a 0)
li $t9,0 # i=0
div $t0,$t0,2 # $t0 ritorna ad essere il numero di assi intero
addi $t0,$t0,1
CaricaOffsets:
	beq $t9,$t0,endCaricamentoOffset

	mul $s7,$t9,2
	lh $t6,dims($s7) # ottengo la dimensione di dims[i]
	div $s5,$s5,$t6 # divido l'offset totale per la dimensione dell'asse i, ottengo quindi il suo spiazzamento
	
#li $v0,1
#la $a0,($t0)
#syscall

#li $v0,11
#la $a0, 10
#syscall
	
	
	addi $sp, $sp, -4 # salvo lo spiazzamento nello stack
    sw   $s5, 0($sp)

	addi $t9,$t9,1
j CaricaOffsets
endCaricamentoOffset:
move $t7,$sp # t7 contiene l'indirizzo di sp, funzionera' come un index di un array
mul $s5,$t0,4 # trovo in s5 il numero di (assi-1) * 2, per ottenere lo spiazzamento corretto nella funzione ricorsiva
addi $s5,$s5,-4
add $t7,$t7,$s5 # e' come se puntasse alla posizione 0 di un array

j a
li $v0,1
la $a0,($sp)
syscall

li $v0,11
la $a0, 10
syscall

li $v0,1
la $a0, ($t7)
syscall

li $v0,10
syscall
a:
###################################################################################################################################################
###################################################################################################################################################

# Se abbiamo tre assi le colonne si troveranno all'asse in posizione 2 in order, quindi Matrice di N dimensioni = colonna in N-1 Dimensione
#	in $t0 troviamo assi-1
# $s5 variabile che contiene l'offset del livello corrente 
# USATI QUI $t0, $s6, $s0 index

	li $s7,16 # registro temporaneo che contiene 16 per la divisione con resto
	li $t9,0 # offset che verrà passato in ricorsione
	li $t2,0 # profondita'
	#addi $t0,$t0,-1
	move $t6,$s5
	jal profondita # input alla funzione: livello di ricorsione ($t2), offset($t9)
	
endProgram:
	li $v0,11 # Output carattere \n
	la $a0,10
	syscall
	
	li $v0,10 # FINALLY THE END
	syscall

###################################################################################################################################################
###################################################################################################################################################
###################################################################################################################################################
###################################################################################################################################################
#                                                         					FUNZIONI                                                                      #
###################################################################################################################################################
###################################################################################################################################################

# 																							[ Function ] 
# Alla funzione bisogna passare l'offset, dimensione e livello di ricorsione  [ ricorsione in profondità ]


#
# $t0					$s0     												$s1    										$s5
# assi-1      indice elementi per riga				numero el per riga        spiazzamento

# $t2									$t3                                $t4           $t8
# livello corrente	  dimensione dell'ASSE CORRENTE				counter			 registro d'appoggio

#
#

profondita: 
	beq $t2,$t0,CasoBase # se si raggiunge il livello 0 (visivamente l'ultima quadra nella matrice) siamo nelle colonne -> mando in out il valore in hex ( Caso base)

	j skipCasoBase
	#========================
	# CASO BASE
	CasoBase:
	move $s0,$ra
	jal AsciiToInt
	beqz $a2,specialCaseZero
	jal HexRecursive # se $a2 e' diverso da 0 converti normalemente
	j skipSpecialCaseZero
	specialCaseZero: # se $a2 e'¨ == 00000 output 0
	jal OutputHex
	skipSpecialCaseZero:
  jr $s0
	#========================
	skipCasoBase:
	
	# dimensione corrente è in base al livello: livello 0 -> dims[order[0]], livello 1 -> dims[order[1]]... cosi' come l'offset.
	mul $s4,$t2,2 # profondita' * 2   0,2,4
	lh $t5,dims($s4)
	lh $t5,order($s4) # carico in $t5 l'indice che fa riferimento alla dimensione dell'asse del livello corrente
	#uso lo spiazzamento di s4
	mul $s4,$t5,4 # spiazzamento per prendere dallo stack l'offset locale
	sub $s4,$t7,$s4
	lw $t6,0($s4) # carico in t6 l'offset originale dell'asse
	mul $t5,$t5,2 # moltiplico per due per poter indicizzare dims e l'offset locale. Si utilizzera' t5 come indice
	lh $t5,dims($t5) # avro' la nuova dimensione dell'asse in t5
	

	
	#======

	li $t4,0 #ad ogni ricorsione questo indice va a 0 (counter del for che innesca le varie ricorsioni)
	ForArrayInMatrix:# si itera su ogni dimensione della matrice, vista come un array che contiene matrici di n-1 dimensioni
		beq $t4,$t5,theEnd # se l'indice e' maggiore della dimensione dell'asse in questione esco
		bgtz $t2,NonPrimoAsse
		li $t9,0 #azzero l'offset totale se mi trovo nel primo asse
		NonPrimoAsse:
		

	# SALVATAGGIO VARIABILI PRE-CHIAMATA RICORSIVA 
    addi $sp, $sp, -24
    sw   $ra, 0($sp)
    sw   $t2, 4($sp)
    sw   $t9, 8($sp)
    sw   $t5, 12($sp)
    sw   $t6, 16($sp)
    sw   $t4, 20($sp)
    
		mul $s2,$t6,$t4 # offset += offset_locale*i
   	add $t9,$t9,$s2
		addi $t2,$t2,1 # $t2 livello della ricorsione + 1
		jal profondita 
	
	# CARICAMENTO VARIABILI POST-CHIAMATA RICORSIVA 
		lw   $t4, 20($sp)
	  lw   $t6, 16($sp)
    lw   $t5, 12($sp)
		lw   $t9, 8($sp)
    lw   $t2, 4($sp)
    lw   $ra, 0($sp)	
    addi $sp, $sp, 24
    
    
	addi $t4,$t4,1 # aggiorno l'indice per la dimensione dell'asse corrente
	j ForArrayInMatrix
	theEnd:
	jr $ra
# PROVE TECNICHE, ATTENDERE...

###################################################################################################################################################
# 																							[ Function ] 
#	Utilizza il padding a 5 dell'intero sotto forma di stringa per calcolare il valore decimale corrispondente [ ASCII -> INT ]
# Viene riutilizzato il registro t9 per indicizzare tutte le stringa con padding a 5. Inizializzato a 0 fuori dal While loop
AsciiToInt:

	li $t3,0 # Registro d'appoggio per prelevare i valori decimali associati all'indice del padding
	li $a2,0 # Registro che conterra'  il valore INTERO relativo alla STRINGA
	move $s1,$t9

	
	lb $t3,string($s1)    # parte da 0
	andi $t3,$t3,0x0F
	#beq $t3,10,endProgram    # [ SPECIALE ] Se il primo byte estratto e'¨uguale a '\n' allora si e'¨arrivati alla fine. Si termina il programma.
	mul $t3,$t3,10000
	add $a2,$a2,$t3
	addi $s1,$s1,1
	
	lb $t3,string($s1)    # parte da 1
	andi $t3,$t3,0x0F
	mul $t3,$t3,1000
	add $a2,$a2,$t3
	addi $s1,$s1,1
	
	lb $t3,string($s1)    # parte da 2
	andi $t3,$t3,0x0F
	mul $t3,$t3,100
	add $a2,$a2,$t3
	addi $s1,$s1,1
	
	lb $t3,string($s1)    # parte da 3
	andi $t3,$t3,0x0F
	mul $t3,$t3,10
	add $a2,$a2,$t3
	addi $s1,$s1,1
	
	lb $t3,string($s1)    # parte da 4
	andi $t3,$t3,0x0F
	mul $t3,$t3,1
	add $a2,$a2,$t3
	addi $s1,$s1,1
	
	jr $ra
###################################################################################################################################################
# 													[ Function ] 
#	Utilizza $a2 per calcolare il valore esadecimale corrispondende
HexRecursive:
			blez $a2,BaseCase
			
			div $a2,$s7
		  mfhi $s6 # resto in $s6
			mflo $a2 # quoziente in $a2
			
			subi $sp,$sp,8 # Alloco memoria nello stack
			sw $ra, 0($sp) # salvo $ra
			sw $s6, 4($sp) # salvo il quoziente
			
			jal HexRecursive  # chiamo la funzione con input $a2 -> $a2/16 
			
			lw $s6, 4($sp) # recupero il quoziente
			
			move $a3,$s6 # sposto il quoziente nel registro utilizzato per la funzione che, preso un intero, restituisce in output un esadecimale
			jal OutputHex
			
			lw $ra, 0($sp) # recupero $ra
			addi $sp,$sp,8 # Dealloco memoria dallo stack
			
			jr $ra
		BaseCase:
			jr $ra
###################################################################################################################################################
# 																					[ Function ] 
#	Utilizza $a3 per mandare in output il valore esadecimale corrispondende all'intero dato in input
OutputHex:
	blt $a3,10,lessThanTen # <10 mando in output un integer altrimenti mando in output un carattere
	beq $a3,10,I0 # valore numerico 10 ->  carattere 'a'
	beq $a3,11,I1 # valore numerico 11 ->  carattere 'b'
	beq $a3,12,I2 # valore numerico 12 ->  carattere 'c'
	beq $a3,13,I3 # valore numerico 13 ->  carattere 'd'
	beq $a3,14,I4 # valore numerico 14 ->  carattere 'e'
	beq $a3,15,I5 # valore numerico 15 ->  carattere 'f'
	
	I0:
		li $v0,11
		la $a0,97
		syscall
		j endOutputHex
		
	I1:
		li $v0,11
		la $a0,98
		syscall
		j endOutputHex
	
	I2:
		li $v0,11
		la $a0,99
		syscall
		j endOutputHex
	
	I3:
		li $v0,11
		la $a0,100
		syscall
		j endOutputHex
	
	I4:
		li $v0,11
		la $a0,101
		syscall
		j endOutputHex
		
	I5:
		li $v0,11
		la $a0,102
		syscall
		j endOutputHex
	
	lessThanTen:
		li $v0,1
		la $a0,($a3)
		syscall
		j endOutputHex
		
	endOutputHex: # [ Function end ]
		jr $ra	
###################################################################################################################################################
