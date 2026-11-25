# Benchmark: n128_fim, binaria. Sem impressao para isolar a busca.
# Ao parar: s0=indice, s1=elementos examinados.
.data
vetor:
    .word 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    .word 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46
    .word 48, 50, 52, 54, 56, 58, 60, 62, 64, 66, 68, 70
    .word 72, 74, 76, 78, 80, 82, 84, 86, 88, 90, 92, 94
    .word 96, 98, 100, 102, 104, 106, 108, 110, 112, 114, 116, 118
    .word 120, 122, 124, 126, 128, 130, 132, 134, 136, 138, 140, 142
    .word 144, 146, 148, 150, 152, 154, 156, 158, 160, 162, 164, 166
    .word 168, 170, 172, 174, 176, 178, 180, 182, 184, 186, 188, 190
    .word 192, 194, 196, 198, 200, 202, 204, 206, 208, 210, 212, 214
    .word 216, 218, 220, 222, 224, 226, 228, 230, 232, 234, 236, 238
    .word 240, 242, 244, 246, 248, 250, 252, 254

.text
main:
    la a0, vetor
    addi a1, zero, 128
    addi a2, zero, 254
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
