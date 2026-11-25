"""Monta o Assembly com Clang/LLD e executa as instruções binárias RV32I.
Modelo funcional restrito às instruções utilizadas neste projeto, sem pipeline.
Não substitui Ripes e não mede ciclos de hardware. Python 3 + clang/ld.lld.
"""
import csv
import json
import os
import shutil
import struct
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MASK = 0xFFFFFFFF

def signed(x, bits=32):
    return (x ^ (1 << (bits-1))) - (1 << (bits-1))

class RV32I:
    def __init__(self, elf):
        b = elf.read_bytes()
        assert b[:6] == b'\x7fELF\x01\x01' and struct.unpack_from('<H', b, 18)[0] == 243
        self.pc, phoff = struct.unpack_from('<II', b, 24)
        entsize, count = struct.unpack_from('<HH', b, 42)
        self.mem = {}
        for i in range(count):
            typ, off, addr, _, filesz, memsz, _, _ = struct.unpack_from('<8I', b, phoff+i*entsize)
            if typ == 1:
                self.mem.update((addr+j, b[off+j] if j < filesz else 0) for j in range(memsz))
        self.r = [0]*32
        self.r[2] = 0x7FFFFFF0
        self.retired = 0
        self.loads = 0
        self.branches = 0
        self.taken = 0
        self.output = []
        self.stopped = False
        self.calls = []
        self.call_stats = []

    def load(self, addr):
        assert addr % 4 == 0, f'Endereço desalinhado: {addr:x}'
        return sum(self.mem[addr+j] << (8*j) for j in range(4))

    def store(self, addr, val):
        assert addr % 4 == 0
        for j in range(4): self.mem[addr+j] = (val >> (8*j)) & 255

    def step(self):
        pc = self.pc
        ins = self.load(pc)
        op, rd, f3, rs1, rs2, f7 = ins&127, (ins>>7)&31, (ins>>12)&7, (ins>>15)&31, (ins>>20)&31, ins>>25
        r = self.r
        a, b = r[rs1], r[rs2]
        imm = signed(ins>>20, 12)
        nxt = pc+4
        val = None
        self.retired += 1
        if op == 0x13:
            if f3 == 0: val = a+imm
            elif f3 == 7: val = a&imm
            elif f3 == 1 and f7 == 0: val = a << rs2
            elif f3 == 5 and f7 == 0: val = a >> rs2
            else: raise ValueError(hex(ins))
        elif op == 0x33 and f3 == 0 and f7 in (0,32): val = a-b if f7 else a+b
        elif op == 0x37: val = ins&0xfffff000
        elif op == 0x17: val = pc+(ins&0xfffff000)
        elif op == 0x03 and f3 == 2:
            val = self.load((a+imm)&MASK); self.loads += 1
        elif op == 0x23 and f3 == 2:
            off = signed(((ins>>25)<<5)|((ins>>7)&31),12)
            self.store((a+off)&MASK,b)
        elif op == 0x63:
            off = signed(((ins>>31)<<12)|(((ins>>7)&1)<<11)|(((ins>>25)&63)<<5)|(((ins>>8)&15)<<1),13)
            cond = {0:a==b,1:a!=b,4:signed(a)<signed(b),5:signed(a)>=signed(b)}[f3]
            self.branches += 1
            if cond: nxt = pc+off; self.taken += 1
        elif op == 0x6f:
            off = signed(((ins>>31)<<20)|(((ins>>12)&255)<<12)|(((ins>>20)&1)<<11)|(((ins>>21)&1023)<<1),21)
            val, nxt = pc+4, pc+off
            if rd == 1:
                self.calls.append((pc+4, self.retired, self.loads, self.branches, nxt))
        elif op == 0x67 and f3 == 0:
            val,nxt = pc+4,(a+imm)&~1
            if rd == 0 and rs1 == 1 and self.calls:
                dest, start, loads, branches, target = self.calls.pop()
                assert nxt == dest
                self.call_stats.append((target,self.retired-start,self.loads-loads,self.branches-branches))
        elif ins == 0x73:
            service = r[17]
            if service == 10: self.stopped = True
            elif service == 1: self.output.append(str(signed(r[10])))
            elif service == 11: self.output.append(chr(r[10]&255))
            elif service == 4:
                addr = r[10]; out=[]
                while self.mem[addr]: out.append(self.mem[addr]); addr+=1
                self.output.append(bytes(out).decode('ascii'))
            else: raise ValueError(f'ecall {service}')
        else: raise ValueError(f'Instrução não implementada: {ins:08x} em {pc:x}')
        if rd and val is not None: r[rd] = val & MASK
        self.pc = nxt & MASK

    def run(self):
        while not self.stopped:
            if self.retired >= 1000000: raise RuntimeError('Limite de instruções')
            self.step()
        return self


