# UniSantos - Arquitetura de Computadores - Tema 4
# Comparacao entre busca sequencial e binaria em RV32I.
# Entradas: tabela de casos em .data. Saida: console do Ripes.
.data
# Vetores de inteiros de 32 bits; cada elemento ocupa 4 bytes.
vazio:
    .word 0
unitario:
    .word 7
vetor8:
    .word -12, -5, 0, 4, 9, 15, 22, 31
vetor32:
    .word 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    .word 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46
    .word 48, 50, 52, 54, 56, 58, 60, 62
vetor128:
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
extremos:
    .word -2147483648, -1, 0, 1, 2147483647
# Registros de 16 bytes: offset em bytes a partir de vazio, N, alvo, indice esperado.
casos:
    .word 0, 0, 5, -1 # 1: Vazio
    .word 4, 1, 7, 0 # 2: Unitario presente
    .word 4, 1, 8, -1 # 3: Unitario ausente
    .word 8, 8, -12, 0 # 4: Inicio negativo
    .word 8, 8, 4, 3 # 5: Meio
    .word 8, 8, 31, 7 # 6: Fim
    .word 8, 8, 8, -1 # 7: Ausente interno
    .word 8, 8, -13, -1 # 8: Abaixo do minimo
    .word 40, 32, 0, 0 # 9: Inicio 32
    .word 40, 32, 62, 31 # 10: Fim 32
    .word 168, 128, 254, 127 # 11: Fim 128
    .word 168, 128, 255, -1 # 12: Acima do maximo
    .word 680, 5, -2147483648, 0 # 13: Minimo int32
    .word 680, 5, 2147483647, 4 # 14: Maximo int32
cabecalho: .string "CASO N ALVO IDX_SEQ CMP_SEQ IDX_BIN CMP_BIN OK\n"

.text
main:
    # Ripes inicializa sp; alinhar a 16 bytes para os frames de pilha.
    andi sp, sp, -16
    la a0, cabecalho
    addi a7, zero, 4
    ecall
    la s0, casos
    addi s1, zero, 1
    addi s2, zero, 15
main_loop:
    bge s1, s2, main_fim
    addi a0, s0, 0
    addi a1, s1, 0
    jal ra, executar_caso
    addi s0, s0, 16
    addi s1, s1, 1
    jal zero, main_loop
main_fim:
    addi a7, zero, 10
    ecall

# executar_caso(a0=registro de teste, a1=numero do caso).
# Frame de 48 bytes (alinhado): ra e s0-s9 preservados.
# s0=base; s1=N; s2=alvo; s3=esperado; s4=id;
# s5/s6=indice/contador sequencial; s7/s8=indice/contador binario;
# s9=resultado de verificacao (1=OK, 0=FALHA).
executar_caso:
    addi sp, sp, -48
    sw ra, 44(sp)
    sw s0, 40(sp)
    sw s1, 36(sp)
    sw s2, 32(sp)
    sw s3, 28(sp)
    sw s4, 24(sp)
    sw s5, 20(sp)
    sw s6, 16(sp)
    sw s7, 12(sp)
    sw s8, 8(sp)
    sw s9, 4(sp)
    lw s0, 0(a0)
    la t0, vazio
    add s0, t0, s0
    lw s1, 4(a0)
    lw s2, 8(a0)
    lw s3, 12(a0)
    addi s4, a1, 0
    addi a0, s0, 0
    addi a1, s1, 0
    addi a2, s2, 0
    jal ra, busca_sequencial
    addi s5, a0, 0
    addi s6, a1, 0
    addi a0, s0, 0
    addi a1, s1, 0
    addi a2, s2, 0
    jal ra, busca_binaria
    addi s7, a0, 0
    addi s8, a1, 0
    addi s9, zero, 0
    bne s5, s3, caso_imprimir
    bne s7, s3, caso_imprimir
    addi s9, zero, 1
caso_imprimir:
    addi a0, s4, 0
    jal ra, imprimir_campo
    addi a0, s1, 0
    jal ra, imprimir_campo
    addi a0, s2, 0
    jal ra, imprimir_campo
    addi a0, s5, 0
    jal ra, imprimir_campo
    addi a0, s6, 0
    jal ra, imprimir_campo
    addi a0, s7, 0
    jal ra, imprimir_campo
    addi a0, s8, 0
    jal ra, imprimir_campo
    addi a0, s9, 0
    addi a7, zero, 1
    ecall
    addi a0, zero, 10
    addi a7, zero, 11
    ecall
    lw s0, 40(sp)
    lw s1, 36(sp)
    lw s2, 32(sp)
    lw s3, 28(sp)
    lw s4, 24(sp)
    lw s5, 20(sp)
    lw s6, 16(sp)
    lw s7, 12(sp)
    lw s8, 8(sp)
    lw s9, 4(sp)
    lw ra, 44(sp)
    addi sp, sp, 48
    jalr zero, 0(ra)

# imprimir_campo(a0=inteiro): imprime o valor e um espaco.
# Folha: usa apenas registradores volateis.
imprimir_campo:
    addi a7, zero, 1
    ecall
    addi a0, zero, 32
    addi a7, zero, 11
    ecall
    jalr zero, 0(ra)

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
