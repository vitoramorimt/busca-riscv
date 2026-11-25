# Benchmark: n008_inicio, binaria. Sem impressao para isolar a busca.
# Ao parar: s0=indice, s1=elementos examinados.
.data
vetor:
    .word -12, -5, 0, 4, 9, 15, 22, 31

.text
main:
    la a0, vetor
    addi a1, zero, 8
    addi a2, zero, -12
    jal ra, busca_binaria
    addi s0, a0, 0
    addi s1, a1, 0
    addi a7, zero, 10
    ecall

# busca_binaria(a0=base, a1=N, a2=alvo)
# Retorno: a0=indice (ou -1), a1=elementos examinados.
# t0=esquerda; t1=direita; t2=meio; t3=endereco;
# t4=valor; t5=contador. Valores comparados com sinal.
# Pre-condicao: vetor crescente; N >= 0. Indices iniciam em zero.
# meio = esquerda + ((direita - esquerda) >> 1), sem divisao.
busca_binaria:
    addi t0, zero, 0
    addi t1, a1, -1
    addi t5, zero, 0
bin_loop:
    blt t1, t0, bin_ausente
    sub t2, t1, t0
    srli t2, t2, 1
    add t2, t0, t2
    slli t3, t2, 2
    add t3, a0, t3
    lw t4, 0(t3)
    addi t5, t5, 1
    beq t4, a2, bin_achou
    blt t4, a2, bin_direita
    addi t1, t2, -1
    jal zero, bin_loop
bin_direita:
    addi t0, t2, 1
    jal zero, bin_loop
bin_achou:
    addi a0, t2, 0
    addi a1, t5, 0
    jalr zero, 0(ra)
bin_ausente:
    addi a0, zero, -1
    addi a1, t5, 0
    jalr zero, 0(ra)