def assemble_run(src, tmp):
    clang = os.environ.get('CLANG','clang')
    # Somente a exportação do símbolo é necessária ao linker; o código é idêntico.
    asm = tmp/'input.s'; elf=tmp/'run.elf'
    asm.write_text('.globl main\n'+src.read_text(encoding='utf-8'), encoding='utf-8')
    subprocess.run([clang,'--target=riscv32-unknown-elf','-march=rv32i','-mabi=ilp32','-nostdlib','-fuse-ld=lld','-Wl,-e,main','-Wl,--no-relax',str(asm),'-o',str(elf)],check=True)
    return RV32I(elf).run()


def reference(values, target):
    seq = next((i for i,v in enumerate(values) if v==target),-1)
    l,h,c = 0,len(values)-1,0
    while l<=h:
        m=l+(h-l)//2; c+=1
        if values[m]==target: return seq,seq+1 if seq>=0 else len(values),m,c
        if values[m]<target: l=m+1
        else: h=m-1
    return seq,seq+1 if seq>=0 else len(values),-1,c


def main():
    cases=json.loads((ROOT/'tests/casos.json').read_text(encoding='utf-8'))
    outdir=ROOT/'evidencias'; outdir.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as d:
        tmp=Path(d)
        cpu=assemble_run(ROOT/'src/main.s',tmp)
        output=''.join(cpu.output)
        rows=[list(map(int,x.split())) for x in output.splitlines()[1:]]
        assert len(rows)==len(cases)
        for case,row in zip(cases,rows):
            i,n,t,seq,cs,b,cb,ok=row
            assert (i,n,t)==(case['id'],case['n'],case['alvo'])
            assert (seq,cs,b,cb)==reference(case['valores'],t), (case,row)
            assert seq==b==case['esperado'] and ok==1
        assert cpu.r[2]==0x7ffffff0 and not cpu.calls
        (outdir/'saida_execucao.txt').write_text('Execução do código de máquina RV32I no interpretador funcional de testes (não Ripes).\n\n'+output+f'\n{len(rows)}/{len(cases)} casos aprovados; pilha restaurada.\n',encoding='utf-8')
        with (outdir/'resultados_testes.csv').open('w',encoding='utf-8',newline='') as f:
            w=csv.writer(f); w.writerow(['caso','n','alvo','indice_seq','comparacoes_seq','indice_bin','comparacoes_bin','ok']); w.writerows(rows)
        metrics=[]
        for src in sorted((ROOT/'benchmarks').glob('*.s')):
            cpu=assemble_run(src,tmp)
            assert len(cpu.call_stats)==1 and not cpu.calls
            _,count,loads,branches=cpu.call_stats[0]
            assert loads==cpu.r[9]
            # A preparação e a finalização são iguais em todos os arquivos.
            assert cpu.retired-count==9,(src,cpu.retired,count)
            name,algo=src.stem.rsplit('_',1)
            expected={'n008_inicio':(0,1,3),'n008_fim':(7,8,4),'n032_fim':(31,32,6),'n128_fim':(127,128,8),'n128_ausente':(-1,128,8)}[name]
            assert signed(cpu.r[8])==expected[0] and cpu.r[9]==expected[1 if algo=='sequencial' else 2],src
            metrics.append([name,algo,signed(cpu.r[8]),cpu.r[9],count,cpu.retired,loads,branches])
        with (outdir/'metricas_rv32i.csv').open('w',encoding='utf-8',newline='') as f:
            w=csv.writer(f); w.writerow(['cenario','algoritmo','indice','elementos_examinados','instrucoes_rotina','instrucoes_programa','leituras_rotina','desvios_condicionais_rotina']); w.writerows(metrics)
        print(output,end=''); print(f'{len(rows)}/{len(cases)} casos aprovados; {len(metrics)} benchmarks verificados.')
        print('Evidências gravadas em evidencias/.')

if __name__=='__main__': main()
