# Roteiro de apresentação e defesa

## 1. Introdução

O tema escolhido foi a comparação entre busca sequencial e busca binária em vetores ordenados, utilizando Assembly RISC-V. O objetivo é verificar qual algoritmo exige menos trabalho da CPU em diferentes situações.

## 2. Funcionamento

A busca sequencial passa pelos elementos um por um. A busca binária verifica o elemento do meio e descarta metade do intervalo a cada passo. Por isso, precisa de um vetor ordenado. As duas retornam o índice e a quantidade de elementos examinados; se não encontrarem o alvo, retornam -1.

## 3. Código e arquitetura

Mostre as duas sub-rotinas no arquivo `src/main.s`. Os registradores `a0`, `a1` e `a2` recebem o endereço, tamanho e alvo. `jal` salva o endereço de retorno em `ra`, e `jalr` retorna à instrução seguinte à chamada. O procedimento que chama as duas rotinas salva os registradores na pilha com `sw` e os restaura com `lw`. As buscas são rotinas folha e usam registradores temporários.

Na binária, `srli` divide a diferença dos índices por dois, e `slli` multiplica o índice por quatro para localizar um inteiro de 32 bits na memória. Essas operações evitam depender da extensão M.

## 4. Demonstração no Ripes

Abra `src/main.s`, execute e mostre as 14 linhas de resultados. Explique o caso 11: o número 254 aparece no índice 127 do vetor de 128 elementos. A sequencial examina 128 elementos; a binária, oito. Em seguida, execute `n128_fim_sequencial.s` e `n128_fim_binaria.s` individualmente e mostre as estatísticas reais da CPU. Nas execuções registradas no Ripes monociclo, a sequencial consumiu 908 ciclos e a binária 108, ambas com CPI 1. A redução foi de 88,11%. O programa principal teve 4.646 ciclos e 14/14 casos aprovados.

## 5. Conclusão

A busca binária é mais eficiente em vetores ordenados grandes, sobretudo quando o alvo está no fim ou não está presente. A busca sequencial pode ser melhor quando o alvo está no primeiro elemento. O projeto também demonstrou como os registradores, a pilha, os acessos à memória e os desvios afetam a execução do programa.

## Perguntas que podem aparecer

- **Por que RV32I?** É a ISA base inteira de 32 bits. Não são necessárias instruções de multiplicação ou divisão.
- **Por que multiplicar por quatro?** Cada inteiro ocupa quatro bytes, e a memória é endereçada por byte.
- **Por que a binária exige ordenação?** Sem ela, comparar com o meio não permite descartar uma metade com segurança.
- **O que acontece quando o vetor está vazio?** Os limites indicam um intervalo inválido e as buscas retornam -1 sem ler o vetor.
- **O que significa CPI?** Ciclos de clock divididos pelo número de instruções aposentadas. Depende do modelo de CPU.
- **Por que a sequencial pode ganhar?** Se o alvo estiver no início, encontra-o rapidamente e tem menos instruções de preparação por elemento.
- **Qual a diferença entre a métrica local e a do Ripes?** A local conta instruções realmente executadas pelo modelo funcional; o Ripes mede o comportamento da microarquitetura selecionada, inclusive ciclos.
