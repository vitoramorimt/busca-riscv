# Benchmark: n032_fim, sequencial. Sem impressao para isolar a busca.
# Ao parar: s0=indice, s1=elementos examinados.
.data
vetor:
    .word 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    .word 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46
    .word 48, 50, 52, 54, 56, 58, 60, 62

.text
main:
    la a0, vetor
    addi a1, zero, 32
    addi a2, zero, 62
    jal ra, busca_sequencial
    addi s0, a0, 0
    addi s1, a1, 0
    addi a7, zero, 10
    ecall

# busca_sequencial(a0=base, a1=N, a2=alvo)
# Retorno: a0=indice (ou -1), a1=elementos examinados.
# t0=indice; t1=endereco corrente; t2=valor; t3=contador.
# Sub-rotina folha: nao altera ra, sp nem registradores s.
busca_sequencial:
    addi t0, zero, 0
    addi t1, a0, 0
    addi t3, zero, 0
seq_loop:
    bge t0, a1, seq_ausente
    lw t2, 0(t1)
    addi t3, t3, 1
    beq t2, a2, seq_achou
    addi t0, t0, 1
    addi t1, t1, 4
    jal zero, seq_loop
seq_achou:
    addi a0, t0, 0
    addi a1, t3, 0
    jalr zero, 0(ra)
seq_ausente:
    addi a0, zero, -1
    addi a1, t3, 0
    jalr zero, 0(ra)
